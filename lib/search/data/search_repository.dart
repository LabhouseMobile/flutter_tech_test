import 'package:cabina/discover/data/services/itunes_search_service.dart';
import 'package:cabina/discover/models/podcast.dart';

class SearchRepository {
  SearchRepository({required ItunesSearchService searchService})
      : _searchService = searchService;

  final ItunesSearchService _searchService;

  Future<List<Podcast>> search(String term) =>
      _searchService.searchPodcasts(term);
}
