import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import '../services/auth_service.dart';
import '../services/public_id_service.dart';
import '../engineer/engineer_dashboard.dart';
import '../manager/manager.dart';
import '../owner/owner.dart';
import '../main.dart';
import '../common/localization/language_controller.dart';
import '../common/localization/language_keys.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String selectedRole;

  const LoginScreen({
    super.key,
    required this.selectedRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _langController = LanguageController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _migrateUserPublicId(String uid, Map<String, dynamic> userData) async {
    try {
      // Add debug logging before Firestore write
      print("AUTH UID: ${FirebaseAuth.instance.currentUser?.uid}");
      print("Writing to users/$uid");
      
      // Ensure we're using the authenticated user's UID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated - cannot migrate publicId');
      }
      
      if (currentUser.uid != uid) {
        throw Exception('UID mismatch: Auth UID (${currentUser.uid}) != passed UID ($uid)');
      }
      
      final fullName = userData['fullName'] ?? 'Unknown User';
      final role = userData['role'] ?? 'user';
      
      print('🔧 MIGRATION: Generating publicId for $fullName ($role)');
      
      // Generate unique public ID
      final publicId = await PublicIdService.generateUniquePublicId(fullName, role);
      final rolePublicIdField = PublicIdService.getRolePublicIdField(role);
      
      // Update user document using current authenticated user's UID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'publicId': publicId,
        rolePublicIdField: publicId,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ MIGRATION: Generated publicId: $publicId for $fullName');
      print('📝 MIGRATION: Updated field: $rolePublicIdField');
    } catch (e) {
      print('❌ MIGRATION ERROR: Failed to generate publicId for user $uid: $e');
      // Don't throw - allow login to continue even if migration fails
    }
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = userCredential.user;

      if (user != null) {
        // DEBUG: Log current user UID
        print('🔐 LOGIN SUCCESS - User UID: ${user.uid}');
        print('📧 LOGIN SUCCESS - User Email: ${user.email}');
        
        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Existing user - check if they need publicId migration
          final userData = userDoc.data()!;
          final role = userData['role'];
          final publicId = userData['publicId'];
          
          print('👤 LOGIN SUCCESS - User Role: $role');
          print('📄 LOGIN SUCCESS - Firestore Document Exists: YES');
          print('🆔 LOGIN SUCCESS - PublicId: $publicId');
          print('📋 LOGIN SUCCESS - Full user data: $userData');
          
          // SAFE MIGRATION: Auto-generate publicId if missing
          if (publicId == null || publicId.toString().isEmpty) {
            print('🔧 MIGRATION: User missing publicId, generating...');
            await _migrateUserPublicId(user.uid, userData);
          }
          
          _navigateToDashboard(role);
        } else {
          // User exists in Auth but not in Firestore
          print('❌ LOGIN ERROR - Firestore Document Exists: NO');
          _showErrorSnackBar('Account not found. Please create an account.');
        }
      }
    } catch (e) {
      String errorMessage = _langController.t(LangKeys.loginFailed);
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = _langController.t(LangKeys.noAccountFound);
            break;
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage = _langController.t(LangKeys.invalidCredentials);
            break;
          case 'invalid-email':
            errorMessage = _langController.t(LangKeys.invalidEmailAddress);
            break;
          case 'user-disabled':
            errorMessage = _langController.t(LangKeys.accountDisabled);
            break;
          default:
            errorMessage = _langController.t(LangKeys.loginFailed);
        }
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential.user;
      
      if (user != null) {
        // DEBUG: Log current user UID for Google login
        print('🔐 GOOGLE LOGIN SUCCESS - User UID: ${user.uid}');
        print('📧 GOOGLE LOGIN SUCCESS - User Email: ${user.email}');
        
        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Existing user - navigate to role-based dashboard
          final role = userDoc.data()?['role'];
          print('👤 GOOGLE LOGIN SUCCESS - User Role: $role');
          print('📄 GOOGLE LOGIN SUCCESS - Firestore Document Exists: YES');
          _navigateToDashboard(role);
        } else {
          // New Google user - create profile with role-specific public ID
          print('📄 GOOGLE LOGIN - Creating new Firestore document');
          
          // Add debug logging before Firestore write
          print("AUTH UID: ${FirebaseAuth.instance.currentUser?.uid}");
          print("Writing to users/${user.uid}");
          
          // Ensure we're using the authenticated user's UID
          if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
            throw Exception('UID mismatch in Google sign-in');
          }
          
          final userData = await PublicIdService.createUserDataWithPublicId(
            uid: user.uid,
            fullName: user.displayName ?? '',
            phone: '', // Google doesn't provide phone
            email: user.email ?? '',
            role: widget.selectedRole,
            profilePhotoUrl: user.photoURL ?? '',
            profileCompletion: 100, // Google users get full completion
            isActive: true,
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .set(userData, SetOptions(merge: true));
          
          print('✅ GOOGLE LOGIN - New user created with role: ${widget.selectedRole}');
          _navigateToDashboard(widget.selectedRole);
        }
      }
    } catch (e) {
      _showErrorSnackBar(_langController.t(LangKeys.googleSignInFailed));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(String? role) {
    print("🚀 NAVIGATION - Logged in UID: ${FirebaseAuth.instance.currentUser?.uid}");
    print("🚀 NAVIGATION - Role from Firestore: $role");
    
    Widget dashboard;
    
    switch (role) {
      case 'engineer':
      case 'projectEngineer':
        print("✅ NAVIGATION - Going to Engineer Dashboard");
        dashboard = const EngineerDashboard();
        break;
      case 'manager':
      case 'fieldManager':
        print("✅ NAVIGATION - Going to Manager Dashboard");
        dashboard = const FieldManagerDashboard();
        break;
      case 'owner':
      case 'ownerClient':
        print("✅ NAVIGATION - Going to Owner Dashboard");
        dashboard = const OwnerDashboard();
        break;
      default:
        // No valid role found - this should not happen in normal flow
        print("⚠️ NAVIGATION - Invalid role '$role' - user needs to complete onboarding");
        // Navigate to welcome screen for role selection
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
        return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboard),
      (route) => false,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _langController,
      builder: (context, child) {
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
          
          // Glow blobs
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(color: primary.withValues(alpha: 0.35), size: 220),
          ),
          Positioned(
            bottom: -70,
            right: -40,
            child: _GlowBlob(color: accent.withValues(alpha: 0.32), size: 200),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  
                  // Logo + Title
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [primary, accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.engineering,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _langController.t(LangKeys.appName),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F1F1F),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_langController.t(LangKeys.login)} - ${_getRoleDisplayName(widget.selectedRole)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF5C5C5C),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Login Form Card
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 560),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.20),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Field
                                _buildGlassTextField(
                                  controller: _emailController,
                                  hint: _langController.t(LangKeys.email),
                                  icon: Icons.alternate_email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return _langController.t(LangKeys.enterYourEmail);
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return _langController.t(LangKeys.invalidEmail);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Password Field
                                _buildGlassTextField(
                                  controller: _passwordController,
                                  hint: _langController.t(LangKeys.password),
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF8E8E8E),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _langController.t(LangKeys.enterYourPassword);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Login Button
                                _GlowingButton(
                                  text: _isLoading ? _langController.t(LangKeys.pleaseWait) : _langController.t(LangKeys.logIn),
                                  onTap: _isLoading ? null : _loginWithEmail,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        _langController.t(LangKeys.orContinueWith),
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),

                                // Google Sign In Button
                                _GlassActionButton(
                                  icon: Icons.g_mobiledata,
                                  label: _langController.t(LangKeys.google),
                                  onTap: _isLoading ? null : _loginWithGoogle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_langController.t(LangKeys.newHere)),
                      TextButton(
                        onPressed: () {
                          print('🎯 LOGIN SCREEN - Create Account button clicked, navigating to RegisterScreen with role: ${widget.selectedRole}');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(selectedRole: widget.selectedRole),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4B4B4B),
                        ),
                        child: Text(_langController.t(LangKeys.createAccount)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF7B7B7B)),
          suffixIcon: suffix,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'engineer':
        return _langController.t(LangKeys.projectEngineer);
      case 'manager':
        return _langController.t(LangKeys.fieldManager);
      case 'owner':
      case 'ownerClient':
        return _langController.t(LangKeys.ownerClient);
      default:
        return 'User';
    }
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _GlowingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _GlowingButton({required this.text, this.onTap});

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primary, accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: onTap != null ? [
            BoxShadow(
              color: primary.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ] : [],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: onTap != null ? Colors.white : Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2E2E2E)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2E2E2E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}