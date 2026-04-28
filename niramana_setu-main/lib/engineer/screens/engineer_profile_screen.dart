import 'package:flutter/material.dart';
import '../../common/widgets/profile_resolver.dart';
import 'engineer_profile_create_screen.dart';
import 'engineer_profile_edit_screen.dart';

/// Engineer Profile Screen - Entry Point
/// 
/// This is the main entry point for engineer profile functionality.
/// Uses ProfileResolver to automatically determine whether to show
/// CREATE or EDIT screen based on profile existence in Firestore.
class EngineerProfileScreen extends StatelessWidget {
  const EngineerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileResolver(
      role: 'Engineer',
      collectionName: 'engineers',
      editScreenBuilder: (profileData) => EngineerProfileEditScreen(
        profileData: profileData,
      ),
      createScreenBuilder: () => const EngineerProfileCreateScreen(),
    );
  }
}