import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../claim_management/screens/firestore_claims_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.user, required this.token});

  final User user;
  final Future<IdTokenResult> token;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _service = AuthService();
  late final _profile = _service.profile(widget.user.uid);
  late var _profileStream = _profile.snapshots(includeMetadataChanges: true);
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await _service.logoutUser();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to log out. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult>(
      future: widget.token,
      builder: (context, session) {
        final role = session.connectionState == ConnectionState.done
            ? (session.data?.claims?['role'])
            : null;
        final isStaff = role == 'Admin' || role == 'OperationsStaff';

        return Navigator(
          key: ValueKey(isStaff),
          onDidRemovePage: (_) {},
          pages: [
            MaterialPage<void>(
              child: _AccountHome(
                user: widget.user,
                profile: _profile,
                profileStream: _profileStream,
                role: isStaff ? role as String : 'Policyholder',
                onOpenClaims: isStaff
                    ? (context) => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => FirestoreClaimsScreen(
                            firestore: _profile.firestore,
                          ),
                        ),
                      )
                    : null,
                onRetry: () => setState(
                  () => _profileStream = _profile.snapshots(
                    includeMetadataChanges: true,
                  ),
                ),
                onSignOut: _signingOut ? null : _signOut,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountHome extends StatelessWidget {
  const _AccountHome({
    required this.user,
    required this.profile,
    required this.profileStream,
    required this.role,
    required this.onOpenClaims,
    required this.onRetry,
    required this.onSignOut,
  });

  final User user;
  final DocumentReference<Map<String, dynamic>> profile;
  final Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream;
  final String role;
  final void Function(BuildContext)? onOpenClaims;
  final VoidCallback onRetry;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My account'),
        actions: [
          TextButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                user.email ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(role == 'OperationsStaff' ? 'Operations staff' : role),
              const SizedBox(height: 16),
              if (onOpenClaims != null)
                OutlinedButton.icon(
                  onPressed: () => onOpenClaims!(context),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Claim Management'),
                ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: profileStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unable to load your profile.'),
                        TextButton(
                          onPressed: onRetry,
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }
                  if (!snapshot.hasData ||
                      (!snapshot.data!.exists &&
                          snapshot.data!.metadata.isFromCache)) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _ProfileForm(
                    profile: profile,
                    initialData: snapshot.data!.data(),
                    email: user.email,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({
    required this.profile,
    required this.initialData,
    required this.email,
  });

  final DocumentReference<Map<String, dynamic>> profile;
  final Map<String, dynamic>? initialData;
  final String? email;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.initialData?['fullName'] as String?,
  );
  late final _phone = TextEditingController(
    text: widget.initialData?['phoneNumber'] as String?,
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    var message = 'Profile saved.';
    try {
      final changes = {
        'fullName': _name.text.trim(),
        'phoneNumber': _phone.text.trim(),
      };
      await widget.profile.firestore.runTransaction((transaction) async {
        final current = await transaction.get(widget.profile);
        if (current.exists) {
          transaction.update(widget.profile, changes);
        } else {
          transaction.set(widget.profile, {
            ...changes,
            'email': widget.email,
            'role': 'Policyholder',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (_) {
      message = 'Unable to save your profile. Please try again.';
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            enabled: !_saving,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) =>
                (value ?? '').trim().length < 2 ? 'Enter your full name' : null,
          ),
          TextFormField(
            controller: _phone,
            enabled: !_saving,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
            validator: (value) =>
                RegExp(r'^\+?[0-9]{9,15}$')
                    .hasMatch((value ?? '').replaceAll(RegExp(r'[\s-]'), ''))
                ? null
                : 'Enter a valid phone number',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save profile'),
          ),
        ],
      ),
    );
  }
}
