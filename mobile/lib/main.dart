import 'package:flutter/material.dart';

import 'app.dart';
import 'core/push/push_service.dart';
import 'core/storage/hive_boxes.dart';
import 'core/webview/webview_platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  await ensureWebViewPlatform();
  await PushService.instance.init();
  runApp(GornayaSalangaApp());
}
