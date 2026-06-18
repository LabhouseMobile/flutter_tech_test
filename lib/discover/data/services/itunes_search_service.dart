import 'dart:convert';

import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/common/network/api_client.dart';
import 'package:cabina/discover/models/podcast.dart';

/// Talks to the iTunes Search API. No API key required.
///
/// Docs: https://performance-partners.apple.com/search-api
class ItunesSearchService {
  ItunesSearchService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const _host = 'itunes.apple.com';

  Future<List<Podcast>> searchPodcasts(String term, {int limit = 50}) async {
    if (term.trim().isEmpty) return const [];
    final uri = Uri.https(_host, '/search', {
      'media': 'podcast',
      'entity': 'podcast',
      'term': term,
      'limit': '$limit',
    });

    final body = await _apiClient.getString(uri);
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final results = (decoded['results'] as List).cast<Map<String, dynamic>>();

    // Only collections with a usable feed URL can be opened.
    return results
        .where((json) => (json['feedUrl'] as String?)?.isNotEmpty ?? false)
        .map(Podcast.fromJson)
        .toList();
  }

  Future<Podcast?> lookupById(int collectionId) async {
    final uri = Uri.https(_host, '/lookup', {'id': '$collectionId'});
    final body = await _apiClient.getString(uri);
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final results = (decoded['results'] as List).cast<Map<String, dynamic>>();
    final match = results.where((j) => j['collectionId'] != null);
    if (match.isEmpty) throw const ApiException('Podcast not found');
    return Podcast.fromJson(match.first);
  }
}
