import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'engineer/engineer_dashboard.dart';
import 'owner/owner.dart';
import 'manager/manager.dart';
import 'purchase_manager/screens/purchase_manager_dashboard.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/offline_sync_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'common/localization/app_language_controller.dart';
import 'common/localization/language_controller.dart';
import 'common/screens/language_selection_screen.dart';
import 'common/project_context.dart';
import 'models/offline_dpr_model.dart';
import 'common/services/connectivity_service.dart';
import 'common/services/profile_repository.dart';
import 'common/models/user_profile_adapter.dart';
import 'config/cloudinary_config.dart';
import 'auth/register_screen.dart';

/// Generate public ID in format: (first 4 letters of name, lowercase) + (4 random digits)
/// Example: "Shashikanth" -> "shas4821"
String generatePublicId(String name) {
  final cleanName = name.trim().toLowerCase();
  final prefix = cleanName.length >= 4
      ? cleanName.substring(0, 4)
      : cleanName.padRight(4, 'x');
  
  final random = Random().nextInt(9000) + 1000; // 4 digits (1000-9999)
  return '$prefix$random';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register UserProfile adapter for profile caching
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserProfileAdapter());
  }
  
  // Register OfflineDprModel adapter
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(OfflineDprModelAdapter());
  }
  
  await Hive.openBox('offline_dprs');
  await Hive.openBox<OfflineDprModel>('offline_dpr_models');
  await Hive.openBox('offline_material_requests');

  // Milestones box (local-first)
  if (!Hive.isAdapterRegistered(21)) {
    // Manual adapter for milestones
    try {
      // ignore: invalid_use_of_internal_member
    } catch (_) {}
  }
  // The repository will register the adapter and open box lazily.

  // Initialize Profile Repository
  await ProfileRepository().initialize();
  print('ProfileRepository initialized');

  // Initialize Offline Sync Service
  await OfflineSyncService().init();

  // Initialize Connectivity Service
  await ConnectivityService().initialize();

  // Validate Cloudinary Configuration
  assert(
    CloudinaryConfig.cloudName.isNotEmpty,
    "Cloudinary cloudName missing",
  );
  assert(
    CloudinaryConfig.uploadPreset.isNotEmpty,
    "Cloudinary uploadPreset missing",
  );
  print("Cloudinary configured: ${CloudinaryConfig.cloudName}");

  // Initialize Language Controller
  // This loads the saved language preference from Hive
  await AppLanguageController().initialize();
  await LanguageController().initialize();

  // CRITICAL: Clear project context on app startup
  ProjectContext.clearActiveProject();

  print("Firebase connected & Hive initialized!");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap with AnimatedBuilder to listen to language changes
    // This allows hot language switching without app restart
    return AnimatedBuilder(
      animation: LanguageController(),
      builder: (context, child) {
        final languageController = LanguageController();
        return MaterialApp(
          title: 'Niramana Setu',
          debugShowCheckedModeBanner: false,
          locale: languageController.currentLocale,
          supportedLocales: languageController.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F4F4F),
              brightness: Brightness.light,
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: const Color(0xFF2E2E2E),
              displayColor: const Color(0xFF2E2E2E),
            ),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// Auth Wrapper to handle auto-login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  Widget _homeWidget = const WelcomeScreen();
  final LanguageController _langController = LanguageController();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // First check if user has selected a language
    // If not, force language selection before anything else
    if (!_langController.hasSelectedLanguage) {
      setState(() {
        _homeWidget = LanguageSelectionScreen(
          onLanguageSelected: () {
            // After language selection, check auth state
            _checkAuthState();
          },
        );
        _isLoading = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // User is logged in, fetch their role from Firestore
      try {
        print("Logged in UID: ${user.uid}");
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final role = userDoc.data()?['role'];
          print("Role from Firestore: $role");
          print("User document data: ${userDoc.data()}");
          
          // Navigate to appropriate dashboard based on role
          if (role == 'manager' || role == 'fieldManager') {
            print("✅ Navigating to Manager Dashboard");
            setState(() {
              _homeWidget = const FieldManagerDashboard();
              _isLoading = false;
            });
          } else if (role == 'engineer' || role == 'projectEngineer') {
            print("✅ Navigating to Engineer Dashboard");
            setState(() {
              _homeWidget = const EngineerDashboard();
              _isLoading = false;
            });
          } else if (role == 'ownerClient') {
            print("✅ Navigating to Owner Dashboard");
            setState(() {
              _homeWidget = const OwnerDashboard();
              _isLoading = false;
            });
          } else if (role == 'purchaseManager' || role == 'purchasemanager') {
            print("✅ Navigating to Purchase Manager Dashboard");
            setState(() {
              _homeWidget = const PurchaseManagerDashboard();
              _isLoading = false;
            });
          } else {
            // Role not found or invalid, show welcome screen for role selection
            print("⚠️ Invalid or missing role: $role - showing welcome screen");
            setState(() {
              _homeWidget = const WelcomeScreen();
              _isLoading = false;
            });
          }
        } else {
          // User exists in Auth but not in Firestore, show welcome screen
          setState(() {
            _homeWidget = const WelcomeScreen();
            _isLoading = false;
          });
        }
      } catch (e) {
        // Error fetching user data, show welcome screen
        setState(() {
          _homeWidget = const WelcomeScreen();
          _isLoading = false;
        });
      }
    } else {
      // No user logged in, show welcome screen
      setState(() {
        _homeWidget = const WelcomeScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _homeWidget;
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langController = LanguageController();
    
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final isNarrow = maxW < 360;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 20 : 28,
                vertical: isNarrow ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Center illustration inside a soft rounded phone frame
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFE7E7E7),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/images/splash_illustration.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    langController.t('app_name'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    langController.t('manage_projects_ease'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6F6F6F),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Get Started button at the bottom
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to Language Selection first
                            // After language is selected, user will proceed to role selection
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LanguageSelectionScreen(
                                  onLanguageSelected: () {
                                    // After language selection, navigate to role selection
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const RoleSelectionScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2E2E2E),
                            elevation: 6,
                            shadowColor: Colors.black.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          child: Text(langController.t('get_started')),
                        ),
                        const SizedBox(height: 8),
                        // Note: Engineer Dashboard opens only after Project Engineer login
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// A calm grayscale line-art illustration of a planner/engineer at a desk
class _LineArtPlannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Light desk
    final deskY = size.height * 0.68;
    canvas.drawLine(Offset(0, deskY), Offset(size.width, deskY), stroke);

    // Monitor outline
    final monitorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.40, size.height * 0.42),
        width: size.width * 0.38,
        height: size.height * 0.22,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(monitorRect, stroke);

    // Monitor base
    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.53),
      Offset(size.width * 0.40, size.height * 0.60),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.40, size.height * 0.61),
          width: size.width * 0.18,
          height: size.height * 0.02,
        ),
        const Radius.circular(4),
      ),
      stroke,
    );

    // Planner/engineer simplified figure
    final headCenter = Offset(size.width * 0.68, size.height * 0.38);
    canvas.drawCircle(headCenter, size.width * 0.055, stroke);

    // Body
    final shoulderY = size.height * 0.45;
    canvas.drawLine(
      Offset(size.width * 0.60, shoulderY),
      Offset(size.width * 0.76, shoulderY),
      stroke,
    );

    // Arms to desk
    canvas.drawLine(
      Offset(size.width * 0.62, shoulderY),
      Offset(size.width * 0.58, deskY),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.74, shoulderY),
      Offset(size.width * 0.80, deskY),
      stroke,
    );

    // Blueprint roll on desk
    final rollRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.55, deskY - size.height * 0.06),
        width: size.width * 0.32,
        height: size.height * 0.06,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(rollRect, stroke);
    canvas.drawLine(
      Offset(size.width * 0.40, deskY - size.height * 0.06),
      Offset(size.width * 0.70, deskY - size.height * 0.06),
      stroke,
    );

    // Phone/tablet device outline
    final tabletRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.25, deskY - size.height * 0.05),
        width: size.width * 0.20,
        height: size.height * 0.12,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(tabletRect, stroke);

    // Light backdrop shapes
    final soft = Paint()
      ..color = const Color(0xFFF2F2F2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.14,
          size.width * 0.22,
          size.height * 0.10,
        ),
        const Radius.circular(8),
      ),
      soft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.62,
          size.height * 0.18,
          size.width * 0.22,
          size.height * 0.10,
        ),
        const Radius.circular(8),
      ),
      soft,
    );

    // Subtle grid lines on monitor
    for (int i = 1; i <= 3; i++) {
      final dx =
          monitorRect.outerRect.left + (monitorRect.outerRect.width / 4) * i;
      canvas.drawLine(
        Offset(dx, monitorRect.outerRect.top + 8),
        Offset(dx, monitorRect.outerRect.bottom - 8),
        stroke..color = const Color(0xFFD6D6D6),
      );
    }
    for (int i = 1; i <= 2; i++) {
      final dy =
          monitorRect.outerRect.top + (monitorRect.outerRect.height / 3) * i;
      canvas.drawLine(
        Offset(monitorRect.outerRect.left + 8, dy),
        Offset(monitorRect.outerRect.right - 8, dy),
        stroke..color = const Color(0xFFD6D6D6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Role Selection Screen
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
                              langController.t('choose_your_role'),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              langController.t('select_how_you_use'),
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
                        title: langController.t('field_manager'),
                        subtitle: langController.t('field_manager_desc'),
                        glowColor: primary,
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // User is logged in via Google, store role and navigate to dashboard
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'role': 'manager', // Updated role name
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
                        title: langController.t('project_engineer'),
                        subtitle: langController.t('project_engineer_desc'),
                        glowColor: accent,
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // User is logged in via Google, store role and navigate to dashboard
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'role': 'engineer', // Updated role name
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
                        title: langController.t('owner_client'),
                        subtitle: langController.t('owner_client_desc'),
                        glowColor: primary,
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // User is logged in via Google, store role and navigate to dashboard
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'role': 'ownerClient', // Updated role name
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
                            print('🎯 WELCOME SCREEN - Owner button clicked, navigating to LoginScreen with role: ownerClient');
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
                      const SizedBox(height: 12),
                      _BigGlassRoleButton(
                        height: cardHeight,
                        icon: Icons.shopping_cart,
                        title: 'Purchase Manager',
                        subtitle: 'Manage material procurement and POs',
                        glowColor: accent,
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // User is logged in via Google, store role and navigate to dashboard
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                                  'role': 'purchaseManager',
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
                                builder: (_) => const PurchaseManagerDashboard(),
                              ),
                            );
                          } else {
                            // Not logged in, go to login screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(
                                  selectedRole: 'purchaseManager',
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
    final shadowColor = Colors.black.withValues(alpha: _pressed ? 0.10 : 0.05);

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

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6F6F6F),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  final String selectedRole;
  const LoginScreen({super.key, required this.selectedRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscure = true;
  bool _isLoading = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login with email and password
  Future<void> _loginWithEmail() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() => _isLoading = false);

        if (userDoc.exists) {
          // Existing user - navigate to role-based dashboard
          final role = userDoc.data()?['role'];
          _navigateToDashboard(role);
        } else {
          // User exists in Auth but not in Firestore
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account not found. Please create an account.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = 'Login failed. Please check your credentials.';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          errorMessage = 'No account found with this email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email address.';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'This account has been disabled.';
        } else if (e.code == 'invalid-credential') {
          errorMessage = 'Invalid email or password.';
        } else {
          errorMessage = 'Login failed. Please try again.';
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  // Navigate to appropriate dashboard based on role
  void _navigateToDashboard(String? role) {
    print("Logged in UID: ${FirebaseAuth.instance.currentUser?.uid}");
    print("Role from Firestore: $role");
    
    switch (role) {
      case 'manager':
      case 'fieldManager':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FieldManagerDashboard()),
        );
        break;
      case 'engineer':
      case 'projectEngineer':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EngineerDashboard()),
        );
        break;
      case 'owner':
      case 'ownerClient':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerDashboard()),
        );
        break;
      default:
        print("⚠️ Invalid role '$role' - staying on welcome screen");
        // Don't navigate anywhere - stay on welcome screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient + soft glows
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
                        'Niramana Setu',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F1F1F),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage projects with ease',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF5C5C5C),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Floating Glass Login Card
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Illustration
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _LineArtPlannerPainter(),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: accent.withValues(
                                                alpha: 0.10,
                                              ),
                                              blurRadius: 22,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _glassTextField(
                                      controller: _emailController,
                                      hint: 'Email',
                                      icon: Icons.alternate_email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Enter your email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _glassTextField(
                                      controller: _passwordController,
                                      hint: 'Password',
                                      icon: Icons.lock_outline,
                                      obscure: _obscure,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: const Color(0xFF8E8E8E),
                                        ),
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty)
                                          return 'Enter your password';
                                        if (v.length < 6)
                                          return 'Password must be at least 6 characters';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Forgot password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ForgotPasswordScreen(
                                                    selectedRole:
                                                        widget.selectedRole,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF424242,
                                          ),
                                        ),
                                        child: const Text('Forgot password?'),
                                      ),
                                    ),
                                    const SizedBox(height: 4),

                                    // Login button
                                    _GlowingButton(
                                      text: _isLoading ? 'Please wait...' : 'Log In',
                                      onTap: _isLoading
                                          ? () {}
                                          : () {
                                              if (_formKey.currentState?.validate() ?? false) {
                                                _loginWithEmail();
                                              }
                                            },
                                    ),

                                    const SizedBox(height: 14),
                                    _DividerText(text: 'or continue with'),
                                    const SizedBox(height: 14),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _GlassActionButton(
                                            icon: Icons.g_mobiledata,
                                            label: 'Google',
                                            onTap: () async {
                                              try {
                                                final userCredential =
                                                    await _authService
                                                        .signInWithGoogle();
                                                final user =
                                                    userCredential.user;
                                                if (user != null) {
                                                  // Check if user exists in Firestore
                                                  final userDoc =
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(user.uid)
                                                          .get();

                                                  if (userDoc.exists) {
                                                    // Existing user - navigate to role-based dashboard
                                                    final role = userDoc
                                                        .data()?['role'];
                                                    if (!mounted) return;
                                                    if (role ==
                                                        'fieldManager') {
                                                      Navigator.of(
                                                        context,
                                                      ).pushReplacement(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const FieldManagerDashboard(),
                                                        ),
                                                      );
                                                    } else if (role ==
                                                        'projectEngineer') {
                                                      Navigator.of(
                                                        context,
                                                      ).pushReplacement(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const EngineerDashboard(),
                                                        ),
                                                      );
                                                    } else if (role ==
                                                        'ownerClient') {
                                                      Navigator.of(
                                                        context,
                                                      ).pushReplacement(
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const OwnerDashboard(),
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    // New user - navigate to role selection
                                                    if (!mounted) return;
                                                    Navigator.of(
                                                      context,
                                                    ).pushReplacement(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const RoleSelectionScreen(),
                                                      ),
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Google sign-in failed. Please try again.',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _GlassActionButton(
                                            icon: Icons.facebook,
                                            label: 'Facebook',
                                            onTap: () {},
                                          ),
                                        ),
                                      ],
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

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New here? '),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                selectedRole: widget.selectedRole,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4B4B4B),
                        ),
                        child: const Text('Create account'),
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
  }

  // Glass-styled text field
  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscure = false,
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
        obscureText: obscure,
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

