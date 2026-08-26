import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _authRepository = AuthRepository();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authRepository.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _openResetPassword() {
    final email = _emailController.text.trim();
    final query = email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : '';
    context.push('/reset-password$query');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: const Text('Восстановление пароля')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_sent) ...[
                const Text(
                  'Мы отправили 6-значный код на ваш email. Введите его на следующем экране.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Проверьте папку «Спам», если письма нет во входящих.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _openResetPassword,
                  child: const Text('Ввести код'),
                ),
              ] else ...[
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: l10n.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Введите email' : null,
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
                      : const Text('Отправить'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
