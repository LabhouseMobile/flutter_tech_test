import 'package:equatable/equatable.dart';

/// A podcast the user subscribed to, as the library stores it.
///
/// [feedUrl] is `null` for subscriptions saved before it was stored.
class SubscribedPodcast extends Equatable {
  const SubscribedPodcast({
    required this.id,
    required this.title,
    required this.author,
    this.feedUrl,
    this.artworkUrl,
  });

  /// Throws a [FormatException] unless `id` is an `int` and `title` and
  /// `author` are non-empty strings. `feedUrl` and `artworkUrl` are optional:
  /// a missing, empty or non-string value becomes `null`.
  factory SubscribedPodcast.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final author = json['author'];
    if (id is! int) throw FormatException('Invalid id', id);
    if (title is! String || title.isEmpty) {
      throw FormatException('Invalid title', title);
    }
    if (author is! String || author.isEmpty) {
      throw FormatException('Invalid author', author);
    }
    return SubscribedPodcast(
      id: id,
      title: title,
      author: author,
      feedUrl: _optionalString(json['feedUrl']),
      artworkUrl: _optionalString(json['artworkUrl']),
    );
  }

  final int id;
  final String title;
  final String author;
  final String? feedUrl;
  final String? artworkUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'feedUrl': feedUrl,
    'artworkUrl': artworkUrl,
  };

  static String? _optionalString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  @override
  List<Object?> get props => [id, title, author, feedUrl, artworkUrl];
}
