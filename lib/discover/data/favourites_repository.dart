import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the set of "liked" podcast ids. Favourites are a lightweight
/// bookmark from the discover/search screens (distinct from Library
/// subscriptions).
class FavouritesRepository {
  FavouritesRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _key = 'favourite_podcast_ids';

  List<int> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<int>();
  }

  Future<void> save(List<int> ids) =>
      _prefs.setString(_key, jsonEncode(ids));
}
