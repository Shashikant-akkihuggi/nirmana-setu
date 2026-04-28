import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ProfileResolver - Smart Profile Gate Widget
/// 
/// This widget handles the complete profile flow:
/// 1. Check if Firestore document exists
/// 2. Route to CREATE or EDIT screen accordingly
/// 3. Handle loading, error, and success states
/// 4. Works for all roles (Owner, Engineer, Field Manager)
class ProfileResolver extends StatelessWidget {
  final String role;
  final String collectionName;
  final Widget Function(Map<String, dynamic> profileData) editScreenBuilder;
  final Widget Function() createScreenBuilder;

  const ProfileResolver({
    super.key,
    required this.role,
    required this.collectionName,
    required this.editScreenBuilder,
    required this.createScreenBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not authenticated'),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('$role Profile'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('$role Profile'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text('Error loading profile'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Success state - decide CREATE vs EDIT
        final doc = snapshot.data!;
        
        if (doc.exists && doc.data() != null) {
          // Profile exists -> EDIT mode
          final profileData = doc.data() as Map<String, dynamic>;
          return editScreenBuilder(profileData);
        } else {
          // Profile doesn't exist -> CREATE mode
          return createScreenBuilder();
        }
      },
    );
  }
}

/// ProfileResolverV2 - Stream-based version for real-time updates
class ProfileResolverStream extends StatelessWidget {
  final String role;
  final String collectionName;
  final Widget Function(Map<String, dynamic> profileData) editScreenBuilder;
  final Widget Function() createScreenBuilder;

  const ProfileResolverStream({
    super.key,
    required this.role,
    required this.collectionName,
    required this.editScreenBuilder,
    required this.createScreenBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not authenticated'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('$role Profile'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('$role Profile'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text('Error loading profile'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Success state - decide CREATE vs EDIT
        final doc = snapshot.data!;
        
        if (doc.exists && doc.data() != null) {
          // Profile exists -> EDIT mode
          final profileData = doc.data() as Map<String, dynamic>;
          return editScreenBuilder(profileData);
        } else {
          // Profile doesn't exist -> CREATE mode
          return createScreenBuilder();
        }
      },
    );
  }
}