import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final w = _weather;
    final forecast = _forecastDays();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weather)),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_loading)
              const SkeletonLoader(height: 120)
            else if (_error != null)
              ErrorPlaceholder(message: _error, onRetry: _load)
            else if (w != null && w.isNotEmpty) ...[
              Text(
                '${w['temperature'] ?? w['tempDay'] ?? '—'}°C',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                w['description']?.toString() ?? '—',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (w['tempNight'] != null) Text('Ночью: ${w['tempNight']}°C'),
              if (w['feelsLike'] != null) Text('Ощущается как: ${w['feelsLike']}°C'),
              Text('Влажность: ${w['humidity'] ?? '—'}%'),
              Text('Ветер: ${w['windSpeed'] ?? '—'} ${w['windDirection'] ?? ''}'),
              if (w['precipitation'] == true)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Ожидаются осадки'),
                ),
              if (forecast.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Прогноз', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...forecast.asMap().entries.map((entry) {
                  final day = entry.value;
                  return Card(
                    child: ListTile(
                      title: Text(_dayTitle(day, entry.key)),
                      subtitle: Text(
                        '${day['description'] ?? '—'} • ночью ${day['tempNight'] ?? '—'}°C',
                      ),
                      trailing: Text('${day['tempDay'] ?? '—'}°C'),
                    ),
                  );
                }),
              ],
              if (w['source'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Источник: ${w['source']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ] else
              Text(l10n.weatherPlaceholder, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
