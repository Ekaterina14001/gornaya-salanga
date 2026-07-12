import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingSlide(
      icon: Icons.landscape,
      titleKey: 'onboardingTitle1',
      bodyKey: 'onboardingBody1',
    ),
    _OnboardingSlide(
      icon: Icons.qr_code_2,
      titleKey: 'onboardingTitle2',
      bodyKey: 'onboardingBody2',
    ),
    _OnboardingSlide(
      icon: Icons.notifications_active_outlined,
      titleKey: 'onboardingTitle3',
      bodyKey: 'onboardingBody3',
    ),
  ];

  Future<void> _complete() async {
    await HiveBoxes.setOnboardingComplete(true);
    if (!mounted) return;
    context.go('/login');
  }

  void _next(AppLocalizations l10n) {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  String _text(AppLocalizations l10n, String key) {
    return switch (key) {
      'onboardingTitle1' => l10n.onboardingTitle1,
      'onboardingBody1' => l10n.onboardingBody1,
      'onboardingTitle2' => l10n.onboardingTitle2,
      'onboardingBody2' => l10n.onboardingBody2,
      'onboardingTitle3' => l10n.onboardingTitle3,
      'onboardingBody3' => l10n.onboardingBody3,
      _ => key,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _complete,
            child: Text(l10n.skip),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final slide = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(slide.icon, size: 96),
                      const SizedBox(height: 32),
                      Text(
                        _text(l10n, slide.titleKey),
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _text(l10n, slide.bodyKey),
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (i) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _next(l10n),
                  child: Text(isLast ? l10n.start : l10n.next),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final String titleKey;
  final String bodyKey;
}
