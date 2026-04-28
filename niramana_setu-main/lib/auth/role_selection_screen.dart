import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import '../common/localization/language_controller.dart';
import '../common/localization/language_keys.dart';
import '../engineer/engineer_dashboard.dart';
import '../manager/manager.dart';
import '../owner/owner.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langController = LanguageController();
    
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
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
          // subtle glow blobs
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                // Each button takes about 26% of screen height, leaving space for header and gaps
                final cardHeight = (h * 0.26).clamp(170.0, 280.0);
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              langController.t(LangKeys.chooseYourRole),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              langController.t(LangKeys.selectHowYouUse),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF5C5C5C),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _BigGlassRoleButton(
                        height: cardHeight,
                        icon: Icons.home_repair_service,
                        title: langController.t(LangKeys.fieldManager),
                        subtitle: langController.t(LangKeys.fieldManagerDesc),
                        glowColor: primary,
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // User is logged in via Google, store role and navigate to dashboard
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'role': 'manager',
                                  'email': user.email,
                                  'fullName': user.displayName,
                                  'profilePhotoUrl': user.photoURL ?? '',
                                  'profileCompletion': 100,
                                  'isActive': true,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'lastUpdatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const FieldManagerDashboard(),
                              ),
                            );
                          } else {
                            // Not logged in, go to login screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(
                                  selectedRole: 'manager',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _BigGlassRoleButton(
                        height: cardHeight,
                        icon: Icons.architecture,
                        title: langController.t(LangKeys.projectEngineer),
                        subtitle: langController.t(LangKeys.projectEngineerDesc),
                        glowColor: accent,
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // User is logged in via Google, store role and navigate to dashboard
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'role': 'engineer',
                                  'email': user.email,
                                  'fullName': user.displayName,
                                  'profilePhotoUrl': user.photoURL ?? '',
                                  'profileCompletion': 100,
                                  'isActive': true,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'lastUpdatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const EngineerDashboard(),
                              ),
                            );
                          } else {
                            // Not logged in, go to login screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(
                                  selectedRole: 'engineer',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _BigGlassRoleButton(
                        height: cardHeight,
                        icon: Icons.apartment,
                        title: langController.t(LangKeys.ownerClient),
                        subtitle: langController.t(LangKeys.ownerClientDesc),
                        glowColor: primary,
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // User is logged in via Google, store role and navigate to dashboard
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'role': 'ownerClient',
                                  'email': user.email,
                                  'fullName': user.displayName,
                                  'profilePhotoUrl': user.photoURL ?? '',
                                  'profileCompletion': 100,
                                  'isActive': true,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'lastUpdatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const OwnerDashboard(),
                              ),
                            );
                          } else {
                            // Not logged in, go to login screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(
                                  selectedRole: 'ownerClient',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BigGlassRoleButton extends StatefulWidget {
  final double height;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color glowColor;
  final VoidCallback onTap;
  const _BigGlassRoleButton({
    required this.height,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_BigGlassRoleButton> createState() => _BigGlassRoleButtonState();
}

class _BigGlassRoleButtonState extends State<_BigGlassRoleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 1.01 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: widget.glowColor.withValues(alpha: 0.18),
                    blurRadius: 38,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing icon circle
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.glowColor.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.65),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.glowColor.withValues(alpha: 0.28),
                            blurRadius: 24,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: const Color(0xFF1F1F1F),
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: const Color(0xFF202020),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF4F4F4F),
                                  height: 1.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF7E7E7E),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadowColor = Colors.black.withValues(alpha: _pressed ? 0.08 : 0.05);

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9E9E9)),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: _pressed ? 18 : 12,
            spreadRadius: 0,
            offset: Offset(0, _pressed ? 8 : 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: Icon(widget.icon, color: const Color(0xFF5A5A5A), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F6F6F),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Color(0xFFB5B5B5)),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          scale: _pressed ? 1.01 : 1.0,
          child: Transform.translate(
            offset: Offset(0, _pressed ? -2 : 0),
            child: card,
          ),
        ),
      ),
    );
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
