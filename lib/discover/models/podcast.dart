import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'podcast.g.dart';

/// A podcast as returned by the iTunes Search API.
@JsonSerializable(createToJson: false)
class Podcast extends Equatable {
  const Podcast({
    required this.id,
    required this.title,
    required this.author,
    required this.feedUrl,
    this.artworkUrl,
    this.genre,
    this.episodeCount,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) =>
      _$PodcastFromJson(json);

  @JsonKey(name: 'collectionId')
  final int id;

  @JsonKey(name: 'collectionName')
  final String title;

  @JsonKey(name: 'artistName')
  final String author;

  final String feedUrl;

  /// iTunes usually returns 600px artwork, but some collections omit it.
  @JsonKey(name: 'artworkUrl600')
  final String? artworkUrl;

  @JsonKey(name: 'primaryGenreName')
  final String? genre;

  @JsonKey(name: 'trackCount')
  final int? episodeCount;

  @override
  List<Object?> get props => [id, title, author, feedUrl, artworkUrl, genre];
}
