import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_link.dart';
import '../../l10n/app_localizations.dart';
import 'book_room_button.dart';
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, labelKey: 'home'),
    _NavItem(icon: Icons.card_giftcard_outlined, selectedIcon: Icons.card_giftcard, labelKey: 'bonus'),
    _NavItem(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, labelKey: 'catalog'),
    _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, labelKey: 'profile'),
  ];

  String _label(AppLocalizations l10n, String key) {
    return switch (key) {
      'home' => l10n.home,
      'bonus' => l10n.bonus,
      'catalog' => l10n.catalog,
      'profile' => l10n.profile,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => openAppLink(context, kSalangaBookingUrl),
              icon: const Icon(Icons.hotel_outlined),
              label: Text(l10n.bookRoom),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: _label(l10n, item.labelKey),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
}
