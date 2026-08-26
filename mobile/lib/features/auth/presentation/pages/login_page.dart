import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/book_room_button.dart';
import '../../../../shared/widgets/install_app_banner.dart';
import '../../../../shared/widgets/salanga_brand_header.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status && curr.status == AuthStatus.authenticated,
        listener: (context, state) => context.go('/home'),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SalangaBrandHeader(),
                      const SizedBox(height: 16),
                      const InstallAppBanner(compact: true),
                      const SizedBox(height: 16),
                      Text(
                        l10n.login,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: l10n.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Введите email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: l10n.password),
                        obscureText: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Введите пароль' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            final email = _emailController.text.trim();
                            final query = email.isNotEmpty
                                ? '?email=${Uri.encodeComponent(email)}'
                                : '';
                            context.push('/forgot-password$query');
                          },
                          child: const Text('Забыли пароль?'),
                        ),
                      ),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state.errorMessage != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                state.errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return FilledButton(
                            onPressed: state.isLoading ? null : _submit,
                            child: state.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.loginButton),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const BookRoomButton(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text('${l10n.noAccount} ${l10n.register}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
