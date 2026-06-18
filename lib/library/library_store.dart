import 'package:cabina/library/subscribed_podcast.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Quick-and-dirty persistence for the Library feature.
//
// Subscriptions are stored in a single SharedPreferences string: each podcast
// is "id|title|author|artwork" and entries are joined with ";". It works for
// the demo. Not wired through a repository/cubit like the rest of the app.
class LibraryStore {
  LibraryStore._();

  static final LibraryStore instance = LibraryStore._();

  static const _key = 'library_subscriptions';

  final List<SubscribedPodcast> _items = [];
  bool _loaded = false;

  List<SubscribedPodcast> get items => _items;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '';
    _items.clear();
    if (raw.isNotEmpty) {
      for (final entry in raw.split(';')) {
        final parts = entry.split('|');
        _items.add(
          SubscribedPodcast(
            id: int.parse(parts[0]),
            title: parts[1],
            author: parts[2],
            artworkUrl: parts[3].isEmpty ? null : parts[3],
          ),
        );
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _items
        .map((p) => '${p.id}|${p.title}|${p.author}|${p.artworkUrl ?? ''}')
        .join(';');
    await prefs.setString(_key, raw);
  }

  bool isSubscribed(int id) {
    for (final item in _items) {
      if (item.id == id) return true;
    }
    return false;
  }

  Future<void> subscribe(SubscribedPodcast podcast) async {
    if (!isSubscribed(podcast.id)) {
      _items.add(podcast);
      await _persist();
    }
  }

  Future<void> unsubscribe(int id) async {
    _items.removeWhere((p) => p.id == id);
    await _persist();
  }
}
