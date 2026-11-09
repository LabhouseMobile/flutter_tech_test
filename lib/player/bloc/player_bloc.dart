import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/player/data/player_repository.dart';
import 'package:cabina/player/models/playback_speed.dart';
import 'package:cabina/player/models/player_args.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:equatable/equatable.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc({required PlayerRepository repository})
    : _repository = repository,
      super(const PlayerState()) {
    on<PlayerOpened>(_onOpened);
    on<PlayerPlayPauseToggled>(_onPlayPauseToggled);
    on<PlayerSeeked>(_onSeeked);
    on<PlayerSpeedChanged>(_onSpeedChanged);
    on<PlayerPositionUpdated>(_onPositionUpdated);
    on<PlayerStatusUpdated>(_onStatusUpdated);

    _positionSub = _repository.positionStream.listen(
      (position) => add(PlayerPositionUpdated(position)),
      onError: addError,
    );
    _statusSub = _repository.statusStream.listen(
      (status) => add(PlayerStatusUpdated(status)),
      onError: addError,
    );
  }

  final PlayerRepository _repository;

  late final StreamSubscription<PlayerPosition> _positionSub;
  late final StreamSubscription<PlayerStatus> _statusSub;

  Future<void> _onOpened(
    PlayerOpened event,
    Emitter<PlayerState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PlayerStatus.loading,
        args: event.args,
        clearError: true,
      ),
    );
    try {
      final total = await _repository.open(event.args.episode.audioUrl);
      emit(
        state.copyWith(
          position: PlayerPosition(total: total ?? event.args.episode.duration),
        ),
      );
      await _repository.play();
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: PlayerStatus.error,
          errorMessage: CabinaException.messageOf(error),
        ),
      );
    }
  }

  Future<void> _onPlayPauseToggled(
    PlayerPlayPauseToggled event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.status.isPlaying) {
      await _repository.pause();
    } else {
      await _repository.play();
    }
  }

  Future<void> _onSeeked(
    PlayerSeeked event,
    Emitter<PlayerState> emit,
  ) async {
    await _repository.seekTo(event.position);
  }

  Future<void> _onSpeedChanged(
    PlayerSpeedChanged event,
    Emitter<PlayerState> emit,
  ) async {
    await _repository.setSpeed(event.speed.value);
    emit(state.copyWith(speed: event.speed));
  }

  void _onPositionUpdated(
    PlayerPositionUpdated event,
    Emitter<PlayerState> emit,
  ) {
    final total = event.position.total ?? state.position.total;
    emit(
      state.copyWith(
        position: PlayerPosition(
          position: event.position.position,
          buffered: event.position.buffered,
          total: total,
        ),
      ),
    );
  }

  void _onStatusUpdated(
    PlayerStatusUpdated event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(status: event.status));
  }

  /// Closes the bloc first so no new event reaches a disposed player, and
  /// always disposes the repository this bloc owns, even if closing fails.
  @override
  Future<void> close() async {
    await _positionSub.cancel();
    await _statusSub.cancel();
    try {
      await super.close();
    } finally {
      await _repository.dispose();
    }
  }
}
