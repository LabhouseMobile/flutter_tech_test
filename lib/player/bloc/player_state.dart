part of 'player_bloc.dart';

/// What the player screen shows. [errorMessage] is always set with
/// [PlayerStatus.error] (open failed); otherwise it is a failed action, shown
/// in a SnackBar.
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