class _DividerText extends StatelessWidget {
  final String text;
  const _DividerText({required this.text});
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: const Color(0xFF666666));
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFE6E6E6))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(text, style: style),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFE6E6E6))),
      ],
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
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

class ForgotPasswordScreen extends StatefulWidget {
  final String selectedRole;
  const ForgotPasswordScreen({super.key, required this.selectedRole});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  bool _sent = false;

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient + glows
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
          Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(color: primary.withValues(alpha: 0.30), size: 200),
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
                  // Top section
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
                          Icons.lock_reset,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reset your password',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F1F1F),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter your email or phone to receive a reset link.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF5C5C5C),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

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
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Input
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _contactController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Enter email or phone'
                                        : null,
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.alternate_email,
                                        color: Color(0xFF7B7B7B),
                                      ),
                                      hintText: 'Email or phone',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                _GlowingButton(
                                  text: _sent ? 'Link Sent' : 'Send Reset Link',
                                  onTap: () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      setState(() => _sent = true);
                                      // Show a subtle success checkmark snackbar
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: const [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Reset instructions will be sent if the account exists.',
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.75),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_sent)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    if (_sent) const SizedBox(width: 6),
                                    const Flexible(
                                      child: Text(
                                        "We'll send instructions to your registered account.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF4B4B4B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Back to '),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4B4B4B),
                        ),
                        child: const Text('Login'),
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
  }
}

