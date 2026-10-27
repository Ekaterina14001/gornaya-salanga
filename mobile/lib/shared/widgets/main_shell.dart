import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_link.dart';
import '../../core/theme/salanga_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../features/catalog/catalog_hub_controller.dart';
import '../../features/home/presentation/widgets/home_banners_section.dart';
import 'book_room_button.dart';
import 'salanga_asset_icon.dart';
import 'salanga_bottom_nav_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Порядок: главная, бонусы, QR (центр), каталог, профиль.
  static const _kQrNavIndex = 2;
  static const _kCatalogShellIndex = 2;
  static const _kCatalogNavIndex = 3;

  static const _destinations = [
    _NavItem(
      asset: SalangaAssets.home,
      activeAsset: SalangaAssets.home,
      labelKey: 'home',
    ),
    _NavItem(
      asset: SalangaAssets.bonus,
      activeAsset: SalangaAssets.bonusActive,
      labelKey: 'bonus',
    ),
    _NavItem(
      asset: SalangaAssets.qr,
      activeAsset: SalangaAssets.qr,
      labelKey: 'qr',
    ),
    _NavItem(
      asset: SalangaAssets.catalog,
      activeAsset: SalangaAssets.catalog,
      labelKey: 'catalog',
    ),
    _NavItem(
      asset: SalangaAssets.profile,
      activeAsset: SalangaAssets.profile,
      labelKey: 'profile',
    ),
  ];

  static int _shellToNavIndex(int shellIndex) =>
      shellIndex < _kQrNavIndex ? shellIndex : shellIndex + 1;

  static int? _navToShellIndex(int navIndex) {
    if (navIndex == _kQrNavIndex) return null;
    return navIndex < _kQrNavIndex ? navIndex : navIndex - 1;
  }

  String _label(AppLocalizations l10n, String key) {
    return switch (key) {
      'home' => l10n.home,
      'bonus' => l10n.bonus,
      'qr' => l10n.qrCode,
      'catalog' => l10n.catalog,
      'profile' => l10n.profile,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: SalangaColors.pageBackground,
      body: navigationShell,
      floatingActionButton: navigationShell.currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => openAppLink(context, kSalangaBookingUrl),
              backgroundColor: SalangaColors.burgundy,
              elevation: 2,
              shape: const CircleBorder(),
              child: Image.asset(
                SalangaAssets.bookRoom,
                width: 28,
                height: 28,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SalangaBottomNavBar(
        currentIndex: _shellToNavIndex(navigationShell.currentIndex),
        onTap: (navIndex) {
          if (navIndex == _kQrNavIndex) {
            context.push('/qr');
            return;
          }
          if (navIndex == _kCatalogNavIndex) {
            navigationShell.goBranch(_kCatalogShellIndex);
            CatalogHubController.instance.showMenu();
            return;
          }
          final shellIndex = _navToShellIndex(navIndex)!;
          navigationShell.goBranch(shellIndex);
          if (shellIndex == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              HomeBannersSection.refreshActive(forceRefresh: true);
            });
          }
        },
        items: [
          for (final item in _destinations)
            SalangaNavBarItem(
              iconAsset: item.asset,
              activeIconAsset: item.activeAsset,
              label: _label(l10n, item.labelKey),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.asset,
    required this.activeAsset,
    required this.labelKey,
  });

  final String asset;
  final String activeAsset;
  final String labelKey;
}
