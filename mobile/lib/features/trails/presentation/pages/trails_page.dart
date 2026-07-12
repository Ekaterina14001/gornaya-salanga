import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../catalog/data/content_repository.dart';

class TrailsPage extends StatefulWidget {
  const TrailsPage({super.key});

  @override
  State<TrailsPage> createState() => _TrailsPageState();
}

class _TrailsPageState extends State<TrailsPage> {
  final _repository = ContentRepository();
  List<dynamic> _trails = [];
  List<dynamic> _lifts = [];
  bool _loading = true;
  String? _error;

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
      final trails = await _repository.fetchTrails(forceRefresh: true);
      final lifts = await _repository.fetchLifts(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _trails = trails;
        _lifts = lifts;
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

  Color _difficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'black':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  String _liftHours(Map<String, dynamic> map) {
    final open = _formatTime(map['openTime']);
    final close = _formatTime(map['closeTime']);
    if (open.isNotEmpty && close.isNotEmpty) return '$open–$close';
    return '';
  }

  String _liftSubtitle(Map<String, dynamic> map) {
    final parts = <String>[];
    final hours = _liftHours(map);
    if (hours.isNotEmpty) parts.add(hours);
    final description = map['description'] as String?;
    if (description != null && description.isNotEmpty) parts.add(description);
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trails)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: SkeletonLoader(height: 200),
                  ),
                ],
              )
            : _error != null
                ? ListView(
                    children: [
                      ErrorPlaceholder(message: _error, onRetry: _load),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Трассы', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_trails.isEmpty)
                        Text(l10n.trailsPlaceholder)
                      else
                        ..._trails.map((t) {
                          final map = Map<String, dynamic>.from(t as Map);
                          final status = map['status'] as String? ?? 'closed';
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _difficultyColor(map['difficulty'] as String?),
                                radius: 8,
                              ),
                              title: Text(map['name'] as String? ?? ''),
                              subtitle: Text('${map['difficulty'] ?? ''} • ${map['operatingHours'] ?? ''}'),
                              trailing: Chip(
                                label: Text(status == 'open' ? 'Открыта' : 'Закрыта'),
                                backgroundColor: status == 'open' ? Colors.green.shade100 : Colors.red.shade100,
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      Text('Подъёмники', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_lifts.isEmpty)
                        const Text('Нет данных о подъёмниках')
                      else
                        ..._lifts.map((l) {
                          final map = Map<String, dynamic>.from(l as Map);
                          final status = map['status'] as String? ?? 'closed';
                          final pricesText = map['pricesText'] as String?;
                          final comment = map['comment'] as String?;
                          final details = [
                            if (pricesText != null && pricesText.isNotEmpty) pricesText,
                            if (comment != null && comment.isNotEmpty) comment,
                          ].join('\n\n');

                          return Card(
                            child: details.isEmpty
                                ? ListTile(
                                    leading: const Icon(Icons.cable),
                                    title: Text(map['name'] as String? ?? ''),
                                    subtitle: Text(_liftSubtitle(map)),
                                    trailing: Text(status == 'open' ? 'Работает' : 'Стоп'),
                                  )
                                : ExpansionTile(
                                    leading: const Icon(Icons.cable),
                                    title: Text(map['name'] as String? ?? ''),
                                    subtitle: Text(_liftSubtitle(map)),
                                    trailing: Text(
                                      status == 'open' ? 'Работает' : 'Стоп',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        child: Text(
                                          details,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
