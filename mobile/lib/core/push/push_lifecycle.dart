import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'push_service.dart';

/// Регистрирует FCM-токен после входа пользователя.
class PushLifecycle extends StatefulWidget {
  const PushLifecycle({required this.child, super.key});

  final Widget child;

  @override
  State<PushLifecycle> createState() => _PushLifecycleState();
}

class _PushLifecycleState extends State<PushLifecycle> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated && PushService.instance.isAvailable) {
          PushService.instance.registerDeviceToken();
        }
      },
      child: widget.child,
    );
  }
}
