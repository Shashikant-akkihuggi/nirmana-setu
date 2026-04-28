import 'package:flutter/material.dart';
import '../../common/widgets/profile_resolver.dart';
import 'owner_profile_create_screen.dart';
import 'owner_profile_edit_screen.dart';

/// Owner Profile Screen - Entry Point
/// 
/// This is the main entry point for owner profile functionality.
/// Uses ProfileResolver to automatically determine whether to show
/// CREATE or EDIT screen based on profile existence in Firestore.
class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileResolver(
      role: 'Owner',
      collectionName: 'owners',
      editScreenBuilder: (profileData) => OwnerProfileEditScreen(
        profileData: profileData,
      ),
      createScreenBuilder: () => const OwnerProfileCreateScreen(),
    );
  }
}

/// Stream-based version for real-time updates
class OwnerProfileScreenStream extends StatelessWidget {
  const OwnerProfileScreenStream({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileResolverStream(
      role: 'Owner',
      collectionName: 'owners',
      editScreenBuilder: (profileData) => OwnerProfileEditScreen(
        profileData: profileData,
      ),
      createScreenBuilder: () => const OwnerProfileCreateScreen(),
    );
  }
}