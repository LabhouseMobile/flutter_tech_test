import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/player/data/services/just_audio_player_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  setUpAll(() => registerFallbackValue(Duration.zero));

  late _MockAudioPlayer player;
  late JustAudioPlayerService service;
  final engineError = PlayerException(1, 'engine failed');

  setUp(() {
    player = _MockAudioPlayer();
    service = JustAudioPlayerService(player: player);
  });

  Matcher mapsEngineError() => throwsA(
    isA<CabinaPlayerException>().having(
      (e) => e.cause,
      'cause',
      same(engineError),
    ),
  );

  Matcher emitsPlaybackFailed() => emitsError(
    isA<CabinaPlayerException>()
        .having((e) => e.message, 'message', 'Playback failed')
        .having((e) => e.cause, 'cause', same(engineError)),
  );

  group('JustAudioPlayerService', () {
    test(
      'GIVEN the engine fails to load '
      'WHEN open '
      'THEN throws a CabinaPlayerException with the original as cause',
      () {
        when(() => player.setUrl(any())).thenThrow(engineError);

        expect(service.open('https://example.com/a.mp3'), mapsEngineError());
      },
    );

    test(
      'GIVEN the engine fails to play '
      'WHEN play '
      'THEN throws a CabinaPlayerException with the original as cause',
      () {
        when(() => player.play()).thenThrow(engineError);

        expect(service.play(), mapsEngineError());
      },
    );

    test(
      'GIVEN the engine fails to pause '
      'WHEN pause '
      'THEN throws a CabinaPlayerException with the original as cause',
      () {
        when(() => player.pause()).thenThrow(engineError);

        expect(service.pause(), mapsEngineError());
      },
    );

    test(
      'GIVEN the engine fails to seek '
      'WHEN seekTo '
      'THEN throws a CabinaPlayerException with the original as cause',
      () {
        when(() => player.seek(any())).thenThrow(engineError);

        expect(service.seekTo(Duration.zero), mapsEngineError());
      },
    );

    test(
      'GIVEN the engine fails to change speed '
      'WHEN setSpeed '
      'THEN throws a CabinaPlayerException with the original as cause',
      () {
        when(() => player.setSpeed(any())).thenThrow(engineError);

        expect(service.setSpeed(2), mapsEngineError());
      },
    );

    test(
      'GIVEN the engine position stream fails '
      'WHEN listening to positionStream '
      'THEN emits a CabinaPlayerException with the original as cause',
      () {
        when(
          () => player.positionStream,
        ).thenAnswer((_) => Stream.error(engineError));

        expect(service.positionStream, emitsPlaybackFailed());
      },
    );

    test(
      'GIVEN the engine state stream fails '
      'WHEN listening to statusStream '
      'THEN emits a CabinaPlayerException with the original as cause',
      () {
        when(
          () => player.playerStateStream,
        ).thenAnswer((_) => Stream.error(engineError));

        expect(service.statusStream, emitsPlaybackFailed());
      },
    );
  });
}
