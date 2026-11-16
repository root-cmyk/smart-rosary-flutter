
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/auth_screen.dart';
import '../screens/kids_mode_screen.dart';
import 'main_navigation.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>> _loadProfile(User user) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!snapshot.exists) {
      throw Exception(
        'Your account profile is missing. '
        'Please contact support before continuing.',
      );
    }

    final data = snapshot.data();

    if (data == null ||
        (data['role'] != 'parent' && data['role'] != 'child')) {
      throw Exception(
        'Your account has an invalid role. '
        'Please contact support.',
      );
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const AuthScreen();
        }

        return FutureBuilder<Map<String, dynamic>>(
          key: ValueKey(user.uid),
          future: _loadProfile(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return _MessageScreen(
                message: 'Could not load your account profile.\n\n'
                    '${profileSnapshot.error}',
                onSignOut: () async {
                  await FirebaseAuth.instance.signOut();
                },
              );
            }

            final profile = profileSnapshot.data!;
            final role = profile['role'];

            if (role == 'child') {
              final accountType = profile['accountType'];

              final parentUid = profile['parentUid'] as String?;
              final childProfileId =
                  profile['childProfileId'] as String?;

              // A parent-managed child must have both linking fields.
              if (accountType == 'parentManagedChild' &&
                  (parentUid == null ||
                      parentUid.isEmpty ||
                      childProfileId == null ||
                      childProfileId.isEmpty)) {
                return _MessageScreen(
                  message: 'Your child account is not properly linked '
                      'to its parent profile. Please contact support.',
                  onSignOut: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                );
              }

              return KidsModeScreen(
                onExitKidsMode: () async {
                  await FirebaseAuth.instance.signOut();
                },
                parentUid: parentUid,
                childProfileId: childProfileId,
              );
            }

            return const MainNavigation();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _MessageScreen extends StatelessWidget {
  final String message;
  final Future<void> Function() onSignOut;

  const _MessageScreen({
    required this.message,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
