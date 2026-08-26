import 'package:flutter/material.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/markdown_content.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../data/content_repository.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> with SingleTickerProviderStateMixin {
  final _repo = ContentRepository();
  late final TabController _tabs;
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
    _tabs = TabController(length: 5, vsync: this);
    _load(refresh: true);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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

  static const _categoryLabels = {
    'lift': 'Подъёмники',
    'rental': 'Прокат',
    'tubing': 'Сноутюбинг',
    'snowmobile': 'Снегоходы',
    'other': 'Прочее',
  };

  String _formatPrice(Map<String, dynamic> s) {
    final desc = s['description']?.toString() ?? '';
    if (desc.isNotEmpty) return desc;
    final price = s['price'];
    if (price == null) return '';
    final num? value = price is num ? price : num.tryParse(price.toString());
    if (value == null) return '';
    if (value == 0) return 'бесплатно';
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)} ₽';
  }

  Widget _buildServicesList(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in _services) {
      final cat = s['category']?.toString() ?? 'other';
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    final order = ['lift', 'tubing', 'snowmobile', 'rental', 'other'];
    final categories = [
      ...order.where(grouped.containsKey),
      ...grouped.keys.where((k) => !order.contains(k)),
    ];

    return ListView.builder(
      itemCount: categories.fold<int>(0, (sum, c) => sum + 1 + grouped[c]!.length),
      itemBuilder: (context, index) {
        var cursor = 0;
        for (final cat in categories) {
          if (index == cursor) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _categoryLabels[cat] ?? cat,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          cursor++;
          final items = grouped[cat]!;
          for (var i = 0; i < items.length; i++) {
            if (index == cursor) {
              final s = items[i];
              final priceLabel = _formatPrice(s);
              return ListTile(
                title: Text(s['name']?.toString() ?? ''),
                subtitle: priceLabel != s['description']?.toString()
                    ? Text(s['description']?.toString() ?? '')
                    : null,
                trailing: Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            cursor++;
          }
        }
        return const SizedBox.shrink();
      },
    );
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
    final service = item['serviceName']?.toString() ?? item['service']?.toString() ?? '';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalog),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _load(refresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'О курорте'),
            Tab(text: 'Услуги'),
            Tab(text: 'Расписание'),
            Tab(text: 'Правила'),
            Tab(text: 'Бонусы'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: SkeletonLoader(height: 200))
          : _error != null
              ? ErrorPlaceholder(message: _error, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    RefreshIndicator(
                      onRefresh: () => _load(refresh: true),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            _about['title']?.toString() ?? 'Горная Саланга',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          MarkdownContent(
                            data: _about['bodyMarkdown']?.toString() ??
                                _about['body']?.toString() ??
                                l10n.catalogPlaceholder,
                          ),
                        ],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: () => _load(refresh: true),
                      child: _services.isEmpty
                          ? ListView(children: [Center(child: Text(l10n.catalogPlaceholder))])
                          : _buildServicesList(context),
                    ),
                    RefreshIndicator(
                      onRefresh: () => _load(refresh: true),
                      child: _buildScheduleList(context),
                    ),
                    RefreshIndicator(
                      onRefresh: () => _load(refresh: true),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(_visitRules['title']?.toString() ?? 'Правила посещения'),
                          const SizedBox(height: 8),
                          MarkdownContent(
                            data: _visitRules['bodyMarkdown']?.toString() ??
                                _visitRules['body']?.toString() ??
                                '',
                          ),
                        ],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: () => _load(refresh: true),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(_bonusRules['title']?.toString() ?? 'Бонусная программа'),
                          const SizedBox(height: 8),
                          MarkdownContent(
                            data: _bonusRules['bodyMarkdown']?.toString() ??
                                _bonusRules['body']?.toString() ??
                                '',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
