import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_placeholder.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../catalog/data/content_repository.dart';
import 'webcam_player_page.dart';

class WebcamsPage extends StatefulWidget {
  const WebcamsPage({super.key});

  @override
  State<WebcamsPage> createState() => _WebcamsPageState();
}

class _WebcamsPageState extends State<WebcamsPage> {
  final _repository = ContentRepository();
  List<dynamic> _webcams = [];
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
      final webcams = await _repository.fetchWebcams(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _webcams = webcams;
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

  void _openCamera(Map<String, dynamic> cam) {
    final name = cam['name']?.toString() ?? 'Камера';
    final url = _streamUrl(cam);
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка на камеру не задана')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WebcamPlayerPage(title: name, streamUrl: url),
      ),
    );
  }

  String? _streamUrl(Map<String, dynamic> cam) {
    final raw = cam['streamUrl'] ?? cam['stream_url'];
    if (raw is String && raw.isNotEmpty) {
      return raw;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.webcams)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  Padding(padding: EdgeInsets.all(24), child: SkeletonLoader(height: 200)),
                ],
              )
            : _error != null
                ? ListView(children: [ErrorPlaceholder(message: _error, onRetry: _load)])
                : _webcams.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(l10n.webcamsPlaceholder, textAlign: TextAlign.center),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _webcams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final cam = Map<String, dynamic>.from(_webcams[index] as Map);
                          final name = cam['name'] as String? ?? 'Камера';
                          final location = cam['locationDescription'] as String? ??
                              cam['location_description'] as String? ??
                              '';
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.videocam),
                              ),
                              title: Text(name),
                              subtitle: location.isNotEmpty ? Text(location) : null,
                              trailing: const Icon(Icons.play_circle_outline),
                              onTap: () => _openCamera(cam),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
