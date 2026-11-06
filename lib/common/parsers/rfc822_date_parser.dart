import 'package:intl/intl.dart';

/// Parses the RFC 822 dates used by RSS `<pubDate>`, e.g.
/// `Wed, 02 Oct 2024 08:00:00 GMT` or `1 Oct 2024 08:00:00 -0500`.
///
/// Accepted:
///
/// - an optional weekday followed by a comma (it is ignored)
/// - a 1 or 2 digit day, an English short month and a 4 digit year
/// - `HH:mm:ss`
/// - a zone that is `GMT`, `UT`, `UTC`, `Z` or a numeric `+HHMM` / `-HHMM`
///
/// If the input is not RFC 822, the parser falls back to
/// [DateTime.tryParse] (ISO 8601).
abstract final class Rfc822DateParser {
  static final _format = DateFormat('d MMM yyyy HH:mm:ss', 'en_US');
  static final _numericZone = RegExp(r'^([+-])(\d{2})(\d{2})$');
  static const Map<String, Duration> _namedZones = {
    'GMT': Duration.zero,
    'UT': Duration.zero,
    'UTC': Duration.zero,
    'Z': Duration.zero,
  };

  /// Returns the instant in [raw] as a UTC [DateTime], or `null` when [raw]
  /// is missing or cannot be parsed.
  ///
  /// Never throws.
  static DateTime? tryParse(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return _tryParseRfc822(trimmed) ?? DateTime.tryParse(trimmed);
  }

  static DateTime? _tryParseRfc822(String input) {
    // Drop the optional "Wed," weekday.
    final comma = input.indexOf(',');
    final withoutWeekday = comma == -1 ? input : input.substring(comma + 1);

    final tokens = withoutWeekday.trim().split(RegExp(r'\s+'));
    if (tokens.length < 2) return null;

    final offset = _parseZone(tokens.removeLast());
    if (offset == null) return null;

    final DateTime local;
    try {
      local = _format.parseStrict(tokens.join(' '), true);
    } on FormatException {
      return null;
    }
    return local.subtract(offset);
  }

  /// The zone's offset from UTC, or `null` if the zone is not accepted.
  static Duration? _parseZone(String zone) {
    final named = _namedZones[zone.toUpperCase()];
    if (named != null) return named;

    final match = _numericZone.firstMatch(zone);
    if (match == null) return null;
    final sign = match[1] == '-' ? -1 : 1;
    return Duration(
          hours: int.parse(match[2]!),
          minutes: int.parse(match[3]!),
        ) *
        sign;
  }
}
