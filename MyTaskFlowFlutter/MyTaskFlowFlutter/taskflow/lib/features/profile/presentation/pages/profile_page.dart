import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/core/providers/theme_provider.dart';
import 'package:taskflow/features/auth/data/providers/auth_providers.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_state.dart';
import 'package:taskflow/features/profile/data/providers/profile_providers.dart';
import 'package:taskflow/features/profile/presentation/controllers/profile_state.dart';
import 'package:taskflow/features/profile/presentation/widgets/profile_avatar.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);

    final user = authState is AuthAuthenticated ? authState.user : null;

    if (!_initialized && user != null) {
      _nameController.text = user.displayName ?? '';
      _initialized = true;
    }

    ref.listen<ProfileState>(profileNotifierProvider, (_, next) {
      if (next is ProfileUpdated) {
        _nameController.text = next.user.displayName ?? '';
        ref.read(authNotifierProvider.notifier).updateUser(next.user);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      } else if (next is ProfileError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    final avatarLabel = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : user?.email ?? '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: ProfileAvatar(displayName: avatarLabel)),
            const SizedBox(height: 8),
            if (user != null)
              Center(
                child: Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 32),

            Text('Nombre', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('displayNameField'),
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre para mostrar',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresa tu nombre'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (profileState is ProfileLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    FilledButton(
                      key: const Key('saveProfileButton'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ref
                              .read(profileNotifierProvider.notifier)
                              .updateDisplayName(_nameController.text.trim());
                        }
                      },
                      child: const Text('Guardar cambios'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            Text('Apariencia', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              key: const Key('themeModeButton'),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Oscuro'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selection.first);
              },
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              key: const Key('signOutButton'),
              onPressed: () {
                ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
