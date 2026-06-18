import 'package:cabina/player/data/services/i_player_service.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';

class AudioPlayerRepository {
  AudioPlayerRepository({required IPlayerService service}) : _service = service;

  final IPlayerService _service;

  Stream<PlayerPosition> get positionStream => _service.positionStream;
  Stream<PlayerStatus> get statusStream => _service.statusStream;

  Future<Duration?> open(String url) => _service.open(url);
  Future<void> play() => _service.play();
  Future<void> pause() => _service.pause();
  Future<void> seekTo(Duration position) => _service.seekTo(position);
  Future<void> setSpeed(double speed) => _service.setSpeed(speed);
  Future<void> dispose() => _service.dispose();
}
