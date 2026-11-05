import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/poster_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPoster(WidgetTester tester, String? url) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme(isDark: false).toThemeData(),
        home: Center(child: PosterImage(url: url, size: 96)),
      ),
    );
  }

  group('PosterImage', () {
    testWidgets(
      'GIVEN a null artwork URL '
      'WHEN rendered '
      'THEN shows the placeholder without requesting an image',
      (tester) async {
        await pumpPoster(tester, null);

        expect(find.byIcon(Icons.podcasts), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      },
    );

    testWidgets(
      'GIVEN an artwork URL '
      'WHEN rendered '
      'THEN requests the network image',
      (tester) async {
        await pumpPoster(tester, 'https://example.com/artwork.jpg');

        expect(find.byType(Image), findsOneWidget);
        expect(find.byIcon(Icons.podcasts), findsNothing);
      },
    );
  });
}
