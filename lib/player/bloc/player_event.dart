part of 'player_bloc.dart';

/// Everything [PlayerBloc] reacts to: user actions and engine updates.
sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

/// Load [args]'s episode and start playing it.
class PlayerOpened extends PlayerEvent {
  const PlayerOpened(this.args);

  final PlayerArgs args;

  @override
  List<Object?> get props => [args];
}

/// Pause when playing, play otherwise.
class PlayerPlayPauseToggled extends PlayerEvent {
  const PlayerPlayPauseToggled();
}

/// Jump to [position].
class PlayerSeeked extends PlayerEvent {
  const PlayerSeeked(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

/// Play at [speed].
class PlayerSpeedChanged extends PlayerEvent {
  const PlayerSpeedChanged(this.speed);

  final PlaybackSpeed speed;

  @override
  List<Object?> get props => [speed];
}

/// The engine reported a new position.
class PlayerPositionUpdated extends PlayerEvent {
  const PlayerPositionUpdated(this.position);

  final PlayerPosition position;

  @override
  List<Object?> get props => [position];
}

/// The engine reported a new status.
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
