import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/biometric_prompt.dart';
import '../../../../core/auth/biometric_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/install_app_banner.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repository = ProfileRepository();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String? _error;
  String? _success;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _fillForm(Map<String, dynamic> profile) {
    _firstNameController.text = profile['firstName'] as String? ?? '';
    _lastNameController.text = profile['lastName'] as String? ?? '';
    _emailController.text = profile['email'] as String? ?? '';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository.fetchProfile();
      final biometricAvailable = await BiometricService().canUse();
      var biometricEnabled = false;
      if (mounted) {
        biometricEnabled = await context.read<AuthBloc>().isBiometricAlreadyEnabled();
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _fillForm(profile);
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final updated = await _repository.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _fillForm(updated);
        _editing = false;
        _saving = false;
        _success = 'Профиль сохранён';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  Future<void> _enableBiometricWithPassword() async {
    final email = _profile?['email'] as String? ?? _emailController.text.trim();
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Привязать Face ID'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Пароль от аккаунта'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty || email.isEmpty || !mounted) {
      return;
    }
    await maybeOfferBiometricLogin(
      context,
      email: email,
      password: password,
    );
    if (!mounted) return;
    final enabled = await context.read<AuthBloc>().isBiometricAlreadyEnabled();
    setState(() => _biometricEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = _profile?['firstName'] as String? ?? l10n.guestName;
    final lastName = _profile?['lastName'] as String? ?? '';
    final phone = _profile?['phone'] as String? ?? '—';
    final email = _profile?['email'] as String? ?? '—';
    final phoneVerified = _profile?['phoneVerified'] as bool? ?? false;
    final emailVerified = _profile?['emailVerified'] as bool? ?? false;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (!_loading && _error == null && _profile != null)
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              onPressed: _saving
                  ? null
                  : () {
                      setState(() {
                        if (_editing && _profile != null) {
                          _fillForm(_profile!);
                        }
                        _editing = !_editing;
                        _success = null;
                      });
                    },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonLoader(height: 120),
              )
            else if (_error != null && _profile == null)
              ErrorPlaceholder(message: _error, onRetry: _load)
            else ...[
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_success!, style: const TextStyle(color: Colors.green)),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(initial, style: const TextStyle(color: Colors.white)),
                ),
                title: Text('$firstName $lastName'),
                subtitle: Text(email),
              ),
              const Divider(),
              if (_editing) ...[
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Фамилия',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
                const Divider(height: 32),
              ],
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(phone),
                trailing: Icon(
                  phoneVerified ? Icons.verified : Icons.warning_amber,
                  color: phoneVerified ? Colors.green : Colors.orange,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(email),
                trailing: Icon(
                  emailVerified ? Icons.verified : Icons.warning_amber,
                  color: emailVerified ? Colors.green : Colors.orange,
                ),
              ),
            ],
            const Divider(),
            if (_biometricAvailable || kIsWeb)
              SwitchListTile(
                secondary: const Icon(Icons.face_retouching_natural),
                title: const Text('Вход по Face ID / отпечатку'),
                subtitle: Text(
                  _biometricEnabled
                      ? 'Можно входить без пароля'
                      : 'Включите, чтобы входить по Face ID',
                ),
                value: _biometricEnabled,
                onChanged: (enabled) async {
                  if (!enabled) {
                    await AuthRepository().disableBiometric();
                    if (mounted) setState(() => _biometricEnabled = false);
                    return;
                  }
                  await _enableBiometricWithPassword();
                },
              ),
            if (showInstallAppMenuItem)
              ListTile(
                leading: const Icon(Icons.install_mobile),
                title: Text(l10n.installAppTitle),
                subtitle: Text(l10n.installAppHint),
                onTap: () => showInstallAppDialog(context),
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('О приложении'),
              subtitle: const Text('Горная Саланга v1.0'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.logout),
              onTap: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
