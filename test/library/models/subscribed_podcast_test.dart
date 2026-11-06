import 'package:cabina/library/models/subscribed_podcast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validJson() => {
    'id': 1,
    'title': 'Title | with ; separators',
    'author': 'Author',
    'feedUrl': 'https://example.com/feed.xml',
    'artworkUrl': 'https://example.com/a.png',
  };

  group('SubscribedPodcast', () {
    test('GIVEN a podcast whose title holds | and ; '
        'WHEN toJson then fromJson '
        'THEN the result is equal', () {
      const podcast = SubscribedPodcast(
        id: 1,
        title: 'Title | with ; separators',
        author: 'Author',
        feedUrl: 'https://example.com/feed.xml',
        artworkUrl: 'https://example.com/a.png',
      );

      expect(SubscribedPodcast.fromJson(podcast.toJson()), podcast);
    });

    for (final (field, value) in [
      ('id', null),
      ('id', '1'),
      ('title', null),
      ('title', ''),
      ('title', 1),
      ('author', null),
      ('author', ''),
    ]) {
      test('GIVEN $field = ${value is String ? '"$value"' : value} '
          'WHEN fromJson '
          'THEN throws a FormatException', () {
        final json = validJson()..[field] = value;

        expect(
          () => SubscribedPodcast.fromJson(json),
          throwsFormatException,
        );
      });
    }

    final optionalFields = <(String, String? Function(SubscribedPodcast))>[
      ('feedUrl', (podcast) => podcast.feedUrl),
      ('artworkUrl', (podcast) => podcast.artworkUrl),
    ];
    for (final (field, read) in optionalFields) {
      for (final value in [null, '', 42]) {
        test('GIVEN $field = ${value is String ? '"$value"' : value} '
            'WHEN fromJson '
            'THEN $field is null', () {
          final json = validJson()..[field] = value;

          expect(read(SubscribedPodcast.fromJson(json)), isNull);
        });
      }
    }
  });
}
