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
    on<_PlayerFailed>(_onFailed);

    _positionSub = _repository.positionStream.listen(
      (position) => add(PlayerPositionUpdated(position)),
      onError: _fail,
    );
    _statusSub = _repository.statusStream.listen(
      (status) => add(PlayerStatusUpdated(status)),
      onError: _fail,
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
      _play();
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
    _clearError(emit);
    if (!state.status.isPlaying) {
      _play();
      return;
    }
    try {
      await _repository.pause();
    } on Object catch (error, stackTrace) {
      _emitFailure(error, stackTrace, emit);
    }
  }

  Future<void> _onSeeked(
    PlayerSeeked event,
    Emitter<PlayerState> emit,
  ) async {
    _clearError(emit);
    try {
      await _repository.seekTo(event.position);
    } on Object catch (error, stackTrace) {
      _emitFailure(error, stackTrace, emit);
    }
  }

  Future<void> _onSpeedChanged(
    PlayerSpeedChanged event,
    Emitter<PlayerState> emit,
  ) async {
    _clearError(emit);
    try {
      await _repository.setSpeed(event.speed.value);
      emit(state.copyWith(speed: event.speed));
    } on Object catch (error, stackTrace) {
      _emitFailure(error, stackTrace, emit);
    }
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

  /// Clears the previous action's error, so the same message can show again.
  /// Skipped without one: a bloc emits an equal state if it hasn't emitted yet.
  void _clearError(Emitter<PlayerState> emit) {
    if (state.errorMessage != null) emit(state.copyWith(clearError: true));
  }

  void _onFailed(_PlayerFailed event, Emitter<PlayerState> emit) =>
      _emitFailure(event.error, event.stackTrace, emit);

  /// Starts playback without waiting for it: the repository's `play()`
  /// completes only when playback stops. A failure arrives as [_PlayerFailed].
  void _play() => unawaited(_repository.play().catchError(_fail));

  /// Routes an error from outside a handler (engine streams, `play()`) through
  /// an event, so it can be emitted. Dropped once the bloc is closed: nobody is
  /// listening any more.
  void _fail(Object error, StackTrace stackTrace) {
    if (!isClosed) add(_PlayerFailed(error, stackTrace));
  }

  /// A failed action keeps the screen as it is: the status is left untouched
  /// and the page shows [PlayerState.errorMessage] in a SnackBar.
  void _emitFailure(
    Object error,
    StackTrace stackTrace,
    Emitter<PlayerState> emit,
  ) {
    addError(error, stackTrace);
    emit(state.copyWith(errorMessage: CabinaException.messageOf(error)));
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
