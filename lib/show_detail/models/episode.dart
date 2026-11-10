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
    this.transcriptUrl,
  });

  final String guid;
  final String title;

  /// Enclosure URL — the streamable audio.
  final String audioUrl;

  final String descriptionHtml;
  final Duration? duration;
  final DateTime? publishedAt;
  final String? imageUrl;

  /// The feed's SRT or VTT transcript (`<podcast:transcript>`), when it
  /// publishes one.
  final String? transcriptUrl;

  @override
  List<Object?> get props => [
    guid,
    title,
    audioUrl,
    descriptionHtml,
    duration,
    publishedAt,
    imageUrl,
    transcriptUrl,
  ];
}
