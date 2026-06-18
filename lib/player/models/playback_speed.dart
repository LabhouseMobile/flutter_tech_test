enum PlaybackSpeed {
  x0_75(0.75, '0.75×'),
  x1(1, '1×'),
  x1_25(1.25, '1.25×'),
  x1_5(1.5, '1.5×'),
  x2(2, '2×');

  const PlaybackSpeed(this.value, this.label);

  final double value;
  final String label;

  PlaybackSpeed get next {
    const values = PlaybackSpeed.values;
    return values[(index + 1) % values.length];
  }
}
