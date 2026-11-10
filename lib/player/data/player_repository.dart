import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';

/// Audio playback for one episode at a time, so the bloc never depends on the
/// audio engine.
abstract interface class PlayerRepository {
  Stream<PlayerPosition> get positionStream;
  Stream<PlayerStatus> get statusStream;

  /// Loads [url] and returns its total duration when known.
  Future<Duration?> open(String url);

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}
