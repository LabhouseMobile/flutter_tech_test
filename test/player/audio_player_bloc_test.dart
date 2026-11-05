import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/player/bloc/audio_player_bloc.dart';
import 'package:cabina/player/data/audio_player_repository.dart';
import 'package:cabina/player/models/player_args.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:cabina/show_detail/models/episode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AudioPlayerRepository {}

void main() {
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

  AudioPlayerBloc buildBloc() => AudioPlayerBloc(repository: repository);

  group('AudioPlayerBloc close', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'GIVEN a player bloc '
      'WHEN it is closed '
      'THEN disposes the audio repository exactly once',
      build: buildBloc,
      expect: () => const <AudioPlayerState>[],
      verify: (_) => verify(() => repository.dispose()).called(1),
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
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

  group('AudioPlayerBloc PlayerOpened', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
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
      seed: () => const AudioPlayerState(
        status: PlayerStatus.error,
        errorMessage: 'playback failed',
      ),
      act: (bloc) => bloc.add(const PlayerOpened(args)),
      expect: () => const [
        AudioPlayerState(
          status: PlayerStatus.loading,
          args: args,
        ),
        AudioPlayerState(
          status: PlayerStatus.loading,
          args: args,
          position: PlayerPosition(total: Duration(minutes: 5)),
        ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
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
        AudioPlayerState(
          status: PlayerStatus.loading,
          args: args,
        ),
        AudioPlayerState(
          status: PlayerStatus.error,
          args: args,
          errorMessage: 'corrupt file',
        ),
      ],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
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
        AudioPlayerState(
          status: PlayerStatus.loading,
          args: args,
        ),
        AudioPlayerState(
          status: PlayerStatus.error,
          args: args,
          errorMessage: CabinaException.fallbackMessage,
        ),
      ],
    );
  });

  group('AudioPlayerBloc streams', () {
    blocTest<AudioPlayerBloc, AudioPlayerState>(
      'GIVEN the status stream emits an error '
      'THEN it reaches errors',
      build: buildBloc,
      act: (_) => statusController.addError(StateError('status stream error')),
      errors: () => [isA<StateError>()],
    );

    blocTest<AudioPlayerBloc, AudioPlayerState>(
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
