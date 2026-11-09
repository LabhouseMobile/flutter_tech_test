/// The audio engine's state as the player shows it, plus [error] when an
/// episode can't be opened.
enum PlayerStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error
  ;

  bool get isPlaying => this == PlayerStatus.playing;
  bool get isBusy =>
      this == PlayerStatus.loading || this == PlayerStatus.buffering;
}
