import 'dart:async';

import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/player/data/player_repository.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:just_audio/just_audio.dart';

class JustAudioPlayerService implements PlayerRepository {
  JustAudioPlayerService({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<PlayerPosition> get positionStream => _guardStream(
    _player.positionStream.map(
      (position) => PlayerPosition(
        position: position,
        buffered: _player.bufferedPosition,
        total: _player.duration,
      ),
    ),
  );

  @override
  Stream<PlayerStatus> get statusStream =>
      _guardStream(_player.playerStateStream.map(_mapStatus));

  PlayerStatus _mapStatus(PlayerState state) {
    switch (state.processingState) {
      case ProcessingState.idle:
        return PlayerStatus.idle;
      case ProcessingState.loading:
        return PlayerStatus.loading;
      case ProcessingState.buffering:
        return PlayerStatus.buffering;
      case ProcessingState.ready:
        return state.playing ? PlayerStatus.playing : PlayerStatus.paused;
      case ProcessingState.completed:
        return PlayerStatus.completed;
    }
  }

  @override
  Future<Duration?> open(String url) =>
      _guard('Could not load audio', () => _player.setUrl(url));

  /// Completes when playback stops, not when it starts: just_audio's `play()`
  /// does the same.
  @override
  Future<void> play() => _guard('Could not play', _player.play);

  @override
  Future<void> pause() => _guard('Could not pause', _player.pause);

  @override
  Future<void> seekTo(Duration position) =>
      _guard('Could not seek', () => _player.seek(position));

  @override
  Future<void> setSpeed(double speed) =>
      _guard('Could not change speed', () => _player.setSpeed(speed));

  @override
  Future<void> dispose() => _player.dispose();

  /// Runs an engine call and maps its failure to [CabinaPlayerException],
  /// keeping the original as `cause`.
  Future<T> _guard<T>(String message, Future<T> Function() call) async {
    try {
      return await call();
    } on PlayerException catch (error) {
      throw CabinaPlayerException(message, cause: error);
    } on Object catch (error) {
      throw CabinaPlayerException('Unexpected player error', cause: error);
    }
  }

  /// Maps an engine stream error to [CabinaPlayerException], keeping the
  /// original as `cause`, as [_guard] does for calls.
  Stream<T> _guardStream<T>(Stream<T> stream) => stream.transform(
    StreamTransformer<T, T>.fromHandlers(
      handleError: (error, stackTrace, sink) => sink.addError(
        CabinaPlayerException('Playback failed', cause: error),
        stackTrace,
      ),
    ),
  );
}
