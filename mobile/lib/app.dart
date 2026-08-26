import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/push/push_lifecycle.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'l10n/app_localizations.dart';

class GornayaSalangaApp extends StatelessWidget {
  GornayaSalangaApp({super.key});

  final _authBloc = AuthBloc()..add(const AuthCheckRequested());

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: PushLifecycle(
        child: MaterialApp.router(
          title: 'Горная Саланга',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: AppRouter.router(_authBloc),
        ),
      ),
    );
  }
}
