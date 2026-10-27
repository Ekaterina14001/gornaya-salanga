import 'package:flutter/material.dart';

import '../../core/network/media_url.dart';
import '../../core/theme/salanga_colors.dart';
import 'home_banner_defaults.dart';

/// Картинка баннера: direct salanga → API-прокси → fallback.
class AdminBannerImage extends StatefulWidget {
  const AdminBannerImage({
    required this.imageUrl,
    this.sortOrder = 0,
    super.key,
  });

  final String? imageUrl;
  final int sortOrder;

  @override
  State<AdminBannerImage> createState() => _AdminBannerImageState();
}

class _AdminBannerImageState extends State<AdminBannerImage> {
  int _attempt = 0;

  @override
  void didUpdateWidget(covariant AdminBannerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.sortOrder != widget.sortOrder) {
      _attempt = 0;
    }
  }

  bool get _isAdminUpload {
    final p = (widget.imageUrl ?? '').trim();
    return p.contains('/uploads/');
  }

  List<String> get _candidates {
    final sort = widget.sortOrder;
    final primary = (widget.imageUrl ?? '').trim();
    final fallback = HomeBannerDefaults.forSortOrder(sort);

    final urls = <String>[];
    void add(String? u) {
      if (u == null || u.isEmpty) return;
      if (!urls.contains(u)) urls.add(u);
    }

    add(resolveBannerMediaUrl(primary));
    add(primary);
    // Загрузка из админки: не подменять дефолтом salanga.ru при ошибке сети.
    if (_isAdminUpload) return urls;

    if (fallback != primary) {
      add(resolveBannerMediaUrl(fallback));
      add(fallback);
    }
    return urls;
  }

  String? _directSalanga(String url) {
    if (url.contains('salanga.ru') && !url.contains('banner-media')) return url;
    return null;
  }

  Map<String, String>? get _headers {
    final url = _candidates.isNotEmpty && _attempt < _candidates.length
        ? _candidates[_attempt]
        : '';
    if (url.contains('salanga.ru') && !url.contains('banner-media')) {
      return const {'Referer': 'https://www.salanga.ru/'};
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final urls = _candidates;
    if (urls.isEmpty) {
      return const _EmptyBannerPlaceholder();
    }
    final idx = _attempt.clamp(0, urls.length - 1);
    final url = urls[idx];

    const fit = BoxFit.cover;
    const alignment = Alignment.center;

    return Image.network(
      url,
      key: ValueKey('$idx-$url'),
      fit: fit,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      headers: _headers,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) {
        if (_attempt + 1 < urls.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _attempt++);
          });
        }
        return const _EmptyBannerPlaceholder();
      },
    );
  }
}

class _EmptyBannerPlaceholder extends StatelessWidget {
  const _EmptyBannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: SalangaColors.sand.withValues(alpha: 0.6),
        size: 40,
      ),
    );
  }
}
