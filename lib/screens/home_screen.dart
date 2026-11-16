
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_message.dart';
import '../widgets/icon_tile.dart';
import '../widgets/soft_card.dart';
import '../widgets/screen_header.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigate;

  const HomeScreen({
    super.key,
    this.onNavigate,
  });

  void _goToTab(BuildContext context, int index, String fallbackMessage) {
    if (onNavigate != null) {
      onNavigate!(index);
    } else {
      showMessage(context, fallbackMessage);
    }
  }

  Future<void> _showAddChildDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddChildDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // APP HEADER
            Row(
              children: [
               
              
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    showMessage(
                      context,
                      'You are all caught up. More notification features are coming soon.',
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // PERSONAL GREETING
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: currentUser == null
                  ? const Stream.empty()
                  : FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                final profile = snapshot.data?.data();
                final storedName = profile?['name'];
                final firestoreName =
                    storedName is String ? storedName.trim() : '';
                final authName = currentUser?.displayName?.trim() ?? '';

                final displayName = firestoreName.isNotEmpty
                    ? firestoreName
                    : authName.isNotEmpty
                        ? authName
                        : 'Friend';

                return Text(
                  'Hello, $displayName!',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: ink,
                    letterSpacing: -0.7,
                  ),
                );
              },
            ),

            const SizedBox(height: 9),

            const Text(
              'Every little prayer brings you closer to God.',
              style: TextStyle(color: muted, fontSize: 14),
            ),

            const SizedBox(height: 24),

            // DAILY MOMENT CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9B7AF3),
                    Color(0xFF6240C4),
                  ],
                ),
                borderRadius: BorderRadius.circular(29),
                boxShadow: [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.23),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -12,
                    top: 0,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 105,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'YOUR DAILY MOMENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Grow closer\nto God 💜',
                        style: TextStyle(
                          fontSize: 27,
                          height: 1.15,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Take a peaceful moment to pray and learn.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => _goToTab(
                          context,
                          2,
                          'Choose Pray below to begin your prayer journey.',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: deepPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start praying',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 9),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 27),

            // CHILDREN SECTION
            Row(
              children: [
                const Expanded(
                  child: SectionTitle(title: 'Your children'),
                ),
                TextButton.icon(
                  onPressed: currentUser == null
                      ? null
                      : () => _showAddChildDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Add child'),
                  style: TextButton.styleFrom(
                    foregroundColor: purple,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            const Text(
              'Manage their accounts and follow their faith journey.',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            if (currentUser == null)
              const SoftCard(
                child: Text(
                  'Sign in to manage your children.',
                  style: TextStyle(color: muted),
                ),
              )
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('kids')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SoftCard(
                      child: Text(
                        'Could not load your children: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SoftCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: CircularProgressIndicator(
                            color: purple,
                          ),
                        ),
                      ),
                    );
                  }

                  final children = snapshot.data?.docs ?? [];

                  if (children.isEmpty) {
                    return SoftCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            height: 65,
                            width: 65,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1CF),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.family_restroom_rounded,
                              color: Color(0xFFB77916),
                              size: 35,
                            ),
                          ),
                          const SizedBox(height: 13),
                          const Text(
                            'No children registered yet',
                            style: TextStyle(
                              color: ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Create a child account to give them their own username, password and prayer journey.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 15),
                          FilledButton.icon(
                            onPressed: () => _showAddChildDialog(context),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
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
                    children: children.map((document) {
                      final child = document.data();
                      final name = child['name'] as String? ?? 'Child';
                      final username =
                          child['username'] as String? ?? '';
                      final childUid =
                          child['childUid'] as String? ?? document.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _ChildAccountCard(
                          name: name,
                          username: username,
                          childUid: childUid,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

            const SizedBox(height: 27),

            const SectionTitle(title: 'Explore your faith'),

            const SizedBox(height: 13),

            _ExploreCard(
              icon: Icons.auto_stories_rounded,
              title: 'Learn a prayer',
              subtitle: 'Discover beautiful Catholic prayers',
              color: lavender,
              onTap: () => _goToTab(
                context,
                1,
                'Choose Learn in the bottom navigation to explore prayers.',
              ),
            ),

            const SizedBox(height: 11),

            _ExploreCard(
              icon: Icons.favorite_rounded,
              title: 'Pray the Rosary',
              subtitle: 'Explore the mysteries of the Rosary',
              color: const Color(0xFFFFE8EF),
              iconColor: const Color(0xFFD65383),
              onTap: () => _goToTab(
                context,
                2,
                'Choose Pray in the bottom navigation to explore mysteries.',
              ),
            ),

            const SizedBox(height: 23),

            // ROSARY DEVICE
            SoftCard(
              child: Row(
                children: [
                  const IconTile(
                    icon: Icons.bluetooth_rounded,
                    background: Color(0xFFE2EEFF),
                    color: Color(0xFF4779D5),
                    size: 52,
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Rosary device',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: ink,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Connect your Smart Rosary device',
                          style: TextStyle(
                            fontSize: 11,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3DC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Not connected',
                      style: TextStyle(
                        color: Color(0xFFB47A22),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // DAILY ENCOURAGEMENT
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: purple,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A moment with God',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          '"Pray without ceasing."',
                          style: TextStyle(
                            color: deepPurple,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '1 Thessalonians 5:17',
                          style: TextStyle(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildAccountCard extends StatelessWidget {
  final String name;
  final String username;
  final String childUid;

  const _ChildAccountCard({
    required this.name,
    required this.username,
    required this.childUid,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 53,
            width: 53,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7A8),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.child_care_rounded,
              color: Color(0xFFB77916),
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
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
                const SizedBox(height: 5),
                Text(
                  username.isEmpty ? 'Child account' : '@$username',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF278443),
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Account registered',
                      style: TextStyle(
                        color: Color(0xFF278443),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF278443),
            size: 21,
          ),
        ],
      ),
    );
  }
}

class _AddChildDialog extends StatefulWidget {
  const _AddChildDialog();

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _creating = false;

  static const String _loginDomain = 'smartrosary.app';
  static const String _secondaryAppName = 'smartRosaryChildRegistration';

  String _usernameEmail(String username) {
    return '${username.toLowerCase()}@$_loginDomain';
  }

  Future<FirebaseAuth> _getSecondaryAuth() async {
    FirebaseApp secondaryApp;

    try {
      secondaryApp = Firebase.app(_secondaryAppName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: _secondaryAppName,
        options: Firebase.app().options,
      );
    }

    return FirebaseAuth.instanceFor(app: secondaryApp);
  }

  Future<void> _createChild() async {
    if (!_formKey.currentState!.validate()) return;

    final parent = FirebaseAuth.instance.currentUser;
    if (parent == null) return;

    setState(() => _creating = true);

    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text;

    FirebaseAuth? secondaryAuth;
    User? createdUser;

    try {
      secondaryAuth = await _getSecondaryAuth();

      final credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: _usernameEmail(username),
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('Firebase did not return the new child account.');
      }

      await createdUser.updateDisplayName(name);

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final parentChildRef = firestore
          .collection('users')
          .doc(parent.uid)
          .collection('kids')
          .doc(createdUser.uid);

      final childUserRef =
          firestore.collection('users').doc(createdUser.uid);

      batch.set(parentChildRef, {
        'name': name,
        'username': username,
        'childUid': createdUser.uid,
        'parentUid': parent.uid,
        'accountType': 'parentManaged',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });


batch.set(childUserRef, {
  'uid': createdUser.uid,
  'name': name,
  'username': username,
  'email': _usernameEmail(username),
  'role': 'child',
  'accountType': 'parentManagedChild',
  'parentUid': parent.uid,
  'childProfileId': createdUser.uid,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});


      await batch.commit();
      await secondaryAuth.signOut();

      if (!mounted) return;

      Navigator.pop(context);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.celebration_rounded,
                color: Color(0xFF278443),
              ),
              SizedBox(width: 9),
              Expanded(child: Text('Child account created')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$name can now sign in using these details.'),
              const SizedBox(height: 18),
              _CredentialRow(
                label: 'Username',
                value: username,
              ),
              const SizedBox(height: 10),
              _CredentialRow(
                label: 'Password',
                value: password,
              ),
              const SizedBox(height: 15),
              const Text(
                'Keep these login details safe. The password is not stored in the parent profile.',
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
              style: FilledButton.styleFrom(
                backgroundColor: purple,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() => _creating = false);

      String message;

      switch (error.code) {
        case 'email-already-in-use':
          message = 'That username is already taken. Choose another one.';
          break;
        case 'weak-password':
          message = 'Choose a stronger password.';
          break;
        case 'invalid-email':
          message = 'That username could not be used. Try another one.';
          break;
        case 'operation-not-allowed':
          message = 'Enable Email/Password sign-in in Firebase Authentication.';
          break;
        default:
          message = error.message ?? 'Could not create the child account.';
      }

      _showError(message);
    } catch (error) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() => _creating = false);
      _showError('Could not register child: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Register a child',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create a personal Smart Rosary login for your child.',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Child full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Enter the child’s name.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 13),

              TextFormField(
                controller: _usernameController,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Create username',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                  border: OutlineInputBorder(),
                  helperText: 'Use letters, numbers, dots or underscores.',
                ),
                validator: (value) {
                  final username = value?.trim() ?? '';

                  if (username.length < 3) {
                    return 'Username must contain at least 3 characters.';
                  }

                  if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
                    return 'Use only letters, numbers, dots and underscores.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 13),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Create password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must contain at least 6 characters.';
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
          onPressed: _creating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _creating ? null : _createChild,
          icon: _creating
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.person_add_alt_1_rounded),
          label: Text(_creating ? 'Creating...' : 'Create account'),
          style: FilledButton.styleFrom(
            backgroundColor: purple,
          ),
        ),
      ],
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;

  const _CredentialRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: lavender.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            value,
            style: const TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  final Color tint;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.tint,
  }) : iconColor = purple;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            icon: icon,
            background: tint,
            color: iconColor,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            number,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.iconColor = purple,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            IconTile(
              icon: icon,
              background: color,
              color: iconColor,
              size: 52,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: muted,
            ),
          ],
        ),
      ),
    );
  }
}
