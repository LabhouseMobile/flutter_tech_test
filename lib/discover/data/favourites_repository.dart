import 'dart:convert';

import 'package:cabina/common/storage/local_storage.dart';

/// Persists the set of "liked" podcast ids. Favourites are a lightweight
/// bookmark from the discover/search screens (distinct from Library
/// subscriptions).
class FavouritesRepository {
  FavouritesRepository({required LocalStorage localStorage})
    : _localStorage = localStorage;

  final LocalStorage _localStorage;

  static const _key = 'favourite_podcast_ids';

  /// The saved ids. Throws when the stored value isn't a JSON list of ints.
  Future<List<int>> load() async {
    final raw = await _localStorage.read(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List;
    return List<int>.from(decoded);
  }

  Future<void> save(List<int> ids) =>
      _localStorage.write(_key, jsonEncode(ids));
}
