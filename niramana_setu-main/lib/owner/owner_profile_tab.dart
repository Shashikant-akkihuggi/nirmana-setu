import 'package:flutter/material.dart';
import '../common/screens/profile_screen.dart';

/// Owner Profile Tab
/// 
/// This is a thin wrapper around the shared ProfileScreen.
/// It provides the role context for the Owner dashboard.
/// 
/// Why a wrapper?
/// - Keeps role-specific code in role-specific folders
/// - Allows future customization per role if needed
/// - Maintains clean architecture
/// - No logic duplication
class OwnerProfileTab extends StatelessWidget {
  const OwnerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(role: 'ownerClient');
  }
}
