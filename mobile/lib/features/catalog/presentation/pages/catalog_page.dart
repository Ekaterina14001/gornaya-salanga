import 'package:flutter/material.dart';

import '../../../../core/storage/hive_boxes.dart';

import '../../../../core/theme/salanga_colors.dart';

import '../../../../l10n/app_localizations.dart';

import '../../../../shared/widgets/error_placeholder.dart';

import '../../../../shared/widgets/markdown_content.dart';

import '../../../../shared/widgets/skeleton_loader.dart';

import '../../catalog_hub_controller.dart';

import '../../catalog_sections.dart';

import '../../data/content_repository.dart';

import '../widgets/catalog_hub_view.dart';

import '../widgets/catalog_services_view.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _repo = ContentRepository();

  CatalogSection? _section;

  List<Map<String, dynamic>> _services = [];

  Map<String, dynamic> _about = {};

  List<dynamic> _schedule = [];

  Map<String, dynamic> _visitRules = {};

  Map<String, dynamic> _bonusRules = {};

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    CatalogHubController.instance.addListener(_onShowMenu);

    _load(refresh: true);
  }

  @override
  void dispose() {
    CatalogHubController.instance.removeListener(_onShowMenu);

    super.dispose();
  }

  void _onShowMenu() {
    if (!mounted) return;

    setState(() => _section = null);
  }

  void _openSection(CatalogSection section) {
    setState(() => _section = section);
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      await HiveBoxes.settings.delete('services_cache');
    }

    setState(() {
      _loading = true;

      _error = null;
    });

    try {
      final results = await Future.wait([
        _repo.fetchServices(forceRefresh: refresh),

        _repo.fetchAbout(forceRefresh: refresh),

        _repo.fetchSchedule(forceRefresh: refresh),

        _repo.fetchRules('visiting', forceRefresh: refresh),

        _repo.fetchRules('bonus', forceRefresh: refresh),
      ]);

      if (!mounted) return;

      setState(() {
        _services = (results[0] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _about = results[1] as Map<String, dynamic>;

        _schedule = results[2] as List<dynamic>;

        _visitRules = results[3] as Map<String, dynamic>;

        _bonusRules = results[4] as Map<String, dynamic>;

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

  static const _serviceLabels = {
    'reception': 'Ресепшн',

    'restaurant': 'Ресторан',

    'ski_lift': 'Подъёмники',

    'rental': 'Прокат',
  };

  static const _dayLabels = [
    'Воскресенье',

    'Понедельник',

    'Вторник',

    'Среда',

    'Четверг',

    'Пятница',

    'Суббота',
  ];

  String _shortTime(String? value) {
    if (value == null || value.isEmpty) return '';

    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  String _scheduleLine(Map<String, dynamic> item) {
    final service =
        item['serviceName']?.toString() ?? item['service']?.toString() ?? '';

    final name = _serviceLabels[service] ?? service;

    if (item['closed'] == true) {
      return '$name — закрыто';
    }

    final open = _shortTime(item['openTime']?.toString());

    final close = _shortTime(item['closeTime']?.toString());

    return '$name: $open — $close';
  }

  Widget _buildScheduleList(BuildContext context) {
    if (_schedule.isEmpty) {
      return ListView(
        children: [
          Center(child: Text(AppLocalizations.of(context)!.catalogPlaceholder)),
        ],
      );
    }

    final byDay = <int, List<Map<String, dynamic>>>{};

    for (final raw in _schedule) {
      final item = Map<String, dynamic>.from(raw as Map);

      final day = item['dayOfWeek'] as int? ?? 0;

      byDay.putIfAbsent(day, () => []).add(item);
    }

    final days = byDay.keys.toList()..sort();

    final children = <Widget>[];

    for (final day in days) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),

          child: Text(
            _dayLabels[day.clamp(0, 6)],

            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );

      for (final item in byDay[day]!) {
        children.add(ListTile(title: Text(_scheduleLine(item))));
      }
    }

    return ListView(children: children);
  }

  Widget _buildSectionBody(BuildContext context, AppLocalizations l10n) {
    switch (_section!) {
      case CatalogSection.about:
        return ListView(
          padding: const EdgeInsets.all(16),

          children: [
            Text(
              _about['title']?.toString() ?? 'Горная Саланга',

              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 12),

            MarkdownContent(
              data:
                  _about['bodyMarkdown']?.toString() ??
                  _about['body']?.toString() ??
                  l10n.catalogPlaceholder,
            ),
          ],
        );

      case CatalogSection.services:
        if (_services.isEmpty) {
          return ListView(
            children: [Center(child: Text(l10n.catalogPlaceholder))],
          );
        }

        return CatalogServicesView(services: _services);

      case CatalogSection.schedule:
        return _buildScheduleList(context);

      case CatalogSection.visitRules:
        return ListView(
          padding: const EdgeInsets.all(16),

          children: [
            Text(_visitRules['title']?.toString() ?? 'Правила посещения'),

            const SizedBox(height: 8),

            MarkdownContent(
              data:
                  _visitRules['bodyMarkdown']?.toString() ??
                  _visitRules['body']?.toString() ??
                  '',
            ),
          ],
        );

      case CatalogSection.bonusRules:
        return ListView(
          padding: const EdgeInsets.all(16),

          children: [
            Text(_bonusRules['title']?.toString() ?? 'Бонусная программа'),

            const SizedBox(height: 8),

            MarkdownContent(
              data:
                  _bonusRules['bodyMarkdown']?.toString() ??
                  _bonusRules['body']?.toString() ??
                  '',
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final inSection = _section != null;

    return Scaffold(
      backgroundColor: inSection
          ? SalangaColors.pageBackground
          : SalangaColors.catalogHubBackground,

      appBar: inSection
          ? AppBar(
              backgroundColor: SalangaColors.pageBackground,

              elevation: 0,

              leading: IconButton(
                icon: const Icon(Icons.arrow_back),

                onPressed: () => setState(() => _section = null),
              ),

              title: Text(catalogSectionTitle(_section!)),

              actions: [
                IconButton(
                  tooltip: 'Обновить',

                  icon: const Icon(Icons.refresh),

                  onPressed: _loading ? null : () => _load(refresh: true),
                ),
              ],
            )
          : null,

      body: _loading
          ? const Center(child: SkeletonLoader(height: 200))
          : _error != null
          ? ErrorPlaceholder(message: _error, onRetry: _load)
          : inSection
          ? RefreshIndicator(
              onRefresh: () => _load(refresh: true),

              child: _buildSectionBody(context, l10n),
            )
          : CatalogHubView(
              onSectionSelected: _openSection,

              onRefresh: () => _load(refresh: true),

              refreshing: _loading,
            ),
    );
  }
}
