import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/common/network/api_client.dart';
import 'package:cabina/show_detail/data/services/rss_feed_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late RssFeedService service;

  const feedUrl = 'https://example.com/feed.xml';

  setUpAll(() => registerFallbackValue(Uri()));

  setUp(() {
    apiClient = _MockApiClient();
    service = RssFeedService(apiClient: apiClient);
  });

  group('RssFeedService.fetchFeed', () {
    test('GIVEN a feed URL '
        'WHEN the feed is fetched '
        'THEN it requests that URL and returns the raw XML', () async {
      when(
        () => apiClient.getString(any()),
      ).thenAnswer((_) async => '<rss/>');

      final xml = await service.fetchFeed(feedUrl);

      expect(xml, '<rss/>');
      verify(() => apiClient.getString(Uri.parse(feedUrl))).called(1);
    });

    test('GIVEN the client fails with a CabinaException '
        'WHEN the feed is fetched '
        'THEN that exception reaches the caller unchanged', () async {
      const failure = NetworkException('offline');
      when(() => apiClient.getString(any())).thenThrow(failure);

      await expectLater(service.fetchFeed(feedUrl), throwsA(same(failure)));
    });

    test('GIVEN a URL that does not parse '
        'WHEN the feed is fetched '
        'THEN an ApiException is thrown and no request is made', () async {
      await expectLater(
        service.fetchFeed('http://[::1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', null),
        ),
      );
      verifyNever(() => apiClient.getString(any()));
    });
  });
}
