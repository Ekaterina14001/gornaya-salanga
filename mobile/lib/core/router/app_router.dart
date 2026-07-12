import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_page.dart';
import '../../features/bonus/presentation/pages/bonus_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/contact/presentation/pages/contact_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/qr/presentation/pages/qr_page.dart';
import '../../features/trails/presentation/pages/trails_page.dart';
import '../../features/weather/presentation/pages/weather_page.dart';
import '../../features/webcams/presentation/pages/webcams_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../storage/hive_boxes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: HiveBoxes.isOnboardingComplete ? '/login' : '/onboarding',
      refreshListenable: _AuthRefreshListenable(authBloc),
      redirect: (context, state) {
        final authState = authBloc.state;
        final loc = state.matchedLocation;
        final isAuthRoute = loc == '/login' ||
            loc == '/register' ||
            loc == '/verify' ||
            loc == '/forgot-password' ||
            loc == '/reset-password' ||
            loc == '/onboarding';

        if (authState.status == AuthStatus.unknown) {
          return null;
        }

        if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
          return '/login';
        }

        if (authState.status == AuthStatus.authenticated &&
            (loc == '/login' ||
                loc == '/register' ||
                loc == '/verify' ||
                loc == '/forgot-password' ||
                loc == '/reset-password' ||
                loc == '/onboarding')) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => ForgotPasswordPage(
            initialEmail: state.uri.queryParameters['email'] ?? '',
          ),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => ResetPasswordPage(
            initialEmail: state.uri.queryParameters['email'] ?? '',
          ),
        ),
        GoRoute(
          path: '/verify',
          builder: (context, state) => VerifyPage(
            phone: state.uri.queryParameters['phone'] ?? '',
          ),
        ),
        GoRoute(
          path: '/qr',
          builder: (context, state) => const QrPage(),
        ),
        GoRoute(
          path: '/weather',
          builder: (context, state) => const WeatherPage(),
        ),
        GoRoute(
          path: '/trails',
          builder: (context, state) => const TrailsPage(),
        ),
        GoRoute(
          path: '/webcams',
          builder: (context, state) => const WebcamsPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/contact',
          builder: (context, state) => const ContactPage(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/bonus',
                  builder: (context, state) => const BonusPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/catalog',
                  builder: (context, state) => const CatalogPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._bloc) {
    _bloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _bloc;
}
