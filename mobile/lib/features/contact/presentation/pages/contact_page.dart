import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/contact_repository.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _repository = ContactRepository();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  bool _loading = true;
  String? _success;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchMessages();
      if (!mounted) return;
      setState(() {
        _messages = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _success = null;
    });
    try {
      await _repository.sendMessage(
        subject: _subjectController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _success = 'Сообщение отправлено';
        _subjectController.clear();
        _bodyController.clear();
      });
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'ru');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contact)),
      body: RefreshIndicator(
        onRefresh: _loadMessages,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Свяжитесь с администрацией курорта',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Тема',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Сообщение',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_success != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_success!, style: const TextStyle(color: Colors.green)),
              ),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Отправить'),
            ),
            const SizedBox(height: 24),
            Text('Мои обращения', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_messages.isEmpty)
              Text(
                'Пока нет сообщений',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              )
            else
              ..._messages.map((msg) {
                final createdAt = msg['createdAt'] as String?;
                final dt = createdAt != null ? DateTime.tryParse(createdAt) : null;
                final status = msg['status'] as String? ?? '';
                final adminReply = msg['adminReply'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['subject'] as String? ?? '',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (dt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(dt.toLocal()),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(msg['body'] as String? ?? ''),
                        const SizedBox(height: 8),
                        Text(
                          status == 'replied' ? 'Ответ получен' : 'Ожидает ответа',
                          style: TextStyle(
                            color: status == 'replied' ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        if (adminReply != null && adminReply.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ответ администрации',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(adminReply),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
