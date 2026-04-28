import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart'; // Import WelcomeScreen from main.dart

/// Central Logout Service
/// 
/// This service provides a reusable logout mechanism for all user roles.
/// 
/// Why centralized?
/// - Single source of truth for logout logic
/// - Consistent behavior across all dashboards (Owner, Engineer, Manager)
/// - Easy to maintain and update
/// - Prevents code duplication
/// 
/// Why clear navigation stack?
/// - Prevents users from pressing back button to return to dashboard
/// - Ensures complete session termination
/// - Provides clean user experience similar to Instagram/WhatsApp
class LogoutService {
  /// Logs out the current user and returns to welcome screen
  /// 
  /// This method:
  /// 1. Signs out from Firebase Authentication
  /// 2. Clears the entire navigation stack using pushAndRemoveUntil
  /// 3. Navigates to WelcomeScreen (imported from main.dart)
  /// 4. Handles errors gracefully with user-friendly messages
  /// 
  /// Parameters:
  /// - context: BuildContext required for navigation and showing SnackBar
  /// 
  /// Note: This does NOT delete user data from Firestore.
  /// User data remains intact for next login session.
  /// 
  /// How it works:
  /// - After signOut(), FirebaseAuth.instance.currentUser becomes null
  /// - We navigate to WelcomeScreen and clear all routes
  /// - pushAndRemoveUntil with (route) => false removes ALL routes
  /// - This prevents back button from returning to dashboard
  /// - User must log in again to access any dashboard
  static Future<void> logout(BuildContext context) async {
    try {
      // Sign out from Firebase Authentication
      // This clears the current user session and sets currentUser to null
      await FirebaseAuth.instance.signOut();
      
      // Navigate to WelcomeScreen and clear all previous routes
      // pushAndRemoveUntil removes all routes from the stack
      // (route) => false means remove ALL routes
      // This prevents back button from returning to dashboard
      if (!context.mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
        (route) => false,
      );
      
    } catch (e) {
      // Handle logout errors gracefully
      // Show user-friendly error message via SnackBar
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
