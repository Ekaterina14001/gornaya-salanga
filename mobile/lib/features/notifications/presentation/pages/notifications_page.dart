import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../../core/navigation/app_link.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../data/notifications_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repository = NotificationsRepository();
  List<Map<String, dynamic>> _items = [];
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
      final items = await _repository.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _openNotification(Map<String, dynamic> item) async {
    final id = item['id'] as String?;
    if (id != null && (item['read'] as bool? ?? false) == false) {
      await _repository.markRead(id);
      setState(() {
        final index = _items.indexWhere((row) => row['id'] == id);
        if (index >= 0) {
          _items[index] = {..._items[index], 'read': true};
        }
      });
    }

    if (!mounted) return;

    final link = notificationLink(item);
    if (link != null) {
      await openAppLink(context, link);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['title'] as String? ?? ''),
        content: Text(item['body'] as String? ?? ''),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'ru');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(children: const [Padding(padding: EdgeInsets.all(24), child: SkeletonLoader(height: 200))])
            : _error != null
                ? ListView(children: [ErrorPlaceholder(message: _error, onRetry: _load)])
                : _items.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(l10n.notificationsPlaceholder, textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isRead = item['read'] as bool? ?? false;
                          final createdAt = item['createdAt'] as String?;
                          final link = notificationLink(item);
                          DateTime? dt;
                          if (createdAt != null) {
                            dt = DateTime.tryParse(createdAt);
                          }
                          return Card(
                            color: isRead
                                ? null
                                : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                            child: ListTile(
                              title: Text(
                                item['title'] as String? ?? '',
                                style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['body'] as String? ?? ''),
                                  if (dt != null)
                                    Text(
                                      dateFormat.format(dt.toLocal()),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                              trailing: link != null ? const Icon(Icons.chevron_right) : null,
                              onTap: () => _openNotification(item),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
