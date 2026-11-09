import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/status_views.dart';
import 'package:cabina/player/bloc/player_bloc.dart';
import 'package:cabina/player/models/player_args.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:cabina/player/views/player_page.dart';
import 'package:cabina/show_detail/models/episode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

void main() {
  const args = PlayerArgs(
    episode: Episode(
      guid: 'guid-1',
      title: 'Episode 1',
      audioUrl: 'https://example.com/audio.mp3',
      duration: Duration(minutes: 5),
    ),
    podcastTitle: 'Podcast Title',
  );

  late _MockPlayerBloc bloc;

  setUp(() {
    bloc = _MockPlayerBloc();
    when(() => bloc.state).thenReturn(
      const PlayerState(status: PlayerStatus.paused),
    );
  });

  /// Pumps the page on a phone-sized view: the square artwork overflows the
  /// default 800x600 test surface.
  Future<void> pumpPage(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme(isDark: false).toThemeData(),
        home: BlocProvider<PlayerBloc>.value(
          value: bloc,
          child: const PlayerPage(args: args),
        ),
      ),
    );
  }

  group('PlayerPage', () {
    testWidgets(
      'GIVEN the page opens '
      'THEN adds PlayerOpened with its args',
      (tester) async {
        await pumpPage(tester);

        verify(() => bloc.add(const PlayerOpened(args))).called(1);
      },
    );

    testWidgets(
      'GIVEN a paused episode '
      'THEN shows the episode and podcast titles',
      (tester) async {
        await pumpPage(tester);

        expect(find.text('Episode 1'), findsOneWidget);
        expect(find.text('Podcast Title'), findsOneWidget);
      },
    );

    testWidgets(
      'GIVEN error status '
      'THEN shows the ErrorView with the message',
      (tester) async {
        when(() => bloc.state).thenReturn(
          const PlayerState(
            status: PlayerStatus.error,
            errorMessage: 'Could not load audio',
          ),
        );

        await pumpPage(tester);

        expect(find.byType(ErrorView), findsOneWidget);
        expect(find.text('Could not load audio'), findsOneWidget);
      },
    );
  });
}
