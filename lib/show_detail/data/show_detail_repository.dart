import 'package:cabina/discover/models/podcast.dart';
import 'package:cabina/show_detail/data/services/rss_feed_service.dart';
import 'package:cabina/show_detail/models/podcast_detail.dart';

class ShowDetailRepository {
  ShowDetailRepository({required RssFeedService feedService})
      : _feedService = feedService;

  final RssFeedService _feedService;

  Future<PodcastDetail> loadDetail(Podcast podcast) =>
      _feedService.fetchDetail(podcast);
}
