import 'package:flutter/material.dart';

import '../../../home/data/bonus_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

class BonusPage extends StatefulWidget {
  const BonusPage({super.key});

  @override
  State<BonusPage> createState() => _BonusPageState();
}

class _BonusPageState extends State<BonusPage> {
  final _repository = BonusRepository();
  final _scrollController = ScrollController();
  final _items = <BonusTransaction>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  String? _filter;
  BonusAccountSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _repository.fetchAccountSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (_) {}
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.fetchHistory(page: _page, type: _filter);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.items);
        _page++;
        _hasMore = result.hasMore;
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

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
    });
    await Future.wait([_loadSummary(), _loadMore()]);
  }

  void _setFilter(String? filter) {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _items.clear();
      _page = 1;
      _hasMore = true;
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bonus)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error != null && _items.isEmpty
            ? ListView(
                children: [
                  ErrorPlaceholder(message: _error, onRetry: _refresh),
                ],
              )
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Баланс', style: Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${summary?.balance.toStringAsFixed(0) ?? '—'} бонусов',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (summary != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Начислено: ${summary.totalEarned.toStringAsFixed(0)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Списано: ${summary.totalSpent.toStringAsFixed(0)}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Все'),
                            selected: _filter == null,
                            onSelected: (_) => _setFilter(null),
                          ),
                          FilterChip(
                            label: const Text('Начисления'),
                            selected: _filter == 'earn',
                            onSelected: (_) => _setFilter('earn'),
                          ),
                          FilterChip(
                            label: const Text('Списания'),
                            selected: _filter == 'spend',
                            onSelected: (_) => _setFilter('spend'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (_items.isEmpty && !_loading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Нет операций')),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: SkeletonLoader(height: 24, width: 120)),
                            );
                          }
                          final tx = _items[index];
                          final isEarn = tx.type == 'earn';
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                isEarn ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                color: isEarn ? Colors.green : Colors.orange,
                              ),
                              title: Text('${isEarn ? '+' : '-'}${tx.amount.toStringAsFixed(0)}'),
                              subtitle: Text(tx.description ?? tx.type),
                            ),
                          );
                        },
                        childCount: _items.length + (_hasMore ? 1 : 0),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
