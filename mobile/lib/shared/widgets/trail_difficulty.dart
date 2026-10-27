import 'package:flutter/material.dart';

import '../../core/theme/salanga_colors.dart';

/// Display labels for trail difficulty (resort legend: blue / pink / black rings).
abstract final class TrailDifficulty {
  static Color ringColor(String? difficulty) {
    switch (difficulty) {
      case 'green':
        return SalangaColors.greenDark;
      case 'blue':
        return const Color(0xFF4A90D9);
      case 'red':
        return const Color(0xFFE87A9A);
      case 'black':
        return SalangaColors.textDark;
      default:
        return SalangaColors.border;
    }
  }

  static String label(String? difficulty) {
    switch (difficulty) {
      case 'green':
        return 'Начальный уровень';
      case 'blue':
        return 'Лёгкий уровень';
      case 'red':
        return 'Средний уровень';
      case 'black':
        return 'Высокий уровень';
      default:
        return difficulty ?? '—';
    }
  }

  static const legendEntries = [
    ('blue', 'Лёгкий уровень'),
    ('red', 'Средний уровень'),
    ('black', 'Высокий уровень'),
  ];
}

class TrailDifficultyLegend extends StatelessWidget {
  const TrailDifficultyLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: SalangaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SalangaColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Уровень сложности',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: SalangaColors.textHeading,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < TrailDifficulty.legendEntries.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _LegendRow(
              color: TrailDifficulty.ringColor(TrailDifficulty.legendEntries[i].$1),
              label: TrailDifficulty.legendEntries[i].$2,
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: SalangaColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
