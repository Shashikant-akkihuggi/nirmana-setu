import 'package:flutter/material.dart';
import '../../common/widgets/profile_resolver.dart';
import 'manager_profile_create_screen.dart';
import 'manager_profile_edit_screen.dart';

/// Field Manager Profile Screen - Entry Point
/// 
/// This is the main entry point for field manager profile functionality.
/// Uses ProfileResolver to automatically determine whether to show
/// CREATE or EDIT screen based on profile existence in Firestore.
class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileResolver(
      role: 'Field Manager',
      collectionName: 'field_managers',
      editScreenBuilder: (profileData) => ManagerProfileEditScreen(
        profileData: profileData,
      ),
      createScreenBuilder: () => const ManagerProfileCreateScreen(),
    );
  }
}