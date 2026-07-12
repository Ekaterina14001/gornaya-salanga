import 'package:webview_flutter/webview_flutter.dart';

bool get supportsInAppWebView => false;

Future<void> ensureWebViewPlatform() async {}

String buildWebcamEmbedHtml(String streamUrl) {
  return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      html, body { margin: 0; padding: 0; height: 100%; background: #000; }
      iframe { border: 0; width: 100%; height: 100%; }
    </style>
  </head>
  <body>
    <iframe src="$streamUrl" allow="autoplay; fullscreen" allowfullscreen></iframe>
  </body>
</html>
''';
}

WebViewController createWebcamController(String streamUrl) {
  throw UnsupportedError('In-app WebView is not supported on this platform');
}
