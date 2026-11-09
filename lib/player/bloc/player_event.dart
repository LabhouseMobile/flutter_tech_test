part of 'player_bloc.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerOpened extends PlayerEvent {
  const PlayerOpened(this.args);

  final PlayerArgs args;

  @override
  List<Object?> get props => [args];
}

class PlayerPlayPauseToggled extends PlayerEvent {
  const PlayerPlayPauseToggled();
}

class PlayerSeeked extends PlayerEvent {
  const PlayerSeeked(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

class PlayerSpeedChanged extends PlayerEvent {
  const PlayerSpeedChanged(this.speed);

  final PlaybackSpeed speed;

  @override
  List<Object?> get props => [speed];
}

class PlayerPositionUpdated extends PlayerEvent {
  const PlayerPositionUpdated(this.position);

  final PlayerPosition position;

  @override
  List<Object?> get props => [position];
}

class PlayerStatusUpdated extends PlayerEvent {
  const PlayerStatusUpdated(this.status);

  final PlayerStatus status;

  @override
  List<Object?> get props => [status];
}

/// An engine stream or `play()` failed outside a handler.
class _PlayerFailed extends PlayerEvent {
  const _PlayerFailed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  List<Object?> get props => [error, stackTrace];
}
