import 'package:equatable/equatable.dart';

class PlayerPosition extends Equatable {
  const PlayerPosition({
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.total,
  });

  final Duration position;
  final Duration buffered;
  final Duration? total;

  double get progress {
    final t = total;
    if (t == null || t.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / t.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [position, buffered, total];
}
