
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/icon_tile.dart';
import '../widgets/soft_card.dart';
import '../widgets/screen_header.dart';

class ProfileScreen extends StatelessWidget {
  final bool kidsModeEnabled;
  final ValueChanged<bool> onKidsModeChanged;
  final Future<void> Function(String childProfileId) onChildSelected;

  const ProfileScreen({
    super.key,
    required this.kidsModeEnabled,
    required this.onKidsModeChanged,
    required this.onChildSelected,
  });

  // ------------------------------------------------------------
  // EDIT PARENT PROFILE
  // ------------------------------------------------------------

  Future<void> _editProfile(
    BuildContext context,
    String currentName,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Personalize profile'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Your name',
                    hintText: 'Enter your name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name.';
                    }

                    if (value.trim().length < 2) {
                      return 'Name must contain at least 2 characters.';
                    }

                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => saving = true);

                          final name = controller.text.trim();

                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                              'name': name,
                              'email': user.email,
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            await user.updateDisplayName(name);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, name);
                            }
                          } catch (error) {
                            setDialogState(() => saving = false);

                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not update profile: $error',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: purple),
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (newName != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your profile was updated successfully.'),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // CREATE CHILD FIREBASE ACCOUNT
  // ------------------------------------------------------------

  Future<void> _registerChild(BuildContext context) async {
    final parent = FirebaseAuth.instance.currentUser;

    if (parent == null) return;

    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    bool obscurePassword = true;
    bool saving = false;

    final credentials = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Register a child'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create a personal Smart Rosary account for your child. '
                        'They can later sign in using their username and password.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Child name',
                          prefixIcon: Icon(Icons.child_care_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Enter a valid child name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: usernameController,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'e.g. brian_kid',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final username =
                              value?.trim().toLowerCase() ?? '';

                          if (username.length < 3) {
                            return 'Username must have at least 3 characters.';
                          }

                          if (!RegExp(r'^[a-z0-9._]+$')
                              .hasMatch(username)) {
                            return 'Use letters, numbers, dots or underscores.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must have at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => saving = true);

                          final name = nameController.text.trim();
                          final username =
                              usernameController.text.trim().toLowerCase();
                          final password = passwordController.text;

                          final loginEmail = '$username@smartrosary.app';

                          UserCredential? childCredential;
                          FirebaseAuth? childAuth;

                          try {
                            // Create or reuse a secondary Firebase app.
                            // This keeps the parent signed in on the
                            // default Firebase app.
                            FirebaseApp childApp;

                            try {
                              childApp =
                                  Firebase.app('childRegistration');
                            } catch (_) {
                              childApp = await Firebase.initializeApp(
                                name: 'childRegistration',
                                options: Firebase.app().options,
                              );
                            }

                            childAuth =
                                FirebaseAuth.instanceFor(app: childApp);

                            // Create the child's Firebase Auth account.
                            childCredential =
                                await childAuth.createUserWithEmailAndPassword(
                              email: loginEmail,
                              password: password,
                            );

                            final childUid = childCredential.user!.uid;

                            final firestore = FirebaseFirestore.instance;
                            final batch = firestore.batch();

                            // Parent-managed child profile.
                            final childProfileRef = firestore
                                .collection('users')
                                .doc(parent.uid)
                                .collection('kids')
                                .doc(childUid);

                            // Child's own Firebase user document.
                            final childUserRef = firestore
                                .collection('users')
                                .doc(childUid);

                            batch.set(childProfileRef, {
                              'childUid': childUid,
                              'parentUid': parent.uid,
                              'name': name,
                              'username': username,
                              'loginEmail': loginEmail,
                              'accountType': 'parentManaged',
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            // IMPORTANT:
                            // uid and role are required by Firestore rules.
                            batch.set(childUserRef, {
                              'uid': childUid,
                              'name': name,
                              'username': username,
                              'email': loginEmail,
                              'role': 'child',
                              'parentUid': parent.uid,
                              'childProfileId': childUid,
                              'accountType': 'parentManagedChild',
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            // Default Firestore instance remains
                            // authenticated as the parent.
                            await batch.commit();

                            // Sign out only the secondary child Auth.
                            await childAuth.signOut();

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, {
                                'name': name,
                                'username': username,
                                'password': password,
                              });
                            }
                          } catch (error, stackTrace) {
                            debugPrint(
                              'CHILD REGISTRATION ERROR: $error',
                            );
                            debugPrintStack(stackTrace: stackTrace);

                            // Best-effort cleanup of a newly created
                            // authentication account.
                            if (childCredential?.user != null) {
                              try {
                                await childCredential!.user!.delete();
                              } catch (cleanupError) {
                                debugPrint(
                                  'CHILD ACCOUNT CLEANUP ERROR: '
                                  '$cleanupError',
                                );
                              }
                            }

                            // Keep the parent registration dialog open.
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not register child: $error',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: purple),
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create account'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();

    if (credentials == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 9),
            Expanded(child: Text('Child account created')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${credentials['name']} can now sign in independently.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 18),
            _CredentialRow(
              label: 'Username',
              value: credentials['username']!,
            ),
            const SizedBox(height: 10),
            _CredentialRow(
              label: 'Password',
              value: credentials['password']!,
            ),
            const SizedBox(height: 14),
            const Text(
              'Save these login details securely. The password will not be '
              'displayed again.',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(backgroundColor: purple),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SELECT CHILD FOR KIDS MODE
  // ------------------------------------------------------------

  Future<void> _chooseChild(BuildContext context) async {
    final parent = FirebaseAuth.instance.currentUser;

    if (parent == null) return;

    final kidsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(parent.uid)
        .collection('kids');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose a child'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: kidsRef.orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Could not load children. Check your Firestore rules.',
                    style: TextStyle(color: Colors.red),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final children = snapshot.data?.docs ?? [];

                if (children.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'You have not registered any children yet. '
                      'Add a child first to use Kids Mode.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: children.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final data = child.data();

                    final name = (data['name'] ?? 'Child').toString();
                    final username =
                        (data['username'] ?? '').toString();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFE7A8),
                        child: Icon(
                          Icons.child_care_rounded,
                          color: Color(0xFFB77916),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      subtitle: username.isEmpty ? null : Text('@$username'),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                      ),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await onChildSelected(child.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out of Smart Rosary?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: purple),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $error')),
      );
    }
  }

  // ------------------------------------------------------------
  // MAIN SCREEN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 25, 22, 125),
        children: [
          const ScreenHeader(
            eyebrow: 'Your space',
            title: 'My profile',
            subtitle: 'Make your prayer journey your own.',
          ),

          const SizedBox(height: 24),

          // Parent profile.
          if (user == null)
            const SoftCard(
              child: Text(
                'Please sign in to view your profile.',
                style: TextStyle(color: muted),
              ),
            )
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();

                final storedName = data?['name'] as String?;

                final name = storedName?.trim().isNotEmpty == true
                    ? storedName!.trim()
                    : user.displayName ?? 'User';

                final storedEmail = data?['email'] as String?;

                final email = storedEmail?.trim().isNotEmpty == true
                    ? storedEmail!.trim()
                    : user.email ?? '';

                return SoftCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFB9A4FF),
                              purple,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 43,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      const Text(
                        'Your faith journey begins here',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _editProfile(context, name),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 17,
                        ),
                        label: const Text('Personalize profile'),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 25),

          // CHILDREN MANAGEMENT

          Row(
            children: [
              const Expanded(
                child: SectionTitle(title: 'My children'),
              ),
              FilledButton.icon(
                onPressed: user == null
                    ? null
                    : () => _registerChild(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add child'),
                style: FilledButton.styleFrom(
                  backgroundColor: purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (user != null)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('kids')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SoftCard(
                    child: Text(
                      'Unable to load your children. Check your Firestore rules.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SoftCard(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final children = snapshot.data?.docs ?? [];

                if (children.isEmpty) {
                  return SoftCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.family_restroom_rounded,
                          size: 42,
                          color: Color(0xFF9A7AE8),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No children registered yet',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add your child to create their own prayer account '
                          'and track their learning progress.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => _registerChild(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Register your first child'),
                          style: FilledButton.styleFrom(
                            backgroundColor: purple,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: children.map((child) {
                    final data = child.data();

                    final name = (data['name'] ?? 'Child').toString();
                    final username =
                        (data['username'] ?? '').toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: SoftCard(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Container(
                              width: 49,
                              height: 49,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE7A8),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.child_care_rounded,
                                color: Color(0xFFB77916),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (username.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '@$username',
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Child account',
                                    style: TextStyle(
                                      color: Color(0xFF278443),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Open Kids Mode',
                              onPressed: () async {
                                await onChildSelected(child.id);
                              },
                              icon: const Icon(
                                Icons.play_circle_fill_rounded,
                                color: purple,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

          const SizedBox(height: 25),

          const SectionTitle(title: 'Experience'),

          const SizedBox(height: 12),

          // KIDS MODE

          SoftCard(
            padding: const EdgeInsets.all(17),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE7A8),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.child_care_rounded,
                        size: 30,
                        color: Color(0xFFB77916),
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kids Mode',
                            style: TextStyle(
                              color: ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'A fun, simple prayer adventure for children.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: kidsModeEnabled,
                      onChanged: (enabled) {
                        if (enabled) {
                          _chooseChild(context);
                        } else {
                          onKidsModeChanged(false);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: kidsModeEnabled
                        ? const Color(0xFFE8F8E9)
                        : const Color(0xFFF2EDFF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        kidsModeEnabled
                            ? Icons.celebration_rounded
                            : Icons.auto_awesome_rounded,
                        color: kidsModeEnabled
                            ? const Color(0xFF278443)
                            : const Color(0xFF8056D8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kidsModeEnabled
                              ? 'Kids Mode is on! Your child-friendly experience is active.'
                              : 'Choose a child to open their personal prayer experience.',
                          style: const TextStyle(
                            color: ink,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const SectionTitle(title: 'Settings'),

          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.child_care_rounded,
            title: 'Learning level',
            subtitle: 'Personalize learning for your child',
            onTap: () => _showComingSoon(context, 'Learning levels'),
          ),

          _SettingsTile(
            icon: Icons.volume_up_rounded,
            title: 'Sound & audio',
            subtitle: 'Prayer audio preferences',
            onTap: () => _showComingSoon(context, 'Audio preferences'),
          ),

          _SettingsTile(
            icon: Icons.family_restroom_rounded,
            title: 'Parent area',
            subtitle: 'Parent and guardian settings',
            onTap: () => _showComingSoon(context, 'Parent management'),
          ),

          _SettingsTile(
            icon: Icons.bluetooth_rounded,
            title: 'Rosary device',
            subtitle: 'Future Bluetooth connection settings',
            onTap: () => _showComingSoon(
              context,
              'Arduino Bluetooth connection',
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Center(
            child: Text(
              'SMART ROSARY  •  LEARN, PRAY, GROW',
              style: TextStyle(
                color: muted,
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be implemented in the next phase.'),
      ),
    );
  }
}

// --------------------------------------------------------------
// CREDENTIAL DISPLAY
// --------------------------------------------------------------

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;

  const _CredentialRow({
    required this.label,
    required this.value,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy_rounded, size: 18),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------
// SETTINGS TILE
// --------------------------------------------------------------

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              IconTile(
                icon: icon,
                size: 46,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
