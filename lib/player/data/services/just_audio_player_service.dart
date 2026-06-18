import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/player/data/services/i_player_service.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:just_audio/just_audio.dart';

class JustAudioPlayerService implements IPlayerService {
  JustAudioPlayerService({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<PlayerPosition> get positionStream => _player.positionStream.map(
        (position) => PlayerPosition(
          position: position,
          buffered: _player.bufferedPosition,
          total: _player.duration,
        ),
      );

  @override
  Stream<PlayerStatus> get statusStream =>
      _player.playerStateStream.map(_mapStatus);

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
  Future<Duration?> open(String url) async {
    try {
      return await _player.setUrl(url);
    } on PlayerException catch (e) {
      throw CabinaPlayerException('Could not load audio', cause: e);
    } catch (e) {
      throw CabinaPlayerException('Unexpected player error', cause: e);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() => _player.dispose();
}
