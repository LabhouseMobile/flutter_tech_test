import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/player/bloc/audio_player_bloc.dart';
import 'package:cabina/player/data/audio_player_repository.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
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
}
