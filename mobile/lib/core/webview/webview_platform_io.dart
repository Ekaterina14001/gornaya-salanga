import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

bool get supportsInAppWebView {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

Future<void> ensureWebViewPlatform() async {
  if (WebViewPlatform.instance != null) {
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      WebViewPlatform.instance = AndroidWebViewPlatform();
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      WebViewPlatform.instance = WebKitWebViewPlatform();
    default:
      break;
  }
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
  late final PlatformWebViewControllerCreationParams params;
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  } else {
    params = const PlatformWebViewControllerCreationParams();
  }

  final controller = WebViewController.fromPlatformCreationParams(params)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0xFF000000));

  if (controller.platform is AndroidWebViewController) {
    final android = controller.platform as AndroidWebViewController;
    android.setMediaPlaybackRequiresUserGesture(false);
  }

  controller.loadHtmlString(
    buildWebcamEmbedHtml(streamUrl),
    baseUrl: 'https://rtsp.ru',
  );

  return controller;
}
