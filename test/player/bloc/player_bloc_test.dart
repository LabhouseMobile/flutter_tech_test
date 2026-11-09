import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/player/bloc/player_bloc.dart';
import 'package:cabina/player/data/player_repository.dart';
import 'package:cabina/player/models/playback_speed.dart';
import 'package:cabina/player/models/player_args.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:cabina/show_detail/models/episode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements PlayerRepository {}

void main() {
  setUpAll(() => registerFallbackValue(Duration.zero));

  late _MockRepository repository;
  late StreamController<PlayerPosition> positionController;
  late StreamController<PlayerStatus> statusController;

  setUp(() {
    repository = _MockRepository();
    positionController = StreamController<PlayerPosition>();
    statusController = StreamController<PlayerStatus>();
    when(
      () => repository.positionStream,
    ).thenAnswer((_) => positionController.stream);
    when(
      () => repository.statusStream,
    ).thenAnswer((_) => statusController.stream);
    when(() => repository.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await positionController.close();
    await statusController.close();
  });

  PlayerBloc buildBloc() => PlayerBloc(repository: repository);

  group('PlayerBloc close', () {
    blocTest<PlayerBloc, PlayerState>(
      'GIVEN a player bloc '
      'WHEN it is closed '
      'THEN disposes the audio repository exactly once',
      build: buildBloc,
      expect: () => const <PlayerState>[],
      verify: (_) => verify(() => repository.dispose()).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN a player bloc listening to the repository streams '
      'WHEN it is closed '
      'THEN cancels both stream subscriptions',
      build: buildBloc,
      verify: (_) {
        expect(positionController.hasListener, isFalse);
        expect(statusController.hasListener, isFalse);
      },
    );

    test(
      'GIVEN the repository fails to dispose '
      'WHEN the bloc is closed '
      'THEN the bloc still ends up closed and surfaces the error',
      () async {
        when(
          () => repository.dispose(),
        ).thenAnswer((_) async => throw Exception('dispose failed'));
        final bloc = buildBloc();

        await expectLater(bloc.close(), throwsException);

        expect(bloc.isClosed, isTrue);
      },
    );
  });

  const episode = Episode(
    guid: 'guid-1',
    title: 'Episode 1',
    audioUrl: 'https://example.com/audio.mp3',
    duration: Duration(minutes: 5),
  );
  const args = PlayerArgs(
    episode: episode,
    podcastTitle: 'Podcast Title',
  );

  group('PlayerBloc PlayerOpened', () {
    blocTest<PlayerBloc, PlayerState>(
      'GIVEN a previous error '
      'WHEN PlayerOpened '
      'THEN the loading state has no errorMessage',
      build: () {
        when(
          () => repository.open(any()),
        ).thenAnswer((_) async => const Duration(minutes: 5));
        when(() => repository.play()).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const PlayerState(
        status: PlayerStatus.error,
        errorMessage: 'playback failed',
      ),
      act: (bloc) => bloc.add(const PlayerOpened(args)),
      expect: () => const [
        PlayerState(
          status: PlayerStatus.loading,
        ),
        PlayerState(
          status: PlayerStatus.loading,
          position: PlayerPosition(total: Duration(minutes: 5)),
        ),
      ],
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN the repository throws a CabinaException '
      'WHEN PlayerOpened '
      'THEN emits [loading, error] with the exception message',
      build: () {
        when(
          () => repository.open(any()),
        ).thenThrow(const CabinaPlayerException('corrupt file'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PlayerOpened(args)),
      errors: () => [isA<CabinaPlayerException>()],
      expect: () => const [
        PlayerState(
          status: PlayerStatus.loading,
        ),
        PlayerState(
          status: PlayerStatus.error,
          errorMessage: 'corrupt file',
        ),
      ],
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN the repository throws a StateError '
      'WHEN PlayerOpened '
      'THEN emits error with CabinaException.fallbackMessage',
      build: () {
        when(
          () => repository.open(any()),
        ).thenThrow(StateError('unexpected'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PlayerOpened(args)),
      errors: () => [isA<StateError>()],
      expect: () => const [
        PlayerState(
          status: PlayerStatus.loading,
        ),
        PlayerState(
          status: PlayerStatus.error,
          errorMessage: CabinaException.fallbackMessage,
        ),
      ],
    );
  });

  group('PlayerBloc actions', () {
    blocTest<PlayerBloc, PlayerState>(
      'GIVEN status playing '
      'WHEN PlayerPlayPauseToggled '
      'THEN pauses the repository',
      build: () {
        when(() => repository.pause()).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const PlayerState(status: PlayerStatus.playing),
      act: (bloc) => bloc.add(const PlayerPlayPauseToggled()),
      verify: (_) {
        verify(() => repository.pause()).called(1);
        verifyNever(() => repository.play());
      },
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN status paused '
      'WHEN PlayerPlayPauseToggled '
      'THEN plays the repository',
      build: () {
        when(() => repository.play()).thenAnswer((_) async {});
        return buildBloc();
      },
      seed: () => const PlayerState(status: PlayerStatus.paused),
      act: (bloc) => bloc.add(const PlayerPlayPauseToggled()),
      verify: (_) {
        verify(() => repository.play()).called(1);
        verifyNever(() => repository.pause());
      },
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN a player bloc '
      'WHEN PlayerSeeked '
      'THEN seeks the repository to that position',
      build: () {
        when(() => repository.seekTo(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PlayerSeeked(Duration(minutes: 1))),
      verify: (_) =>
          verify(() => repository.seekTo(const Duration(minutes: 1))).called(1),
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN speed x1 '
      'WHEN PlayerSpeedChanged to x1_25 '
      'THEN sets 1.25 on the repository and emits the new speed',
      build: () {
        when(() => repository.setSpeed(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PlayerSpeedChanged(PlaybackSpeed.x1_25)),
      expect: () => const [PlayerState(speed: PlaybackSpeed.x1_25)],
      verify: (_) => verify(() => repository.setSpeed(1.25)).called(1),
    );
  });

  group('PlayerBloc streams', () {
    blocTest<PlayerBloc, PlayerState>(
      'GIVEN a known total '
      'WHEN the position stream emits without a total '
      'THEN keeps the known total',
      build: buildBloc,
      seed: () => const PlayerState(
        position: PlayerPosition(total: Duration(minutes: 5)),
      ),
      act: (_) => positionController.add(
        const PlayerPosition(
          position: Duration(minutes: 1),
          buffered: Duration(minutes: 2),
        ),
      ),
      expect: () => const [
        PlayerState(
          position: PlayerPosition(
            position: Duration(minutes: 1),
            buffered: Duration(minutes: 2),
            total: Duration(minutes: 5),
          ),
        ),
      ],
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN a player bloc '
      'WHEN the status stream emits playing '
      'THEN emits status playing',
      build: buildBloc,
      act: (_) => statusController.add(PlayerStatus.playing),
      expect: () => const [PlayerState(status: PlayerStatus.playing)],
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN the status stream emits an error '
      'THEN it reaches errors',
      build: buildBloc,
      act: (_) => statusController.addError(StateError('status stream error')),
      errors: () => [isA<StateError>()],
    );

    blocTest<PlayerBloc, PlayerState>(
      'GIVEN the position stream emits an error '
      'THEN it reaches errors',
      build: buildBloc,
      act: (_) => positionController.addError(
        StateError('position stream error'),
      ),
      errors: () => [isA<StateError>()],
    );
  });
}
