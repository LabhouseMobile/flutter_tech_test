extension DurationFormat on Duration {
  /// `1:02:03` for >= 1h, otherwise `2:03`.
  String get clock {
    final h = inHours;
    final m = inMinutes.remainder(60);
    final s = inSeconds.remainder(60);
    final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  /// Human label such as `1h 2m` or `43m`.
  String get human {
    final h = inHours;
    final m = inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
