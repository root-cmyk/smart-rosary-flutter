
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _registering = false;
  bool _loading = false;
  bool _hidePassword = true;

  String _role = 'parent';

  static const purple = Color(0xFF7654D6);
  static const ink = Color(0xFF292343);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _normalizeUsername(String value) {
    return value.trim().toLowerCase().replaceAll('@smartrosary.app', '');
  }

  bool _isValidUsername(String value) {
    return value.length >= 3 &&
        RegExp(r'^[a-z0-9._]+$').hasMatch(value);
  }

  String _getLoginEmail(String value) {
    final input = value.trim().toLowerCase();

    if (input.contains('@')) {
      return input;
    }

    return '${_normalizeUsername(input)}@smartrosary.app';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final input = _email.text.trim();
      final password = _password.text;

      final loginEmail = _getLoginEmail(input);

      if (_registering) {
        final name = _name.text.trim();

        final credential = await auth.createUserWithEmailAndPassword(
          email: loginEmail,
          password: password,
        );

        final user = credential.user!;

        final profileData = <String, dynamic>{
          'uid': user.uid,
          'name': name,
          'email': loginEmail,
          'role': _role,
          'accountType': _role == 'parent'
              ? 'parent'
              : 'independentChild',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_role == 'child') {
          profileData['username'] = _normalizeUsername(input);
        }

        await firestore
            .collection('users')
            .doc(user.uid)
            .set(profileData);

        await user.updateDisplayName(name);
      } else {
        await auth.signInWithEmailAndPassword(
          email: loginEmail,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      _message(switch (e.code) {
        'invalid-email' =>
          'Enter a valid email address or username.',
        'user-not-found' =>
          'No account found. Check your email or username.',
        'wrong-password' || 'invalid-credential' =>
          'Email/username or password is incorrect.',
        'email-already-in-use' =>
          'That email or username already has an account.',
        'weak-password' =>
          'Use a stronger password (at least 6 characters).',
        'too-many-requests' =>
          'Too many attempts. Try again later.',
        'network-request-failed' =>
          'Check your internet connection.',
        'operation-not-allowed' =>
          'Email/password authentication is not enabled in Firebase.',
        _ => e.message ?? 'Authentication failed. Please try again.',
      });
    } catch (e) {
      _message(
        'Could not complete the request. Check your connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final input = _email.text.trim();

    if (input.isEmpty || !input.contains('@')) {
      _message(
        'Enter the real email address associated with your account.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: input.toLowerCase(),
      );

      _message(
        'If an account exists for that email, a reset email will be sent.',
      );
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? 'Could not send the reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChildRegistration = _registering && _role == 'child';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 88,
                      width: 88,
                      alignment: Alignment.center,
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
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 43,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'SMART ROSARY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: purple,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _registering
                          ? 'Create your account'
                          : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _registering
                          ? 'Begin your journey to learn, pray and grow.'
                          : 'Continue your journey of prayer and faith.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF77718A),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (_registering) ...[
                      const Text(
                        'Your name',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),

                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration(
                          'Enter your name',
                          Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Enter a valid name.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      const Text(
                        'I am registering as',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _roleOption(
                              'parent',
                              'Parent / Adult',
                              Icons.family_restroom_rounded,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _roleOption(
                              'child',
                              'Child',
                              Icons.child_care_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 17),
                    ],

                    Text(
                      isChildRegistration
                          ? 'Choose a username'
                          : _registering
                              ? 'Email address'
                              : 'Email or username',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _email,
                      keyboardType: isChildRegistration
                          ? TextInputType.text
                          : TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: isChildRegistration
                          ? const [AutofillHints.username]
                          : const [AutofillHints.email],
                      decoration: _decoration(
                        isChildRegistration
                            ? 'e.g. brian_kid'
                            : _registering
                                ? 'you@example.com'
                                : 'Email address or username',
                        isChildRegistration
                            ? Icons.person_outline_rounded
                            : Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return isChildRegistration
                              ? 'Choose a username.'
                              : 'Enter your email or username.';
                        }

                        if (isChildRegistration) {
                          final username = _normalizeUsername(value);

                          if (!_isValidUsername(username)) {
                            return 'Use 3+ letters, numbers, dots or underscores.';
                          }

                          return null;
                        }

                        if (_registering) {
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value.trim())) {
                            return 'Enter a valid email address.';
                          }
                        } else if (!value.contains('@')) {
                          final username = _normalizeUsername(value);

                          if (!_isValidUsername(username)) {
                            return 'Enter a valid username.';
                          }
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 17),

                    const Text(
                      'Password',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: _registering
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: _decoration(
                        'Enter your password',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    if (!_registering)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 23,
                                width: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _registering
                                    ? 'Create account'
                                    : 'Sign in',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _registering
                                ? 'Already have an account?'
                                : "Don't have an account?",
                            style: const TextStyle(
                              color: Color(0xFF77718A),
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _registering = !_registering;
                                    _role = 'parent';
                                    _formKey.currentState?.reset();
                                  });
                                },
                          child: Text(
                            _registering ? 'Sign in' : 'Register',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: purple,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (!_registering) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Children can sign in using the username and password '
                        'provided by their parent.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF77718A),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF8B7BB8),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE7E0F5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE7E0F5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: purple,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _roleOption(
    String value,
    String title,
    IconData icon,
  ) {
    final selected = _role == value;

    return InkWell(
      onTap: () {
        setState(() {
          _role = value;
        });
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEDE6FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? purple
                : const Color(0xFFE7E0F5),
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? purple
                  : const Color(0xFF8B7BB8),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? purple : ink,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
