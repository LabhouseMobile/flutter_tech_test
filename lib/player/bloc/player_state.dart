part of 'player_bloc.dart';

class PlayerState extends Equatable {
  const PlayerState({
    this.status = PlayerStatus.idle,
    this.position = const PlayerPosition(),
    this.speed = PlaybackSpeed.x1,
    this.errorMessage,
  });

  final PlayerStatus status;
  final PlayerPosition position;
  final PlaybackSpeed speed;
  final String? errorMessage;

  PlayerState copyWith({
    PlayerStatus? status,
    PlayerPosition? position,
    PlaybackSpeed? speed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      speed: speed ?? this.speed,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, position, speed, errorMessage];
}
