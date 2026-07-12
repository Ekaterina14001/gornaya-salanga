import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/webview/webview_platform.dart';

/// Full-screen rtsp.ru embed player (ported from legacy Mobile app).
class WebcamPlayerPage extends StatefulWidget {
  const WebcamPlayerPage({
    super.key,
    required this.title,
    required this.streamUrl,
  });

  final String title;
  final String streamUrl;

  @override
  State<WebcamPlayerPage> createState() => _WebcamPlayerPageState();
}

class _WebcamPlayerPageState extends State<WebcamPlayerPage> {
  WebViewController? _controller;
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (!supportsInAppWebView) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Встроенный плеер недоступен на этой платформе';
      });
      return;
    }

    try {
      await ensureWebViewPlatform();
      if (WebViewPlatform.instance == null) {
        throw StateError('WebView platform is not available');
      }
      final controller = createWebcamController(widget.streamUrl);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initializing = false;
      });
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.streamUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Открыть в браузере',
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Плеер недоступен',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Открыть в браузере'),
              ),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: _controller!);
  }
}
