import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/common/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  const key = 'key';

  Future<LocalStorage> buildStorage([
    Map<String, Object> stored = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    return LocalStorage(prefs: await SharedPreferences.getInstance());
  }

  group('LocalStorage', () {
    test('GIVEN a stored value '
        'WHEN read '
        'THEN returns it', () async {
      final storage = await buildStorage({key: 'value'});

      expect(await storage.read(key), 'value');
    });

    test('GIVEN nothing stored '
        'WHEN read '
        'THEN returns null', () async {
      final storage = await buildStorage();

      expect(await storage.read(key), isNull);
    });

    test('GIVEN a value '
        'WHEN write then read '
        'THEN returns it', () async {
      final storage = await buildStorage();

      await storage.write(key, 'value');

      expect(await storage.read(key), 'value');
    });

    test('GIVEN a stored key '
        'WHEN delete '
        'THEN read returns null', () async {
      final storage = await buildStorage({key: 'value'});

      await storage.delete(key);

      expect(await storage.read(key), isNull);
    });

    group('GIVEN the backend', () {
      late _MockSharedPreferences prefs;
      late LocalStorage storage;
      final failure = Exception('disk full');

      setUp(() {
        prefs = _MockSharedPreferences();
        storage = LocalStorage(prefs: prefs);
      });

      test('returns false '
          'WHEN write '
          'THEN throws StorageException', () async {
        when(
          () => prefs.setString(key, 'value'),
        ).thenAnswer((_) async => false);

        await expectLater(
          storage.write(key, 'value'),
          throwsA(isA<StorageException>()),
        );
      });

      test('returns false '
          'WHEN delete '
          'THEN throws StorageException', () async {
        when(() => prefs.remove(key)).thenAnswer((_) async => false);

        await expectLater(
          storage.delete(key),
          throwsA(isA<StorageException>()),
        );
      });

      test('throws '
          'WHEN read '
          'THEN throws StorageException with that cause', () async {
        when(() => prefs.getString(key)).thenThrow(failure);

        await expectLater(
          storage.read(key),
          throwsA(
            isA<StorageException>().having((e) => e.cause, 'cause', failure),
          ),
        );
      });

      test('throws '
          'WHEN write '
          'THEN throws StorageException with that cause', () async {
        when(() => prefs.setString(key, 'value')).thenThrow(failure);

        await expectLater(
          storage.write(key, 'value'),
          throwsA(
            isA<StorageException>().having((e) => e.cause, 'cause', failure),
          ),
        );
      });

      test('throws '
          'WHEN delete '
          'THEN throws StorageException with that cause', () async {
        when(() => prefs.remove(key)).thenThrow(failure);

        await expectLater(
          storage.delete(key),
          throwsA(
            isA<StorageException>().having((e) => e.cause, 'cause', failure),
          ),
        );
      });
    });
  });
}
