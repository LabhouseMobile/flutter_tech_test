import 'dart:convert';

import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/common/storage/local_storage.dart';
import 'package:cabina/library/data/library_repository.dart';
import 'package:cabina/library/models/subscribed_podcast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLocalStorage extends Mock implements LocalStorage {}

void main() {
  const key = 'library_podcasts';
  const legacyKey = 'library_subscriptions';

  const first = SubscribedPodcast(
    id: 1,
    title: 'A',
    author: 'B',
    feedUrl: 'https://example.com/feed.xml',
    artworkUrl: 'http://a.png',
  );
  const second = SubscribedPodcast(id: 2, title: 'C', author: 'D');

  late LocalStorage localStorage;

  Future<LibraryRepository> buildRepository([
    Map<String, Object> stored = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    localStorage = LocalStorage(prefs: await SharedPreferences.getInstance());
    return LibraryRepository(localStorage: localStorage);
  }

  group('LibraryRepository', () {
    group('load', () {
      test('GIVEN nothing stored '
          'WHEN load '
          'THEN returns an empty list', () async {
        final repository = await buildRepository();

        expect(await repository.load(), isEmpty);
      });

      for (final raw in ['', 'not json', '{"id": 1}']) {
        test('GIVEN $key = "$raw" '
            'WHEN load '
            'THEN returns an empty list', () async {
          final repository = await buildRepository({key: raw});

          expect(await repository.load(), isEmpty);
        });
      }

      test('GIVEN one valid entry, one malformed and one that is not an object '
          'WHEN load '
          'THEN returns only the valid one', () async {
        final repository = await buildRepository({
          key: jsonEncode([
            second.toJson(),
            {'id': 'x', 'title': 'T', 'author': 'A'},
            'text',
          ]),
        });

        expect(await repository.load(), [second]);
      });
    });

    test('GIVEN a list '
        'WHEN save '
        'THEN load returns it in order', () async {
      final repository = await buildRepository();

      await repository.save([first, second]);

      expect(await repository.load(), [first, second]);
    });

    group('legacy migration', () {
      test('GIVEN only $legacyKey '
          'WHEN load '
          'THEN returns its entries, saves them as JSON '
          'and deletes $legacyKey', () async {
        final repository = await buildRepository({
          legacyKey: '1|A|B|http://a.png;2|C|D|',
        });

        final podcasts = await repository.load();

        const migratedFirst = SubscribedPodcast(
          id: 1,
          title: 'A',
          author: 'B',
          artworkUrl: 'http://a.png',
        );
        expect(podcasts, [migratedFirst, second]);
        expect(
          await localStorage.read(key),
          jsonEncode([migratedFirst.toJson(), second.toJson()]),
        );
        expect(await localStorage.read(legacyKey), isNull);
      });

      test('GIVEN legacy entries with a non-int id, 3 or 5 fields, '
          'or an empty title or author '
          'WHEN load '
          'THEN those are skipped', () async {
        final repository = await buildRepository({
          legacyKey: 'x|A|B|;3|A|B;4|A|B|c|d;5||B|;6|A||;2|C|D|',
        });

        expect(await repository.load(), [second]);
      });

      test('GIVEN $legacyKey is empty, as after unsubscribing from all '
          'WHEN load '
          'THEN returns an empty list and deletes $legacyKey', () async {
        final repository = await buildRepository({legacyKey: ''});

        expect(await repository.load(), isEmpty);
        expect(await localStorage.read(legacyKey), isNull);
      });

      test('GIVEN both keys '
          'WHEN load '
          'THEN $key wins and $legacyKey is untouched', () async {
        final repository = await buildRepository({
          key: jsonEncode([second.toJson()]),
          legacyKey: '1|A|B|',
        });

        expect(await repository.load(), [second]);
        expect(await localStorage.read(legacyKey), '1|A|B|');
      });

      group('with a failing storage', () {
        late _MockLocalStorage storage;
        late LibraryRepository repository;

        setUp(() {
          storage = _MockLocalStorage();
          repository = LibraryRepository(localStorage: storage);
          when(() => storage.read(key)).thenAnswer((_) async => null);
          when(
            () => storage.read(legacyKey),
          ).thenAnswer((_) async => '2|C|D|');
        });

        test('GIVEN the migration write fails '
            'WHEN load '
            'THEN throws StorageException and keeps $legacyKey', () async {
          when(
            () => storage.write(key, any()),
          ).thenThrow(const StorageException('Could not save your changes'));

          await expectLater(
            repository.load(),
            throwsA(isA<StorageException>()),
          );
          verifyNever(() => storage.delete(any()));
        });

        test('GIVEN the legacy delete fails '
            'WHEN load '
            'THEN throws StorageException after saving under $key', () async {
          when(() => storage.write(key, any())).thenAnswer((_) async {});
          when(
            () => storage.delete(legacyKey),
          ).thenThrow(const StorageException('Could not save your changes'));

          await expectLater(
            repository.load(),
            throwsA(isA<StorageException>()),
          );
          verify(
            () => storage.write(key, jsonEncode([second.toJson()])),
          ).called(1);
        });
      });
    });
  });
}
