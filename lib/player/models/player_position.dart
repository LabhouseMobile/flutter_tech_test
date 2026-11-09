import 'package:equatable/equatable.dart';

/// Playback progress: elapsed, buffered and, once the engine knows it, total.
class PlayerPosition extends Equatable {
  const PlayerPosition({
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.total,
  });

  final Duration position;
  final Duration buffered;
  final Duration? total;

  @override
  List<Object?> get props => [position, buffered, total];
}
