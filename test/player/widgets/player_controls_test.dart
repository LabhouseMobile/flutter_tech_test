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

  Future<void> pumpControls(
    WidgetTester tester,
    PlayerState state,
  ) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme(isDark: false).toThemeData(),
        home: Scaffold(
          body: BlocProvider<PlayerBloc>.value(
            value: bloc,
            child: PlayerControls(
              status: state.status,
              speed: state.speed,
              position: state.position,
            ),
          ),
        ),
      ),
    );
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
  });
}
