import 'package:flutter/material.dart';

import '../../core/theme/salanga_colors.dart';

IconData weatherIconForDescription(String? description) {
  final d = (description ?? '').toLowerCase();
  if (d.contains('гроз') || d.contains('storm')) {
    return Icons.thunderstorm_outlined;
  }
  if (d.contains('снег') || d.contains('snow')) {
    return Icons.ac_unit_outlined;
  }
  if (d.contains('дожд') || d.contains('rain')) {
    return Icons.grain;
  }
  if (d.contains('облач') || d.contains('cloud')) {
    return Icons.wb_cloudy_outlined;
  }
  if (d.contains('ясн') || d.contains('солнеч') || d.contains('clear')) {
    return Icons.wb_sunny_outlined;
  }
  return Icons.wb_cloudy_outlined;
}

class WeatherConditionIcon extends StatelessWidget {
  const WeatherConditionIcon({
    super.key,
    required this.description,
    this.size = 56,
  });

  final String? description;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      weatherIconForDescription(description),
      size: size,
      color: SalangaColors.textDark,
    );
  }
}
