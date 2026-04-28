import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import '../common/models/project_model.dart';
import '../common/services/firestore_service.dart';
import '../common/widgets/loading_overlay.dart';
import '../services/user_service.dart';

/// Create Project Screen for Engineers
/// Allows engineers to create new projects by selecting from existing users
class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> with LoadingStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _ownerIdController = TextEditingController();
  final _managerIdController = TextEditingController();
  final _purchaseManagerIdController = TextEditingController();

  UserData? _selectedOwner;
  UserData? _selectedManager;
  UserData? _selectedPurchaseManager;
  bool _isValidatingOwner = false;
  bool _isValidatingManager = false;
  bool _isValidatingPurchaseManager = false;
  String? _ownerValidationError;
  String? _managerValidationError;
  String? _purchaseManagerValidationError;
  Timer? _ownerDebounceTimer;
  Timer? _managerDebounceTimer;
  Timer? _purchaseManagerDebounceTimer;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void initState() {
    super.initState();
    // No need to load users upfront - validation happens on-demand
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _ownerIdController.dispose();
    _managerIdController.dispose();
    _purchaseManagerIdController.dispose();
    _ownerDebounceTimer?.cancel();
    _managerDebounceTimer?.cancel();
    _purchaseManagerDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Creating project...',
      child: Scaffold(
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
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Create New Project',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Project Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Project Name
                                  TextFormField(
                                    controller: _projectNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Project Name',
                                      hintText: 'Enter project name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.apartment),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter a project name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Owner ID Input
                                  _buildIdInputField(
                                    label: 'Owner ID',
                                    controller: _ownerIdController,
                                    icon: Icons.person,
                                    isValidating: _isValidatingOwner,
                                    validationError: _ownerValidationError,
                                    onChanged: _validateOwnerId,
                                  ),
                                  const SizedBox(height: 16),

                                  // Manager ID Input
                                  _buildIdInputField(
                                    label: 'Manager ID',
                                    controller: _managerIdController,
                                    icon: Icons.manage_accounts,
                                    isValidating: _isValidatingManager,
                                    validationError: _managerValidationError,
                                    onChanged: _validateManagerId,
                                  ),
                                  const SizedBox(height: 16),

                                  // Purchase Manager ID Input
                                  _buildIdInputField(
                                    label: 'Purchase Manager ID',
                                    controller: _purchaseManagerIdController,
                                    icon: Icons.shopping_cart,
                                    isValidating: _isValidatingPurchaseManager,
                                    validationError: _purchaseManagerValidationError,
                                    onChanged: _validatePurchaseManagerId,
                                  ),
                                  const SizedBox(height: 24),

                                  // Info Note
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBAE6FD)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info, color: Color(0xFF0369A1)),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Enter Owner and Manager IDs to validate them automatically. IDs will be checked against Firestore to ensure they exist and have correct roles.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF0369A1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Create Button
                                  LoadingButton(
                                    isLoading: isLoading,
                                    onPressed: _canCreateProject() ? _createProject : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _canCreateProject() ? primary : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Create Project',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateProject() {
    return _selectedOwner != null && 
           _selectedManager != null && 
           _selectedPurchaseManager != null &&
           !_isValidatingOwner && 
           !_isValidatingManager &&
           !_isValidatingPurchaseManager &&
           _ownerValidationError == null &&
           _managerValidationError == null &&
           _purchaseManagerValidationError == null;
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_canCreateProject()) {
      _showError('Please select both Owner and Manager');
      return;
    }

    await runWithLoading(() async {
      try {
        final currentUserId = FirestoreService.currentUserId;
        if (currentUserId == null) {
          throw Exception('User not authenticated');
        }

        // DEBUG: Log current user UID
        print('🔐 CREATE PROJECT - Engineer UID: $currentUserId');
        print('👤 CREATE PROJECT - Selected Owner: ${_selectedOwner!.fullName} (${_selectedOwner!.uid})');
        print('👤 CREATE PROJECT - Selected Manager: ${_selectedManager!.fullName} (${_selectedManager!.uid})');
        print('👤 CREATE PROJECT - Selected Purchase Manager: ${_selectedPurchaseManager!.fullName} (${_selectedPurchaseManager!.uid})');

        final project = ProjectModel(
          id: '', // Will be set by Firestore
          projectName: _projectNameController.text.trim(),
          createdBy: currentUserId,
          ownerId: _selectedOwner!.publicId ?? _selectedOwner!.uid, 
          managerId: _selectedManager!.publicId ?? _selectedManager!.uid,
          purchaseManagerId: _selectedPurchaseManager!.publicId ?? _selectedPurchaseManager!.uid,
          status: 'pending_owner_approval',
          createdAt: DateTime.now(),
          ownerUid: _selectedOwner!.uid, 
          managerUid: _selectedManager!.uid, 
          purchaseManagerUid: _selectedPurchaseManager!.uid,
          ownerName: _selectedOwner!.fullName, 
          managerName: _selectedManager!.fullName, 
          purchaseManagerName: _selectedPurchaseManager!.fullName,
        );

        final projectId = await FirestoreService.createProject(project);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project "${project.projectName}" created successfully!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          _showError('Failed to create project: ${e.toString()}');
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  /// Validate Owner ID by checking Firestore (with debouncing)
  void _validateOwnerId(String ownerId) {
    _ownerDebounceTimer?.cancel();
    
    if (ownerId.trim().isEmpty) {
      setState(() {
        _selectedOwner = null;
        _ownerValidationError = null;
        _isValidatingOwner = false;
      });
      return;
    }

    _ownerDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performOwnerValidation(ownerId.trim());
    });
  }

  /// Perform actual owner validation
  Future<void> _performOwnerValidation(String ownerId) async {
    setState(() {
      _isValidatingOwner = true;
      _ownerValidationError = null;
    });

    print('🔍 Validating Owner ID: $ownerId');

    try {
      final validation = await UserService.validateSingleUser(
        publicId: ownerId,
        expectedRole: 'ownerClient',
      );

      if (mounted) {
        if (validation['success']) {
          final owner = validation['user'] as UserData;
          setState(() {
            _selectedOwner = owner;
            _ownerValidationError = null;
            _isValidatingOwner = false;
          });
          print('✅ Owner validated: ${owner.fullName} (${owner.uid})');
        } else {
          setState(() {
            _selectedOwner = null;
            _ownerValidationError = validation['error'];
            _isValidatingOwner = false;
          });
          print('❌ Owner validation failed: ${validation['error']}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedOwner = null;
          _ownerValidationError = 'Validation failed: ${e.toString()}';
          _isValidatingOwner = false;
        });
        print('❌ Owner validation error: $e');
      }
    }
  }

  /// Validate Manager ID by checking Firestore (with debouncing)
  void _validateManagerId(String managerId) {
    _managerDebounceTimer?.cancel();
    
    if (managerId.trim().isEmpty) {
      setState(() {
        _selectedManager = null;
        _managerValidationError = null;
        _isValidatingManager = false;
      });
      return;
    }

    _managerDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performManagerValidation(managerId.trim());
    });
  }

  /// Perform actual manager validation
  Future<void> _performManagerValidation(String managerId) async {
    setState(() {
      _isValidatingManager = true;
      _managerValidationError = null;
    });

    print('🔍 Validating Manager ID: $managerId');

    try {
      final validation = await UserService.validateSingleUser(
        publicId: managerId,
        expectedRole: 'manager',
      );

      if (mounted) {
        if (validation['success']) {
          final manager = validation['user'] as UserData;
          setState(() {
            _selectedManager = manager;
            _managerValidationError = null;
            _isValidatingManager = false;
          });
          print('✅ Manager validated: ${manager.fullName} (${manager.uid})');
        } else {
          setState(() {
            _selectedManager = null;
            _managerValidationError = validation['error'];
            _isValidatingManager = false;
          });
          print('❌ Manager validation failed: ${validation['error']}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedManager = null;
          _managerValidationError = 'Validation failed: ${e.toString()}';
          _isValidatingManager = false;
        });
        print('❌ Manager validation error: $e');
      }
    }
  }

  /// Validate Purchase Manager ID by checking Firestore (with debouncing)
  void _validatePurchaseManagerId(String pmId) {
    _purchaseManagerDebounceTimer?.cancel();
    
    if (pmId.trim().isEmpty) {
      setState(() {
        _selectedPurchaseManager = null;
        _purchaseManagerValidationError = null;
        _isValidatingPurchaseManager = false;
      });
      return;
    }

    _purchaseManagerDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performPurchaseManagerValidation(pmId.trim());
    });
  }

  /// Perform actual purchase manager validation
  Future<void> _performPurchaseManagerValidation(String pmId) async {
    setState(() {
      _isValidatingPurchaseManager = true;
      _purchaseManagerValidationError = null;
    });

    print('🔍 Validating Purchase Manager ID: $pmId');

    try {
      final validation = await UserService.validateSingleUser(
        publicId: pmId,
        expectedRole: 'purchaseManager',
      );

      if (mounted) {
        if (validation['success']) {
          final pm = validation['user'] as UserData;
          setState(() {
            _selectedPurchaseManager = pm;
            _purchaseManagerValidationError = null;
            _isValidatingPurchaseManager = false;
          });
          print('✅ Purchase Manager validated: ${pm.fullName} (${pm.uid})');
        } else {
          setState(() {
            _selectedPurchaseManager = null;
            _purchaseManagerValidationError = validation['error'];
            _isValidatingPurchaseManager = false;
          });
          print('❌ Purchase Manager validation failed: ${validation['error']}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedPurchaseManager = null;
          _purchaseManagerValidationError = 'Validation failed: ${e.toString()}';
          _isValidatingPurchaseManager = false;
        });
        print('❌ Purchase Manager validation error: $e');
      }
    }
  }

  /// Build ID input field with validation
  Widget _buildIdInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isValidating,
    required String? validationError,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter ${label.toLowerCase()}',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
            suffixIcon: isValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : validationError == null && controller.text.isNotEmpty
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : validationError != null
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
            errorText: validationError,
          ),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter ${label.toLowerCase()}';
            }
            if (validationError != null) {
              return validationError;
            }
            return null;
          },
        ),
      ],
    );
  }

}