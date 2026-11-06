import 'dart:convert';

import 'package:cabina/common/storage/local_storage.dart';
import 'package:cabina/library/models/subscribed_podcast.dart';

/// Reads and writes the user's subscriptions as a JSON list in
/// [LocalStorage], and migrates the older `id|title|author|artwork` format.
class LibraryRepository {
  LibraryRepository({required LocalStorage localStorage})
    : _localStorage = localStorage;

  final LocalStorage _localStorage;

  static const _key = 'library_podcasts';

  /// Written by builds before the JSON format. Read only to migrate it.
  static const _legacyKey = 'library_subscriptions';

  /// The saved subscriptions, oldest first.
  ///
  /// Bad data is dropped instead of breaking the Library tab: a value that
  /// isn't a JSON list loads as `[]`, and each entry
  /// [SubscribedPodcast.fromJson] rejects is skipped.
  ///
  /// When only the legacy key exists, its entries are saved under the new key
  /// and the legacy key is deleted. A legacy entry without exactly four
  /// fields, an `int` id and a non-empty title and author is skipped. A
  /// failed write throws and keeps the legacy key for the next load.
  Future<List<SubscribedPodcast>> load() async {
    final raw = await _localStorage.read(_key);
    if (raw != null) return _decode(raw);

    final legacy = await _localStorage.read(_legacyKey);
    if (legacy == null) return const [];
    final podcasts = legacy.split(';').map(_tryParseLegacy).nonNulls.toList();
    await save(podcasts);
    await _localStorage.delete(_legacyKey);
    return podcasts;
  }

  Future<void> save(List<SubscribedPodcast> podcasts) => _localStorage.write(
    _key,
    jsonEncode([for (final podcast in podcasts) podcast.toJson()]),
  );

  List<SubscribedPodcast> _decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_tryParse)
        .nonNulls
        .toList();
  }

  SubscribedPodcast? _tryParse(Map<String, dynamic> json) {
    try {
      return SubscribedPodcast.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  /// One `id|title|author|artwork` entry (entries are joined with `;`). A
  /// title or author that held `|` or `;` split wrong when it was saved, so it
  /// can't be recovered: it fails the four-field check and is skipped.
  SubscribedPodcast? _tryParseLegacy(String entry) {
    if (entry.split('|') case [
      final idText,
      final title,
      final author,
      final artworkUrl,
    ]) {
      final id = int.tryParse(idText);
      if (id == null || title.isEmpty || author.isEmpty) return null;
      return SubscribedPodcast(
        id: id,
        title: title,
        author: author,
        artworkUrl: artworkUrl.isEmpty ? null : artworkUrl,
      );
    }
    return null;
  }
}
