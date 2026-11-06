/// Parses the `<itunes:duration>` tag of a podcast RSS item.
///
/// - `S`: plain seconds, e.g. `3725`, `1834.5`
/// - `M:SS` / `MM:SS`, e.g. `5:07`, `45:30`
/// - `H:MM:SS` / `HH:MM:SS`, e.g. `1:02:03`, `01:02:03.5`
abstract final class ItunesDurationParser {
  static final _wholeNumber = RegExp(r'^\d+$');
  static final _decimalNumber = RegExp(r'^\d+(\.\d+)?$');

  /// Returns the duration in [raw], or `null` when [raw] is missing,
  /// malformed or zero (a zero duration is a publisher mistake).
  ///
  /// Never throws.
  static Duration? tryParse(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final parts = trimmed.split(':');
    if (parts.length > 3) return null;

    final leading = parts.sublist(0, parts.length - 1);
    if (!leading.every(_wholeNumber.hasMatch) ||
        !_decimalNumber.hasMatch(parts.last)) {
      return null;
    }

    // ((h * 60) + m) * 60 + s
    var totalSeconds = 0.0;
    for (final part in parts) {
      totalSeconds = totalSeconds * 60 + double.parse(part);
    }
    if (!totalSeconds.isFinite) return null;

    final rounded = totalSeconds.round();
    return rounded == 0 ? null : Duration(seconds: rounded);
  }
}
