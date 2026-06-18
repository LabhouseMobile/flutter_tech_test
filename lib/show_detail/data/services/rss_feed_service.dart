import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/common/network/api_client.dart';
import 'package:cabina/discover/models/podcast.dart';
import 'package:cabina/show_detail/models/episode.dart';
import 'package:cabina/show_detail/models/podcast_detail.dart';
import 'package:xml/xml.dart';

/// Fetches a podcast's RSS feed and turns it into a [PodcastDetail].
class RssFeedService {
  RssFeedService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PodcastDetail> fetchDetail(Podcast podcast) async {
    final xmlString = await _apiClient.getString(Uri.parse(podcast.feedUrl));
    return _parseFeed(xmlString, podcast);
  }

  PodcastDetail _parseFeed(String xmlString, Podcast podcast) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xmlString);
    } on XmlException catch (e) {
      throw FeedParseException('Feed is not valid XML', cause: e);
    }

    final channel = document.findAllElements('channel').first;

    final episodes = channel.findAllElements('item').map((item) {
      final enclosure = item.findElements('enclosure').first;
      return Episode(
        guid: _firstText(item, 'guid') ??
            item.findElements('title').first.innerText,
        title: item.findElements('title').first.innerText.trim(),
        audioUrl: enclosure.getAttribute('url')!,
        descriptionHtml: _firstText(item, 'description') ?? '',
        duration: _parseDuration(_firstText(item, 'itunes:duration')),
        publishedAt: _parseDate(_firstText(item, 'pubDate')),
        imageUrl: _firstAttr(item, 'itunes:image', 'href'),
      );
    }).toList()
      // Newest first.
      ..sort((a, b) {
        final aDate = a.publishedAt ?? DateTime(1970);
        final bDate = b.publishedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

    final description = _stripHtml(_firstText(channel, 'description') ?? '');

    return PodcastDetail(
      podcastId: podcast.id,
      title: podcast.title,
      author: podcast.author,
      artworkUrl: podcast.artworkUrl,
      descriptionHtml: description,
      episodes: episodes,
    );
  }

  String? _firstText(XmlElement parent, String name) {
    final matches = parent.findElements(name);
    if (matches.isEmpty) return null;
    final text = matches.first.innerText.trim();
    return text.isEmpty ? null : text;
  }

  String? _firstAttr(XmlElement parent, String name, String attr) {
    final matches = parent.findElements(name);
    if (matches.isEmpty) return null;
    return matches.first.getAttribute(attr);
  }

  Duration _parseDuration(String? raw) {
    if (raw == null) return Duration.zero;
    final parts = raw.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  String _stripHtml(String html) {
    // Remove tags and collapse whitespace.
    final withoutTags = html.replaceAll(RegExp('<[^>]*>'), ' ');
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
