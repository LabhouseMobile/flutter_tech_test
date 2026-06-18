part of 'audio_player_bloc.dart';

class AudioPlayerState extends Equatable {
  const AudioPlayerState({
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

  AudioPlayerState copyWith({
    PlayerStatus? status,
    PlayerPosition? position,
    PlaybackSpeed? speed,
    PlayerArgs? args,
    String? errorMessage,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      speed: speed ?? this.speed,
      args: args ?? this.args,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, position, speed, args, errorMessage];
}
