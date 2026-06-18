import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';

/// Abstraction over the concrete audio backend so the bloc never depends on
/// `just_audio` directly (mirrors the audio_app's IPlayerService).
abstract class IPlayerService {
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
