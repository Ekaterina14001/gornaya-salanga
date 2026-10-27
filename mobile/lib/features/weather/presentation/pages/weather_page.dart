import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/salanga_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/weather_condition_icon.dart';
import '../../../catalog/data/content_repository.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _repo = ContentRepository();
  Map<String, dynamic>? _weather;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.fetchWeather(forceRefresh: refresh);
      if (!mounted) return;
      setState(() {
        _weather = data;
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

  List<Map<String, dynamic>> _forecastDays() {
    final raw = _weather?['forecast'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _dayTitle(Map<String, dynamic> day, int index) {
    final label = day['label']?.toString();
    if (label != null && label.isNotEmpty) return label;
    return index == 0 ? 'Сегодня' : 'День ${index + 1}';
  }

  String _windLine(Map<String, dynamic> w) {
    final speed = w['windSpeed'];
    if (speed == null) return '—';
    final dir = w['windDirection']?.toString() ?? '';
    if (dir.isNotEmpty) return '$speed $dir';
    return '$speed м/с';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final w = _weather;
    final forecast = _forecastDays();
    final description = w?['description']?.toString() ?? '—';
    final temp = w?['temperature'] ?? w?['tempDay'] ?? '—';

    return Scaffold(
      backgroundColor: SalangaColors.pageBackground,
      appBar: AppBar(
        title: Text(l10n.weather),
        centerTitle: true,
        backgroundColor: SalangaColors.pageBackground,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          children: [
            if (_loading)
              const SkeletonLoader(height: 320)
            else if (_error != null)
              ErrorPlaceholder(message: _error, onRetry: _load)
            else if (w != null && w.isNotEmpty) ...[
              Center(
                child: Text(
                  'Сейчас',
                  style: GoogleFonts.ptSerif(
                    fontSize: 18,
                    color: SalangaColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '$temp°C',
                  style: GoogleFonts.ptSerif(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: SalangaColors.textDark,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: WeatherConditionIcon(description: description, size: 56)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  description,
                  style: GoogleFonts.ptSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: SalangaColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _StatLine(label: 'Ночью', value: w['tempNight'] != null ? '${w['tempNight']}°C' : '—'),
              _StatLine(
                label: 'Ощущается как',
                value: w['feelsLike'] != null ? '${w['feelsLike']}°C' : '—',
              ),
              _StatLine(label: 'Влажность', value: '${w['humidity'] ?? '—'} %'),
              _StatLine(label: 'Ветер', value: _windLine(w)),
              if (forecast.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: SalangaColors.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SalangaColors.sand),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: forecast.take(7).toList().asMap().entries.map((entry) {
                      final day = entry.value;
                      final dayDesc = day['description']?.toString();
                      return Column(
                        children: [
                          if (entry.key > 0)
                            const Divider(height: 1, thickness: 1, color: SalangaColors.sand),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _dayTitle(day, entry.key),
                                    style: GoogleFonts.openSans(
                                      color: SalangaColors.textDark,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                WeatherConditionIcon(description: dayDesc, size: 26),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${day['tempNight'] ?? '—'}°',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.openSans(
                                      color: SalangaColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '${day['tempDay'] ?? '—'}°',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.openSans(
                                      color: SalangaColors.textDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ] else
              Text(l10n.weatherPlaceholder, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.openSans(fontSize: 15, color: SalangaColors.textPrimary),
            children: [
              TextSpan(text: '$label: '),
              TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.w600, color: SalangaColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
