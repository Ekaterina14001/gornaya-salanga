import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/salanga_colors.dart';
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

  String? _previewUrl(Map<String, dynamic> cam) {
    final raw = cam['previewUrl'] ?? cam['preview_url'] ?? cam['thumbnailUrl'];
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: SalangaColors.pageBackground,
      appBar: AppBar(
        title: Text(
          l10n.webcams,
          style: GoogleFonts.ptSerif(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: SalangaColors.pageBackground,
      ),
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: _webcams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 28),
                        itemBuilder: (context, index) {
                          final cam = Map<String, dynamic>.from(_webcams[index] as Map);
                          final name = cam['name'] as String? ?? 'Камера';
                          final preview = _previewUrl(cam);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  color: SalangaColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openCamera(cam),
                                  borderRadius: BorderRadius.circular(18),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 10,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (preview != null)
                                            Image.network(
                                              preview,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _previewFallback(),
                                            )
                                          else
                                            _previewFallback(),
                                          Center(
                                            child: Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white.withValues(alpha: 0.9),
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                size: 34,
                                                color: SalangaColors.textDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
      ),
    );
  }

  Widget _previewFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SalangaColors.sand, SalangaColors.warmBrown],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.landscape_outlined,
        size: 56,
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}
