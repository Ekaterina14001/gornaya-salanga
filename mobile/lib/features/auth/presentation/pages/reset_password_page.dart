import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/auth_repository.dart';
import '../bloc/auth_bloc.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = widget.initialEmail.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email не указан. Вернитесь на экран восстановления пароля.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final newPassword = _passwordController.text;
      await _authRepository.resetPassword(
        token: _tokenController.text.trim(),
        newPassword: newPassword,
      );
      if (!mounted) return;

      context.read<AuthBloc>().add(
            AuthLoginRequested(email: email, password: newPassword),
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Новый пароль')),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            prev.status != AuthStatus.authenticated &&
            curr.status == AuthStatus.authenticated,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пароль обновлён')),
          );
          context.go('/home');
        },
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              _loading && !curr.isLoading && curr.status != AuthStatus.authenticated,
          listener: (context, state) {
            if (state.errorMessage != null) {
              setState(() {
                _loading = false;
                _error = state.errorMessage;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  if (widget.initialEmail.isNotEmpty) ...[
                    Text(
                      'Аккаунт: ${widget.initialEmail}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Токен сброса',
                      helperText: 'Скопируйте из лога backend после запроса восстановления',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Введите токен' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: l10n.password),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Минимум 6 символов' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить и войти'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
