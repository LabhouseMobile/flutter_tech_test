import 'package:cabina/discover/data/services/itunes_search_service.dart';
import 'package:cabina/discover/models/podcast.dart';

class DiscoverRepository {
  DiscoverRepository({required ItunesSearchService searchService})
      : _searchService = searchService;

  final ItunesSearchService _searchService;

  /// A simple "featured" shelf — in a real app this would hit the charts
  /// endpoint; here we seed discovery from a popular term.
  Future<List<Podcast>> featured() =>
      _searchService.searchPodcasts('top shows');

  Future<List<Podcast>> search(String term) =>
      _searchService.searchPodcasts(term);
}
