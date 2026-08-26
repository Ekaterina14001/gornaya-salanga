import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../home/data/bonus_repository.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/book_room_button.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../widgets/headliners_carousel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _bonusRepository = BonusRepository();
  final _profileRepository = ProfileRepository();
  int? _balance;
  String _firstName = '';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _bonusRepository.fetchBalance(),
        _profileRepository.fetchProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _balance = results[0] as int;
        final profile = results[1] as Map<String, dynamic>;
        _firstName = profile['firstName'] as String? ?? '';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final greeting = _firstName.isNotEmpty ? 'Привет, $_firstName!' : l10n.home;

    return Scaffold(
      appBar: AppBar(title: Text(greeting)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const BookRoomPromoCard(),
            const SizedBox(height: 16),
            const HeadlinersCarousel(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _loading
                    ? const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(height: 24, width: 120),
                          SizedBox(height: 12),
                          SkeletonLoader(height: 32, width: 80),
                        ],
                      )
                    : _error != null
                        ? ErrorPlaceholder(message: _error, onRetry: _load)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.balance,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.bonusPoints(_balance ?? 0),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/qr'),
              icon: const Icon(Icons.qr_code_2, size: 28),
              label: Text(l10n.qrCode),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            _QuickLink(
              icon: Icons.wb_sunny_outlined,
              title: l10n.weather,
              onTap: () => context.push('/weather'),
            ),
            _QuickLink(
              icon: Icons.downhill_skiing,
              title: l10n.trails,
              onTap: () => context.push('/trails'),
            ),
            _QuickLink(
              icon: Icons.videocam_outlined,
              title: l10n.webcams,
              onTap: () => context.push('/webcams'),
            ),
            _QuickLink(
              icon: Icons.notifications_outlined,
              title: l10n.notifications,
              onTap: () => context.push('/notifications'),
            ),
            _QuickLink(
              icon: Icons.contact_mail_outlined,
              title: l10n.contact,
              onTap: () => context.push('/contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
