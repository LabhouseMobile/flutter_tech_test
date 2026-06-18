enum PlayerStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error;

  bool get isPlaying => this == PlayerStatus.playing;
  bool get isBusy =>
      this == PlayerStatus.loading || this == PlayerStatus.buffering;
}
