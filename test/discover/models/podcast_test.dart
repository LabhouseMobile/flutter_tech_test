import 'package:cabina/discover/models/podcast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Podcast.fromJson', () {
    test('maps the iTunes search fields', () {
      final podcast = Podcast.fromJson(const {
        'collectionId': 123,
        'collectionName': 'The Daily',
        'artistName': 'The New York Times',
        'feedUrl': 'https://example.com/feed.xml',
        'artworkUrl600': 'https://example.com/art.jpg',
        'primaryGenreName': 'News',
        'trackCount': 1200,
      });

      expect(podcast.id, 123);
      expect(podcast.title, 'The Daily');
      expect(podcast.author, 'The New York Times');
      expect(podcast.feedUrl, 'https://example.com/feed.xml');
      expect(podcast.artworkUrl, 'https://example.com/art.jpg');
      expect(podcast.genre, 'News');
      expect(podcast.episodeCount, 1200);
    });

    test('tolerates a missing artwork url', () {
      final podcast = Podcast.fromJson(const {
        'collectionId': 1,
        'collectionName': 'No Art',
        'artistName': 'Someone',
        'feedUrl': 'https://example.com/feed.xml',
      });

      expect(podcast.artworkUrl, isNull);
      expect(podcast.genre, isNull);
    });
  });
}
