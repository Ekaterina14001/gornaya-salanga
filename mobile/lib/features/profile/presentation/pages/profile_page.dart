import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/auth/biometric_prompt.dart';
import '../../../../core/auth/biometric_service.dart';
import '../../../../core/theme/salanga_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/install_app_banner.dart';
import '../../../../shared/widgets/salanga_asset_icon.dart';
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

  void _toggleEditing() {
    setState(() {
      if (_editing && _profile != null) {
        _fillForm(_profile!);
      }
      _editing = !_editing;
      _success = null;
    });
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
      backgroundColor: SalangaColors.pageBackground,
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: GoogleFonts.ptSerif(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: SalangaColors.pageBackground,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonLoader(height: 120),
              )
            else if (_error != null && _profile == null)
              ErrorPlaceholder(message: _error, onRetry: _load)
            else ...[
              Align(
                alignment: Alignment.topLeft,
                child: Opacity(
                  opacity: 0.28,
                  child: SalangaAssetIcon(asset: SalangaAssets.branch, size: 72, tint: false),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Opacity(
                  opacity: 0.28,
                  child: Transform.flip(
                    flipX: true,
                    child: SalangaAssetIcon(asset: SalangaAssets.branch, size: 72, tint: false),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -48),
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: SalangaColors.warmBrown,
                              child: Text(
                                initial,
                                style: GoogleFonts.ptSerif(
                                  fontSize: 44,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Material(
                              color: SalangaColors.surface,
                              shape: const CircleBorder(),
                              elevation: 1,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _saving ? null : _toggleEditing,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    _editing ? Icons.close : Icons.edit_outlined,
                                    size: 20,
                                    color: SalangaColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: SalangaColors.cream,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: SalangaColors.sand),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                            child: Column(
                              children: [
                                if (_success != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(_success!, style: const TextStyle(color: Colors.green)),
                                  ),
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      _error!,
                                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                                    ),
                                  ),
                                if (!_editing) ...[
                                  Text(
                                    '$firstName $lastName'.trim(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.ptSerif(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: SalangaColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    email,
                                    style: GoogleFonts.openSans(
                                      color: SalangaColors.warmBrown,
                                      fontSize: 14,
                                    ),
                                  ),
                                ] else ...[
                                  TextField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Имя',
                                      filled: true,
                                      fillColor: SalangaColors.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Фамилия',
                                      filled: true,
                                      fillColor: SalangaColors.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      filled: true,
                                      fillColor: SalangaColors.surface,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _saving ? null : _save,
                                      child: _saving
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Сохранить'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFE8DDD0),
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                            child: Column(
                              children: [
                                _ProfileRow(
                                  icon: Icons.phone_outlined,
                                  title: phone,
                                  verified: phoneVerified,
                                ),
                                const Divider(height: 1, color: SalangaColors.sand),
                                _ProfileRow(
                                  icon: Icons.mail_outline,
                                  title: email,
                                  verified: emailVerified,
                                ),
                                if (_biometricAvailable || kIsWeb) ...[
                                  const Divider(height: 1, color: SalangaColors.sand),
                                  SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    secondary: const Icon(
                                      Icons.face_retouching_natural_outlined,
                                      color: SalangaColors.textDark,
                                    ),
                                    title: const Text('Face ID'),
                                    subtitle: Text(
                                      _biometricEnabled
                                          ? 'Можно входить без пароля'
                                          : 'Включите для быстрого входа',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    activeTrackColor: SalangaColors.warmBrown.withValues(alpha: 0.45),
                                    activeThumbColor: SalangaColors.textDark,
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
                                ],
                                if (showInstallAppMenuItem)
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    leading: const Icon(Icons.install_mobile_outlined,
                                        color: SalangaColors.textDark),
                                    title: Text(l10n.installAppTitle),
                                    subtitle: Text(l10n.installAppHint),
                                    onTap: () => showInstallAppDialog(context),
                                  ),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  leading: SalangaAssetIcon(
                                    asset: SalangaAssets.qr,
                                    size: 24,
                                    color: SalangaColors.textDark,
                                  ),
                                  title: Text(l10n.qrCode),
                                  onTap: () => context.push('/qr'),
                                ),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  leading: const Icon(Icons.info_outline, color: SalangaColors.textDark),
                                  title: const Text('О приложении'),
                                  subtitle: const Text('Горная Саланга v1.0'),
                                ),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  leading: const Icon(Icons.logout, color: SalangaColors.textDark),
                                  title: Text(l10n.logout),
                                  onTap: () {
                                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                                    context.go('/login');
                                  },
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
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.verified,
  });

  final IconData icon;
  final String title;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: SalangaColors.textDark),
      title: Text(title),
      trailing: verified
          ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
          : Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 22),
    );
  }
}
