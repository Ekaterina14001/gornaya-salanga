import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

bool get supportsInAppWebView => true;

Future<void> ensureWebViewPlatform() async {
  if (WebViewPlatform.instance != null) {
    return;
  }
  WebViewPlatform.instance = WebWebViewPlatform();
}

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
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(
      buildWebcamEmbedHtml(streamUrl),
      baseUrl: 'https://rtsp.ru',
    );
  return controller;
}
