import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/biometric_prompt.dart';
import '../../../../core/theme/salanga_colors.dart';

import '../../../home/data/bonus_repository.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/home_menu_card.dart';
import '../../../../shared/widgets/salanga_asset_icon.dart';
import '../../../../shared/widgets/salanga_network_icon.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../widgets/home_banners_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _bonusRepository = BonusRepository();
  final _profileRepository = ProfileRepository();
  final _notificationsRepository = NotificationsRepository();
  int? _balance;
  String _firstName = '';
  String? _avatarUrl;
  String? _error;
  bool _loading = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeOfferBiometricLogin(context);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await HomeBannersSection.refreshActive(forceRefresh: true);
      final balanceFuture = _bonusRepository.fetchBalance();
      final profileFuture = _profileRepository.fetchProfile();
      final unreadFuture = _notificationsRepository.unreadCount();
      final balance = await balanceFuture;
      final profile = await profileFuture;
      var unread = 0;
      try {
        unread = await unreadFuture;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _firstName = profile['firstName'] as String? ?? '';
        _avatarUrl = profile['avatarUrl'] as String?;
        _unreadNotifications = unread;
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

  void _openBonusTab(BuildContext context) {
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) {
      shell.goBranch(1, initialLocation: shell.currentIndex != 1);
    } else {
      context.go('/bonus');
    }
  }

  void _openProfileTab(BuildContext context) {
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) {
      shell.goBranch(3, initialLocation: shell.currentIndex != 3);
    } else {
      context.go('/profile');
    }
  }

  String _displayName(AppLocalizations l10n) {
    final raw = _firstName.trim();
    if (raw.isEmpty) return l10n.guestName;
    if (raw.length == 1) return raw.toUpperCase();
    return '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: SalangaColors.pageBackground,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          children: [
            _HomeUserHeader(
              displayName: _displayName(l10n),
              avatarUrl: _avatarUrl,
              balance: _balance,
              loading: _loading,
              onBonusTap: () => _openBonusTab(context),
              onNameTap: () => _openProfileTab(context),
            ),
            const SizedBox(height: 16),
            const HomeBannersSection(),
            const SizedBox(height: 16),
            HomeMenuCard(
              children: [
                HomeMenuTile(
                  iconAsset: SalangaAssets.weather,
                  title: l10n.weather,
                  onTap: () => context.push('/weather'),
                ),
                HomeMenuTile(
                  iconAsset: SalangaAssets.trails,
                  title: l10n.trails,
                  onTap: () => context.push('/trails'),
                ),
                HomeMenuTile(
                  iconAsset: SalangaAssets.webcams,
                  title: l10n.webcams,
                  onTap: () => context.push('/webcams'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorPlaceholder(message: _error, onRetry: _load),
            ],
            const SizedBox(height: 12),
            HomeMenuCard(
              children: [
                HomeMenuTile(
                  iconAsset: SalangaAssets.notifications,
                  title: l10n.notifications,
                  badgeCount: _unreadNotifications,
                  onTap: () async {
                    await context.push('/notifications');
                    if (!mounted) return;
                    try {
                      final unread = await _notificationsRepository.unreadCount();
                      if (mounted) setState(() => _unreadNotifications = unread);
                    } catch (_) {}
                  },
                ),
                HomeMenuTile(
                  iconAsset: SalangaAssets.contact,
                  title: l10n.contact,
                  onTap: () => context.push('/contact'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeUserHeader extends StatelessWidget {
  const _HomeUserHeader({
    required this.displayName,
    required this.avatarUrl,
    required this.balance,
    required this.loading,
    this.onBonusTap,
    this.onNameTap,
  });

  static const frameHeight = 77.0;
  static const frameMaxWidth = 550.0;
  static const nameFontSize = 28.0;
  static const bonusFontSize = 35.0;

  final String displayName;
  final String? avatarUrl;
  final int? balance;
  final bool loading;
  final VoidCallback? onBonusTap;
  final VoidCallback? onNameTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Row(
        children: [
          const SkeletonLoader(height: 56, width: 56, borderRadius: 28),
          const SizedBox(width: 10),
          Expanded(
            child: SkeletonLoader(height: frameHeight, width: frameMaxWidth, borderRadius: 38),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SalangaNetworkIcon(size: 56, imageUrl: avatarUrl),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: frameMaxWidth, minHeight: frameHeight),
              child: SizedBox(
                height: frameHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: SalangaColors.cream,
                    borderRadius: BorderRadius.circular(frameHeight / 2),
                    border: Border.all(color: SalangaColors.sand),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HomeNameSection(
                          displayName: displayName,
                          onTap: onNameTap,
                        ),
                      ),
                      _BonusPointsPlaque(
                        balance: balance,
                        onTap: onBonusTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeNameSection extends StatelessWidget {
  const _HomeNameSection({required this.displayName, this.onTap});

  final String displayName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nameStyle = GoogleFonts.openSans(
      fontSize: _HomeUserHeader.nameFontSize,
      height: 1.05,
      fontWeight: FontWeight.w700,
      color: SalangaColors.menuText,
      letterSpacing: 0.2,
    );

    final text = Text(
      displayName.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: nameStyle,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: onTap == null
            ? text
            : Semantics(
                button: true,
                label: 'Личный кабинет, $displayName',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: text,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _BonusPointsPlaque extends StatelessWidget {
  const _BonusPointsPlaque({required this.balance, this.onTap});

  final int? balance;
  final VoidCallback? onTap;

  static double widthForBalance(int? balance) {
    if (balance == null) return 130;
    final digits = balance.abs().toString().length;
    if (digits <= 1) return 130;
    if (digits >= 4) return 190;
    return 130 + (digits - 1) * 20;
  }

  @override
  Widget build(BuildContext context) {
    final formatted = balance != null
        ? NumberFormat.decimalPattern('ru').format(balance)
        : '—';

    final plaque = Container(
      width: widthForBalance(balance),
      height: _HomeUserHeader.frameHeight,
      decoration: BoxDecoration(
        color: SalangaColors.bonusPlaqueBg,
        borderRadius: BorderRadius.horizontal(
          left: Radius.zero,
          right: Radius.circular(_HomeUserHeader.frameHeight / 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            SalangaAssets.bonus,
            width: 26,
            height: 26,
            color: SalangaColors.bonusPlaqueInk,
            colorBlendMode: BlendMode.srcIn,
          ),
          const SizedBox(width: 6),
          Text(
            formatted,
            style: GoogleFonts.openSans(
              fontSize: _HomeUserHeader.bonusFontSize,
              height: 1,
              fontWeight: FontWeight.w700,
              color: SalangaColors.bonusPlaqueInk,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return plaque;

    return Semantics(
      button: true,
      label: 'Бонусы, $formatted баллов',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(_HomeUserHeader.frameHeight / 2),
          ),
          child: plaque,
        ),
      ),
    );
  }
}
