import 'package:flutter_test/flutter_test.dart';
import 'package:gornaya_salanga/core/network/media_url.dart';

void main() {
  test('resolveBannerMediaUrl does not proxy api upload URLs', () {
    const raw =
        'https://api.salanga.ru/uploads/36555106-e89e-413a-9335-c96706d71b45.jpg';
    final out = resolveBannerMediaUrl(raw);
    expect(out, raw);
    expect(out.contains('banner-media'), isFalse);
  });
}
