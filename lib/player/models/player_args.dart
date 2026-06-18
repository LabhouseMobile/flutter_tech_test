import 'package:cabina/show_detail/models/episode.dart';
import 'package:equatable/equatable.dart';

/// Everything the player screen needs to present and stream an episode.
class PlayerArgs extends Equatable {
  const PlayerArgs({
    required this.episode,
    required this.podcastTitle,
    this.artworkUrl,
  });

  final Episode episode;
  final String podcastTitle;
  final String? artworkUrl;

  @override
  List<Object?> get props => [episode, podcastTitle, artworkUrl];
}
