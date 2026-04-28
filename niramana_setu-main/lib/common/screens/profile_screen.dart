import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/profile_repository.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../widgets/public_id_display.dart';

/// Profile Screen - Shared UI for all roles
/// 
/// This screen displays and allows editing of user profile data.
/// Works fully offline with automatic sync when online.
/// 
/// Features:
/// - Read-only display mode
/// - Edit mode with save button
/// - Offline indicator badge
/// - Sync status text
/// - Instant local saves (no blocking)
/// - Automatic cloud sync when online
class ProfileScreen extends StatefulWidget {
  final String role;

  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _repository = ProfileRepository();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserProfile? _profile;
  bool _isEditing = false;
  bool _isOnline = false;
  bool _isSaving = false;
  String _syncStatus = 'Loading...';

  StreamSubscription<bool>? _connectivitySubscription;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Load profile from repository (Hive cache)
  /// 
  /// This loads instantly from local cache.
  /// No network request, works offline.
  Future<void> _loadProfile() async {
    print('🔍 ProfileScreen: Loading profile for role: ${widget.role}');
    
    // Get current user UID
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('❌ ProfileScreen: No authenticated user');
      setState(() {
        _syncStatus = 'Not logged in';
      });
      return;
    }
    
    print('✅ ProfileScreen: Auth UID: $uid');
    
    // Try to load profile using offline-first strategy
    // This will check Hive first, then Firestore if not cached
    final profile = await _repository.loadProfile(uid);
    
    print('📄 ProfileScreen: Profile loaded: ${profile != null ? profile.fullName : "null"}');
    
    if (profile != null) {
      setState(() {
        _profile = profile;
        _nameController.text = profile.fullName;
        _phoneController.text = profile.phone ?? '';
        _updateSyncStatus();
      });
    } else {
      print('⚠️ ProfileScreen: No profile found in Hive or Firestore');
      setState(() {
        _syncStatus = 'No profile found';
      });
    }
  }

  /// Listen to connectivity changes
  /// 
  /// Updates UI to show online/offline status.
  /// Triggers sync status update when connection changes.
  void _listenToConnectivity() {
    _isOnline = _connectivityService.isOnline;
    _updateSyncStatus();

    _connectivitySubscription = _connectivityService.isOnlineStream.listen((isOnline) {
      setState(() {
        _isOnline = isOnline;
        _updateSyncStatus();
      });
    });
  }

  /// Update sync status text based on current state
  /// 
  /// Shows different messages for:
  /// - Synced with cloud
  /// - Saved locally (pending sync)
  /// - Offline mode
  void _updateSyncStatus() {
    if (_profile == null) {
      _syncStatus = 'No profile loaded';
      return;
    }

    if (_profile!.isDirty) {
      if (_isOnline) {
        _syncStatus = 'Syncing...';
      } else {
        _syncStatus = 'Saved locally • Will sync when online';
      }
    } else {
      if (_isOnline) {
        _syncStatus = 'Synced with cloud';
      } else {
        _syncStatus = 'Offline mode';
      }
    }
  }

  /// Save profile changes
  /// 
  /// This saves instantly to local cache (Hive).
  /// Does NOT block user or wait for network.
  /// Marks profile as dirty for automatic sync later.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create updated profile with new data
      final updatedProfile = _profile!.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        isDirty: true, // Mark as dirty for sync
      );

      // Save to local cache (instant, works offline)
      await _repository.saveLocalProfile(updatedProfile);

      setState(() {
        _profile = updatedProfile;
        _isEditing = false;
        _isSaving = false;
        _updateSyncStatus();
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline 
              ? 'Profile saved and syncing...' 
              : 'Profile saved locally'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Trigger immediate sync if online
      if (_isOnline) {
        _syncService.syncNow();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get role display name
  String _getRoleDisplayName() {
    switch (widget.role) {
      case 'fieldManager':
        return 'Field Manager';
      case 'projectEngineer':
        return 'Project Engineer';
      case 'ownerClient':
        return 'Owner / Client';
      default:
        return widget.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.12),
                  accent.withValues(alpha: 0.10),
                  Colors.white,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: _profile == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with offline indicator
                        _buildHeader(),
                        const SizedBox(height: 24),

                        // Profile card
                        _buildProfileCard(),

                        const SizedBox(height: 16),

                        // Sync status
                        _buildSyncStatus(),

                        const SizedBox(height: 24),

                        // Action buttons
                        if (!_isEditing)
                          _buildEditButton()
                        else
                          _buildSaveButtons(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [primary, accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    Text(
                      _getRoleDisplayName(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5C5C5C),
                      ),
                    ),
                  ],
                ),
              ),
              // Offline indicator
              if (!_isOnline)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name
                _buildField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  enabled: _isEditing,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // Email (read-only)
                _buildField(
                  label: 'Email',
                  initialValue: _profile!.email,
                  icon: Icons.email_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 16),

                // Public ID Display (read-only, copy-friendly)
                PublicIdDisplay(
                  label: '${_getRoleDisplayName()} ID',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                // Phone
                _buildField(
                  label: 'Phone (Optional)',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Role (read-only)
                _buildField(
                  label: 'Role',
                  initialValue: _getRoleDisplayName(),
                  icon: Icons.badge_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 16),

                // Public ID (read-only, only for Owner and Manager)
                if (widget.role == 'ownerClient' || widget.role == 'fieldManager')
                  PublicIdDisplay(
                    label: widget.role == 'ownerClient' ? 'Owner ID' : 'Manager ID',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6F6F6F),
                    ),
                    valueStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6F6F6F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: TextFormField(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            enabled: enabled,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF7B7B7B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _profile!.isDirty
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _profile!.isDirty ? Colors.orange : Colors.green,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _profile!.isDirty ? Icons.sync : Icons.check_circle,
            color: _profile!.isDirty ? Colors.orange : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _syncStatus,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _profile!.isDirty ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton(
      onPressed: () => setState(() => _isEditing = true),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Edit Profile',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSaveButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving
                ? null
                : () {
                    setState(() {
                      _isEditing = false;
                      _nameController.text = _profile!.fullName;
                      _phoneController.text = _profile!.phone ?? '';
                    });
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
