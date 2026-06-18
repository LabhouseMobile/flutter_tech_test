import 'package:equatable/equatable.dart';

/// A single episode parsed from a podcast's RSS feed.
class Episode extends Equatable {
  const Episode({
    required this.guid,
    required this.title,
    required this.audioUrl,
    this.descriptionHtml = '',
    this.duration,
    this.publishedAt,
    this.imageUrl,
  });

  final String guid;
  final String title;

  /// Enclosure URL — the streamable audio.
  final String audioUrl;

  final String descriptionHtml;
  final Duration? duration;
  final DateTime? publishedAt;
  final String? imageUrl;

  @override
  List<Object?> get props => [guid, title, audioUrl, duration, publishedAt];
}
