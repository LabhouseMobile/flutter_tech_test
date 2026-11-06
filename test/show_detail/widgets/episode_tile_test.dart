import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/show_detail/models/episode.dart';
import 'package:cabina/show_detail/widgets/episode_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpTile(WidgetTester tester, Episode episode) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme(isDark: false).toThemeData(),
        home: Scaffold(
          body: EpisodeTile(episode: episode, onTap: () {}),
        ),
      ),
    );
  }

  Episode buildEpisode({Duration? duration, DateTime? publishedAt}) => Episode(
    guid: 'guid-1',
    title: 'Episode title',
    audioUrl: 'https://example.com/episode.mp3',
    duration: duration,
    publishedAt: publishedAt,
  );

  /// Durations the tile must never render in the meta line.
  const omittedDurations = <(String, Duration?)>[
    ('null', null),
    ('zero', Duration.zero),
    ('negative', Duration(minutes: -5)),
  ];

  /// Every text rendered by the tile, in order.
  List<String?> tileTexts(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(EpisodeTile),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data)
      .toList();

  group('EpisodeTile', () {
    testWidgets(
      'GIVEN a positive duration and a publish date '
      'WHEN rendered '
      'THEN shows both joined in the meta line',
      (tester) async {
        await pumpTile(
          tester,
          buildEpisode(
            duration: const Duration(hours: 1, minutes: 2),
            publishedAt: DateTime(2024, 1, 5),
          ),
        );

        expect(find.text('Jan 5, 2024 · 1h 2m'), findsOneWidget);
      },
    );

    testWidgets(
      'GIVEN a positive duration and no publish date '
      'WHEN rendered '
      'THEN shows only the duration in the meta line',
      (tester) async {
        await pumpTile(
          tester,
          buildEpisode(duration: const Duration(minutes: 43)),
        );

        expect(tileTexts(tester), ['Episode title', '43m']);
      },
    );

    for (final (label, duration) in omittedDurations) {
      testWidgets(
        'GIVEN a $label duration '
        'WHEN rendered '
        'THEN omits the duration from the meta line',
        (tester) async {
          await pumpTile(
            tester,
            buildEpisode(duration: duration, publishedAt: DateTime(2024, 1, 5)),
          );

          expect(find.text('Jan 5, 2024'), findsOneWidget);
          expect(find.textContaining(RegExp(r'\d+m\b')), findsNothing);
        },
      );
    }

    for (final (label, duration) in omittedDurations) {
      testWidgets(
        'GIVEN no publish date and a $label duration '
        'WHEN rendered '
        'THEN renders only the title, with no empty meta line',
        (tester) async {
          await pumpTile(tester, buildEpisode(duration: duration));

          expect(tileTexts(tester), ['Episode title']);
        },
      );
    }
  });
}
