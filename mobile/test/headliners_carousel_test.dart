import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gornaya_salanga/features/home/presentation/widgets/headliners_carousel.dart';

void main() {
  testWidgets('HeadlinersCarousel builds horizontal PageView for lower slots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: HeadlinersCarousel(
              bottomBanners: [
                {'sortOrder': 1, 'imageUrl': ''},
                {'sortOrder': 2, 'imageUrl': ''},
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('HeadlinersCarousel hidden when no bottom banners', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeadlinersCarousel(bottomBanners: []),
        ),
      ),
    );

    expect(find.byType(PageView), findsNothing);
  });
}
