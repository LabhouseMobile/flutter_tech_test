part of 'player_bloc.dart';

class PlayerState extends Equatable {
  const PlayerState({
    this.status = PlayerStatus.idle,
    this.position = const PlayerPosition(),
    this.speed = PlaybackSpeed.x1,
    this.args,
    this.errorMessage,
  });

  final PlayerStatus status;
  final PlayerPosition position;
  final PlaybackSpeed speed;
  final PlayerArgs? args;
  final String? errorMessage;

  PlayerState copyWith({
    PlayerStatus? status,
    PlayerPosition? position,
    PlaybackSpeed? speed,
    PlayerArgs? args,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      speed: speed ?? this.speed,
      args: args ?? this.args,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, position, speed, args, errorMessage];
}
