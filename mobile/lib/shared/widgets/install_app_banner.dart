import 'package:flutter/material.dart';

import '../../core/pwa/pwa_install.dart';
import '../../core/theme/salanga_colors.dart';
import '../../l10n/app_localizations.dart';

class InstallAppBanner extends StatefulWidget {
  const InstallAppBanner({super.key, this.compact = false});

  final bool compact;

  @override
  State<InstallAppBanner> createState() => _InstallAppBannerState();
}

class _InstallAppBannerState extends State<InstallAppBanner> {
  @override
  void initState() {
    super.initState();
    PwaInstall.onAvailabilityChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!PwaInstall.shouldShowHelp) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Card(
      color: SalangaColors.cream,
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.install_mobile,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.installAppTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _hintText(l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (PwaInstall.canPrompt) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => PwaInstall.prompt(),
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.installAppButton),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _hintText(AppLocalizations l10n) {
    if (PwaInstall.canPrompt) {
      return l10n.installAppHint;
    }
    if (PwaInstall.isIos) {
      return l10n.installAppIosHint;
    }
    return l10n.installAppAndroidHint;
  }
}

Future<void> showInstallAppDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.installAppTitle),
        content: Text(
          PwaInstall.canPrompt
              ? l10n.installAppHint
              : PwaInstall.isIos
                  ? l10n.installAppIosHint
                  : l10n.installAppAndroidHint,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          if (PwaInstall.canPrompt)
            FilledButton(
              onPressed: () async {
                await PwaInstall.prompt();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.installAppButton),
            ),
        ],
      );
    },
  );
}

bool get showInstallAppMenuItem => PwaInstall.shouldShowHelp;
