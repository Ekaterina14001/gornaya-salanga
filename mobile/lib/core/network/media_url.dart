import '../config/app_config.dart';

/// Resolves API-relative paths like `/uploads/…` to a full URL for [Image.network].
String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (url.startsWith('/')) return '$base$url';
  return '$base/$url';
}

bool _isSalangaWebsiteHost(String host) {
  final h = host.toLowerCase();
  return h == 'salanga.ru' || h == 'www.salanga.ru';
}

/// Баннеры с сайта salanga.ru — через API-прокси. Загрузки `/uploads/` — как есть (same origin).
String resolveBannerMediaUrl(String? url) {
  final resolved = resolveMediaUrl(url);
  if (resolved.isEmpty) return resolved;
  if (resolved.contains('/api/content/banner-media')) return resolved;
  final uri = Uri.tryParse(resolved);
  if (uri == null) return resolved;
  if (uri.path.startsWith('/uploads/')) return resolved;
  if (!_isSalangaWebsiteHost(uri.host)) return resolved;
  final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  return '$base/api/content/banner-media?url=${Uri.encodeComponent(resolved)}';
}
