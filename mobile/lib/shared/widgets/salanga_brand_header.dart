import 'package:flutter/material.dart';

import 'salanga_network_icon.dart';

class SalangaBrandHeader extends StatelessWidget {
  const SalangaBrandHeader({
    super.key,
    this.compact = false,
    this.showSubtitle = true,
  });

  final bool compact;

  /// Зарезервировано под подпись под логотипом (сейчас не используется).
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return SalangaNetworkIcon(size: compact ? 88 : 112);
  }
}

/// Круглый логотип для онбординга и экранов входа.
class SalangaBrandLogoCircle extends StatelessWidget {
  const SalangaBrandLogoCircle({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SalangaNetworkIcon(size: size);
  }
}
