import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../common/localization/language_controller.dart';
import '../common/localization/language_keys.dart';
import 'onboarding/onboarding_step1_identity.dart';

class RegisterScreen extends StatefulWidget {
  final String selectedRole;

  const RegisterScreen({
    super.key,
    required this.selectedRole,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _langController = LanguageController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _proceedToOnboarding() {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      _showErrorSnackBar(_langController.t(LangKeys.pleaseAcceptTerms));
      return;
    }

    setState(() => _isLoading = true);

    print('🎯 REGISTER SCREEN - Selected Role: ${widget.selectedRole}');
    print('📧 REGISTER SCREEN - Email: ${_emailController.text.trim()}');

    // Navigate to onboarding with role, email, and password
    // The actual Firebase Auth account creation will happen in onboarding step 1
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnboardingStep1Identity(
          role: widget.selectedRole,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      ),
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
            child: _GlowBlob(color: primary.withValues(alpha: 0.28), size: 200),
          ),
          Positioned(
            bottom: -70,
            right: -40,
            child: _GlowBlob(color: accent.withValues(alpha: 0.26), size: 190),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  
                  // Logo + Title
                  Column(
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
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
                        '${_langController.t(LangKeys.createAccount)} - ${_getRoleDisplayName(widget.selectedRole)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF5C5C5C),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Registration Form Card
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
                                      return _langController.t(LangKeys.emailRequired);
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
                                    if (value.length < 6) {
                                      return _langController.t(LangKeys.passwordMinLength);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // Confirm Password Field
                                _buildGlassTextField(
                                  controller: _confirmPasswordController,
                                  hint: _langController.t(LangKeys.confirmPassword),
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureConfirmPassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF8E8E8E),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _langController.t(LangKeys.confirmPassword);
                                    }
                                    if (value != _passwordController.text) {
                                      return _langController.t(LangKeys.passwordsDoNotMatch);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Terms & Privacy Checkbox
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreedToTerms = value ?? false;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _langController.t(LangKeys.agreeToTerms),
                                        style: const TextStyle(
                                          color: Color(0xFF3F3F3F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Create Account Button
                                _GlowingButton(
                                  text: _isLoading ? _langController.t(LangKeys.pleaseWait) : _langController.t(LangKeys.createAccount),
                                  onTap: _isLoading ? null : _proceedToOnboarding,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Info Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Next, we\'ll collect your profile information to complete your account setup.',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_langController.t(LangKeys.alreadyHaveAccount)),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4B4B4B),
                        ),
                        child: Text(_langController.t(LangKeys.logIn)),
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