import 'package:flutter/material.dart';
import '../common/screens/profile_screen.dart';

/// Engineer Profile Screen
/// 
/// This screen displays the engineer's profile using the shared ProfileScreen.
/// Supports offline-first editing with automatic cloud sync.
class EngineerProfileScreen extends StatelessWidget {
  const EngineerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(role: 'projectEngineer');
  }
}