/* FieldManagerDashboard moved to lib/manager.dart to keep main.dart lean.
  const FieldManagerDashboard({super.key});

  static const Color primary = Color(0xFF136DEC);
  static const Color accent = Color(0xFF7A5AF8);
  static const Color mint = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient + glows
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
          Positioned(top: -80, left: -60, child: _GlowBlob(color: primary.withValues(alpha: 0.30), size: 220)),
          Positioned(bottom: -70, right: -40, child: _GlowBlob(color: accent.withValues(alpha: 0.28), size: 200)),

          SafeArea(
            child: Column(
              children: [
                // Header glass strip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                            BoxShadow(color: primary.withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Hi, Field Manager 👷', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
                                  SizedBox(height: 4),
                                  Text("Here's your site overview today", style: TextStyle(color: Color(0xFF5C5C5C))),
                                ],
                              ),
                            ),
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [primary, accent]),
                                boxShadow: [
                                  BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 14, spreadRadius: 1),
                                ],
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content scrollable area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Key metrics
                        SizedBox(
                          height: 96,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: const [
                              _GlassStatCard(title: 'Active Projects', icon: Icons.apartment, value: 7),
                              SizedBox(width: 12),
                              _GlassStatCard(title: 'Workers Today', icon: Icons.groups, value: 128),
                              SizedBox(width: 12),
                              _GlassStatCard(title: 'Tasks Pending', icon: Icons.playlist_add_check_circle_outlined, value: 19),
                              SizedBox(width: 12),
                              _GlassStatCard(title: 'Issues Reported', icon: Icons.report_problem, value: 3),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Project list
                        const _ProjectCard(
                          name: 'Skyline Tower A',
                          location: 'Sector 14, Pune',
                          start: '12 Jan 2024',
                          end: '30 Nov 2025',
                          progress: 0.62,
                          status: 'On Track',
                        ),
                        const SizedBox(height: 12),
                        const _ProjectCard(
                          name: 'Metro Line Ext.',
                          location: 'Phase 2, Bengaluru',
                          start: '01 Mar 2024',
                          end: '15 Dec 2025',
                          progress: 0.48,
                          status: 'Delayed',
                        ),
                        const SizedBox(height: 12),
                        const _ProjectCard(
                          name: 'Green Park Housing',
                          location: 'Plot 9, Ahmedabad',
                          start: '05 May 2024',
                          end: '10 Oct 2025',
                          progress: 0.31,
                          status: 'Critical',
                        ),
                        const SizedBox(height: 18),

                        // Quick actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _QuickAction(icon: Icons.assignment_add, label: 'DPR'),
                            _QuickAction(icon: Icons.how_to_reg, label: 'Attendance'),
                            _QuickAction(icon: Icons.warehouse, label: 'Materials'),
                            _QuickAction(icon: Icons.notifications_active, label: 'Alerts'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _GlassBottomNav(currentIndex: 0),
    );
  }
}

  final String title;
  final IconData icon;
  final int value;
  const _GlassStatCard({required this.title, required this.icon, required this.value});

  @override
  State<_GlassStatCard> createState() => _GlassStatCardState();
}

class _GlassStatCardState extends State<_GlassStatCard> {
  double _t = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() => _t = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [FieldManagerDashboard.primary, FieldManagerDashboard.accent]),
                  boxShadow: [BoxShadow(color: FieldManagerDashboard.primary.withValues(alpha: 0.25), blurRadius: 14)],
                ),
                child: Icon(widget.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A4A))),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: widget.value.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F)),
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
}

  final String name;
  final String location;
  final String start;
  final String end;
  final double progress;
  final String status; // On Track / Delayed / Critical
  const _ProjectCard({super.key, required this.name, required this.location, required this.start, required this.end, required this.progress, required this.status});

  Color get statusColor {
    switch (status) {
      case 'On Track':
        return const Color(0xFF16A34A);
      case 'Delayed':
        return const Color(0xFFF59E0B);
      case 'Critical':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8)),
              BoxShadow(color: FieldManagerDashboard.primary.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 1),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF202020))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(location, style: const TextStyle(color: Color(0xFF4B5563))),
              const SizedBox(height: 8),
              Text('Start: $start    End: $end', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const SizedBox(height: 10),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, c) => AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      width: c.maxWidth * progress,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF10B981)]),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 1)],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF1F2937)),
                  label: const Text('View Details', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [FieldManagerDashboard.primary, FieldManagerDashboard.accent]),
            boxShadow: [
              BoxShadow(color: FieldManagerDashboard.primary.withValues(alpha: 0.32), blurRadius: 18, spreadRadius: 1, offset: const Offset(0, 6)),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
      ],
    );
  }
}

  final int currentIndex;
  const _GlassBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(icon: Icons.home_rounded, label: 'Dashboard', active: currentIndex == 0),
              _navItem(icon: Icons.description_rounded, label: 'Reports', active: currentIndex == 1),
              _navItem(icon: Icons.inventory_2_rounded, label: 'Materials', active: currentIndex == 2),
              _navItem(icon: Icons.person_rounded, label: 'Profile', active: currentIndex == 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required bool active}) {
    final Color c = active ? const Color(0xFF111827) : const Color(0xFF6B7280);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}

*/

// Missing UI components that were removed with SignupScreen
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


