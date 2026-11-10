import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/player/bloc/player_bloc.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:cabina/player/widgets/seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const PlayerSeeked(Duration.zero)));

  const playing = PlayerState(
    status: PlayerStatus.playing,
    position: PlayerPosition(total: Duration(minutes: 5)),
  );

  late _MockPlayerBloc bloc;
  late StreamController<PlayerState> states;

  setUp(() {
    bloc = _MockPlayerBloc();
    states = StreamController<PlayerState>();
  });

  tearDown(() => states.close());

  Future<void> pumpSeekBar(
    WidgetTester tester, {
    PlayerState initialState = playing,
  }) {
    whenListen(bloc, states.stream, initialState: initialState);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme(isDark: false).toThemeData(),
        home: Scaffold(
          body: BlocProvider<PlayerBloc>.value(
            value: bloc,
            child: const SeekBar(),
          ),
        ),
      ),
    );
  }

  double sliderValue(WidgetTester tester) =>
      tester.widget<Slider>(find.byType(Slider)).value;

  /// Sends a position tick and settles: after a drag the Slider is still
  /// animating, and a bare `pump()` would build before the tick lands.
  Future<void> tick(WidgetTester tester, Duration position) {
    states.add(
      PlayerState(
        status: PlayerStatus.playing,
        position: PlayerPosition(
          position: position,
          total: const Duration(minutes: 5),
        ),
      ),
    );
    return tester.pumpAndSettle();
  }

  group('SeekBar', () {
    testWidgets(
      'GIVEN a 5 min episode '
      'WHEN dragging the slider '
      'THEN adds exactly one PlayerSeeked, on release',
      (tester) async {
        await pumpSeekBar(tester);

        await tester.drag(find.byType(Slider), const Offset(200, 0));
        await tester.pump();

        verify(() => bloc.add(any(that: isA<PlayerSeeked>()))).called(1);
      },
    );

    testWidgets(
      'GIVEN a drag in progress '
      'WHEN a position tick arrives '
      'THEN the thumb keeps the drag value',
      (tester) async {
        await pumpSeekBar(tester);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Slider)),
        );
        await gesture.moveBy(const Offset(100, 0));
        await tester.pump();
        final dragged = sliderValue(tester);

        await tick(tester, const Duration(seconds: 1));

        expect(dragged, greaterThan(0));
        expect(sliderValue(tester), dragged);
        await gesture.up();
      },
    );

    testWidgets(
      'GIVEN a finished drag '
      'WHEN no position tick has arrived yet '
      'THEN the thumb stays where it was released',
      (tester) async {
        await pumpSeekBar(tester);

        await tester.drag(find.byType(Slider), const Offset(100, 0));
        await tester.pump();

        final released = sliderValue(tester);
        expect(released, greaterThan(0));
        verify(
          () =>
              bloc.add(PlayerSeeked(Duration(milliseconds: released.round()))),
        ).called(1);
      },
    );

    testWidgets(
      'GIVEN a finished drag '
      'WHEN a position tick arrives '
      'THEN the thumb follows the tick again',
      (tester) async {
        await pumpSeekBar(tester);
        await tester.drag(find.byType(Slider), const Offset(100, 0));
        await tester.pump();

        await tick(tester, const Duration(seconds: 1));

        expect(sliderValue(tester), 1000);
      },
    );

    testWidgets(
      'GIVEN an episode of unknown length '
      'WHEN dragging the slider '
      'THEN the slider is disabled and adds no PlayerSeeked',
      (tester) async {
        await pumpSeekBar(
          tester,
          initialState: const PlayerState(status: PlayerStatus.playing),
        );

        await tester.drag(find.byType(Slider), const Offset(100, 0));
        await tester.pump();

        expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
        verifyNever(() => bloc.add(any()));
      },
    );
  });
}
