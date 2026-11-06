import 'package:cabina/common/storage/local_storage.dart';
import 'package:cabina/discover/data/favourites_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'favourite_podcast_ids';

  late LocalStorage localStorage;

  Future<FavouritesRepository> buildRepository([
    Map<String, Object> stored = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    localStorage = LocalStorage(prefs: await SharedPreferences.getInstance());
    return FavouritesRepository(localStorage: localStorage);
  }

  group('FavouritesRepository', () {
    test('GIVEN nothing stored '
        'WHEN load '
        'THEN returns an empty list', () async {
      final repository = await buildRepository();

      expect(await repository.load(), isEmpty);
    });

    test('GIVEN $key stored as the prefs-based build wrote it '
        'WHEN load '
        'THEN returns those ids', () async {
      final repository = await buildRepository({key: '[1,2]'});

      expect(await repository.load(), [1, 2]);
    });

    test('GIVEN [3] saved '
        'WHEN load '
        'THEN returns [3] and stores it as a JSON list', () async {
      final repository = await buildRepository();

      await repository.save([3]);

      expect(await repository.load(), [3]);
      expect(await localStorage.read(key), '[3]');
    });

    test('GIVEN $key holds a non-int id '
        'WHEN load '
        'THEN throws', () async {
      final repository = await buildRepository({key: '[1,"a"]'});

      await expectLater(repository.load(), throwsA(isA<TypeError>()));
    });
  });
}
