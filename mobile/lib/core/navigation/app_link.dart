import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openAppLink(BuildContext context, String? link) async {
  if (link == null || link.isEmpty) return;

  if (link.startsWith('http://') || link.startsWith('https://')) {
    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return;
  }

  if (link.startsWith('/')) {
    if (!context.mounted) return;
    if (_isShellRoute(link)) {
      context.go(link);
    } else {
      context.push(link);
    }
  }
}

bool _isShellRoute(String link) {
  const shellRoutes = ['/home', '/bonus', '/catalog', '/profile'];
  return shellRoutes.contains(link.split('?').first);
}

String? notificationLink(Map<String, dynamic> item) {
  final data = item['data'];
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final link = map['linkUrl'] ?? map['link'];
    if (link is String && link.isNotEmpty) {
      return link;
    }
    if (map['messageId'] != null) {
      return '/contact';
    }
  }
  return null;
}
