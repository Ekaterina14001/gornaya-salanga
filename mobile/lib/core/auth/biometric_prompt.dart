import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'biometric_service.dart';

Future<void> maybeOfferBiometricLogin(
  BuildContext context, {
  String? email,
  String? password,
}) async {
  if (!await BiometricService().canUse()) return;
  if (!context.mounted) return;

  final bloc = context.read<AuthBloc>();
  if (await bloc.isBiometricAlreadyEnabled()) return;

  var offerEmail = email?.trim() ?? '';
  var offerPassword = password ?? '';
  if (offerEmail.isEmpty || offerPassword.isEmpty) {
    final pending = bloc.takePendingBiometricOffer();
    if (pending == null) return;
    offerEmail = pending.email;
    offerPassword = pending.password;
  } else {
    bloc.takePendingBiometricOffer();
  }
  if (!context.mounted) return;

  final confirmed = await BiometricService().authenticate(
    reason: 'Подтвердите Face ID, чтобы привязать вход',
  );
  if (!context.mounted) return;
  if (!confirmed) {
    final detail = BiometricService().lastError();
    final suffix = detail.isEmpty || detail == 'cancelled' ? '' : ' ($detail)';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось включить Face ID$suffix')),
    );
    return;
  }

  context.read<AuthBloc>().add(
        AuthBiometricEnabled(email: offerEmail, password: offerPassword),
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Вход по Face ID включён')),
    );
  }
}
