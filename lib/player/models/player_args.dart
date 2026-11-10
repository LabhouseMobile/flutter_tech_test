import 'package:cabina/show_detail/models/episode.dart';
import 'package:equatable/equatable.dart';

/// Everything the player screen needs to present and stream an episode.
class PlayerArgs extends Equatable {
  const PlayerArgs({
    required this.episode,
    required this.podcastTitle,
    required this.feedUrl,
    this.artworkUrl,
  });

  final Episode episode;
  final String podcastTitle;

  /// The show's RSS feed. With the episode's `guid` it identifies the episode
  /// across podcasts.
  final String feedUrl;

  final String? artworkUrl;

  @override
  List<Object?> get props => [episode, podcastTitle, feedUrl, artworkUrl];
}
