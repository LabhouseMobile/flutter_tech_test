import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/common/network/api_client.dart';

/// Downloads a podcast's raw RSS feed. Parsing lives in `RssFeedParser`.
class RssFeedService {
  RssFeedService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Returns the raw XML at [feedUrl].
  ///
  /// Throws an [ApiException] without a status code when [feedUrl] cannot be
  /// parsed as a URI, before any request is made.
  Future<String> fetchFeed(String feedUrl) async {
    final uri = Uri.tryParse(feedUrl.trim());
    if (uri == null) {
      throw const ApiException('This podcast has an invalid feed URL');
    }
    return _apiClient.getString(uri);
  }
}
