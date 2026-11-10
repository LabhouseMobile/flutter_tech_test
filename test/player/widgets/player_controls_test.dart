import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/player/bloc/player_bloc.dart';
import 'package:cabina/player/models/playback_speed.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:cabina/player/widgets/player_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

void main() {
  late _MockPlayerBloc bloc;

  setUp(() => bloc = _MockPlayerBloc());

  /// Pumps the controls over whatever `bloc.state` is stubbed to, so a
  /// `whenListen` stream can drive them.
  Future<void> pumpWithBloc(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme(isDark: false).toThemeData(),
      home: Scaffold(
        body: BlocProvider<PlayerBloc>.value(
          value: bloc,
          child: const PlayerControls(),
        ),
      ),
    ),
  );

  Future<void> pumpControls(WidgetTester tester, PlayerState state) {
    when(() => bloc.state).thenReturn(state);
    return pumpWithBloc(tester);
  }

  group('PlayerControls', () {
    testWidgets(
      'GIVEN a paused episode '
      'WHEN tapping play '
      'THEN adds PlayerPlayPauseToggled',
      (tester) async {
        await pumpControls(
          tester,
          const PlayerState(status: PlayerStatus.paused),
        );

        await tester.tap(find.byIcon(Icons.play_arrow));

        verify(() => bloc.add(const PlayerPlayPauseToggled())).called(1);
      },
    );

    testWidgets(
      'GIVEN speed x1 '
      'WHEN tapping the speed label '
      'THEN adds PlayerSpeedChanged with the next speed',
      (tester) async {
        await pumpControls(tester, const PlayerState());

        await tester.tap(find.text(PlaybackSpeed.x1.label));

        verify(
          () => bloc.add(const PlayerSpeedChanged(PlaybackSpeed.x1_25)),
        ).called(1);
      },
    );

    testWidgets(
      'GIVEN a paused episode '
      'WHEN the status changes to playing '
      'THEN the button shows pause',
      (tester) async {
        whenListen(
          bloc,
          Stream.value(const PlayerState(status: PlayerStatus.playing)),
          initialState: const PlayerState(status: PlayerStatus.paused),
        );
        await pumpWithBloc(tester);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        await tester.pump();

        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
      },
    );

    testWidgets(
      'GIVEN speed x1 '
      'WHEN the speed changes to x1_25 '
      'THEN the label shows the new speed',
      (tester) async {
        whenListen(
          bloc,
          Stream.value(const PlayerState(speed: PlaybackSpeed.x1_25)),
          initialState: const PlayerState(),
        );
        await pumpWithBloc(tester);
        expect(find.text(PlaybackSpeed.x1.label), findsOneWidget);

        await tester.pump();

        expect(find.text(PlaybackSpeed.x1_25.label), findsOneWidget);
        expect(find.text(PlaybackSpeed.x1.label), findsNothing);
      },
    );

    testWidgets(
      'GIVEN position 10 s '
      'WHEN tapping replay 30 '
      'THEN adds PlayerSeeked clamped at zero',
      (tester) async {
        await pumpControls(
          tester,
          const PlayerState(
            status: PlayerStatus.playing,
            position: PlayerPosition(
              position: Duration(seconds: 10),
              total: Duration(minutes: 5),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.replay_30));

        verify(() => bloc.add(const PlayerSeeked(Duration.zero))).called(1);
      },
    );

    testWidgets(
      'GIVEN position 4:50 of 5:00 '
      'WHEN tapping forward 30 '
      'THEN adds PlayerSeeked clamped at the episode length',
      (tester) async {
        await pumpControls(
          tester,
          const PlayerState(
            status: PlayerStatus.playing,
            position: PlayerPosition(
              position: Duration(minutes: 4, seconds: 50),
              total: Duration(minutes: 5),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.forward_30));

        verify(
          () => bloc.add(const PlayerSeeked(Duration(minutes: 5))),
        ).called(1);
      },
    );
  });
}
