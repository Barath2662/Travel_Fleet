import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'employee';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appStateProvider.notifier).fetchUsers());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _password.text.trim().isEmpty) {
      _show('Name, email, and password are required');
      return;
    }

    await ref.read(appStateProvider.notifier).createUser({
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'role': _role,
    });

    _name.clear();
    _email.clear();
    _password.clear();
    setState(() => _role = 'employee');
    _show('User added');
  }

  Future<void> _deleteUser(String id) async {
    await ref.read(appStateProvider.notifier).deleteUser(id);
    _show('User deleted');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).role;
    final state = ref.watch(appStateProvider);

    if (role != 'owner') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Only owner can manage users from this menu.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add User', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                    DropdownMenuItem(value: 'employee', child: Text('Employee')),
                    DropdownMenuItem(value: 'driver', child: Text('Driver')),
                  ],
                  onChanged: (value) => setState(() => _role = value ?? 'employee'),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _createUser, child: const Text('Create User')),
                if (state.loading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('All Users', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...state.users.map(
          (user) => Card(
            child: ListTile(
              title: Text(user.name),
              subtitle: Text('${user.email}\nRole: ${user.role}'),
              isThreeLine: true,
              trailing: user.id == ref.watch(authProvider).userId
                  ? const Chip(label: Text('You'))
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteUser(user.id),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
