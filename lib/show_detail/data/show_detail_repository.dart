import 'package:cabina/discover/models/podcast.dart';
import 'package:cabina/show_detail/data/parsers/rss_feed_parser.dart';
import 'package:cabina/show_detail/data/services/rss_feed_service.dart';
import 'package:cabina/show_detail/models/podcast_detail.dart';

class ShowDetailRepository {
  ShowDetailRepository({
    required RssFeedService feedService,
    required RssFeedParser feedParser,
  }) : _feedService = feedService,
       _feedParser = feedParser;

  final RssFeedService _feedService;
  final RssFeedParser _feedParser;

  Future<PodcastDetail> loadDetail(Podcast podcast) async {
    final xml = await _feedService.fetchFeed(podcast.feedUrl);
    // If detail is too big, it would be better to run this into an isolate.
    return _feedParser.parse(xml, podcast);
  }
}
