import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/library/cubit/library_cubit.dart';
import 'package:cabina/library/data/library_repository.dart';
import 'package:cabina/library/models/subscribed_podcast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  const first = SubscribedPodcast(id: 1, title: 'A', author: 'B');
  const second = SubscribedPodcast(id: 2, title: 'C', author: 'D');
  const saveError = StorageException('Could not save your changes');

  late _MockLibraryRepository repository;

  setUp(() {
    repository = _MockLibraryRepository();
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  LibraryCubit buildCubit() => LibraryCubit(libraryRepository: repository);

  group('LibraryCubit', () {
    group('load', () {
      blocTest<LibraryCubit, LibraryState>(
        'GIVEN stored podcasts '
        'WHEN load '
        'THEN emits loading, then ready with them',
        setUp: () => when(
          () => repository.load(),
        ).thenAnswer((_) async => [first, second]),
        build: buildCubit,
        act: (cubit) => cubit.load(),
        expect: () => const [
          LibraryState(status: LibraryStatus.loading),
          LibraryState(status: LibraryStatus.ready, podcasts: [first, second]),
        ],
      );

      blocTest<LibraryCubit, LibraryState>(
        'GIVEN the repository throws '
        'WHEN load '
        'THEN emits error with its message and reports it',
        setUp: () => when(
          () => repository.load(),
        ).thenThrow(const StorageException('Could not load your saved data')),
        build: buildCubit,
        act: (cubit) => cubit.load(),
        expect: () => const [
          LibraryState(status: LibraryStatus.loading),
          LibraryState(
            status: LibraryStatus.error,
            errorMessage: 'Could not load your saved data',
          ),
        ],
        errors: () => [isA<StorageException>()],
      );

      blocTest<LibraryCubit, LibraryState>(
        'GIVEN an error '
        'WHEN load succeeds '
        'THEN errorMessage is cleared',
        setUp: () =>
            when(() => repository.load()).thenAnswer((_) async => [first]),
        build: buildCubit,
        seed: () => const LibraryState(
          status: LibraryStatus.error,
          errorMessage: 'x',
        ),
        act: (cubit) => cubit.load(),
        expect: () => const [
          LibraryState(status: LibraryStatus.loading),
          LibraryState(status: LibraryStatus.ready, podcasts: [first]),
        ],
      );
    });

    group('subscribe', () {
      blocTest<LibraryCubit, LibraryState>(
        'GIVEN a new podcast '
        'WHEN subscribe '
        'THEN saves it at the end and emits the list',
        build: buildCubit,
        seed: () => const LibraryState(
          status: LibraryStatus.ready,
          podcasts: [first],
        ),
        act: (cubit) => cubit.subscribe(second),
        expect: () => const [
          LibraryState(status: LibraryStatus.ready, podcasts: [first, second]),
        ],
        verify: (_) => verify(() => repository.save([first, second])).called(1),
      );

      blocTest<LibraryCubit, LibraryState>(
        'GIVEN an already subscribed podcast '
        'WHEN subscribe '
        'THEN nothing is saved or emitted',
        build: buildCubit,
        seed: () => const LibraryState(
          status: LibraryStatus.ready,
          podcasts: [first],
        ),
        act: (cubit) => cubit.subscribe(first),
        expect: () => const <LibraryState>[],
        verify: (_) => verifyNever(() => repository.save(any())),
      );

      blocTest<LibraryCubit, LibraryState>(
        'GIVEN save throws '
        'WHEN subscribe '
        'THEN the list is unchanged, status ready and errorMessage set',
        setUp: () => when(() => repository.save(any())).thenThrow(saveError),
        build: buildCubit,
        seed: () => const LibraryState(
          status: LibraryStatus.ready,
          podcasts: [first],
        ),
        act: (cubit) => cubit.subscribe(second),
        expect: () => const [
          LibraryState(
            status: LibraryStatus.ready,
            podcasts: [first],
            errorMessage: 'Could not save your changes',
          ),
        ],
        errors: () => [saveError],
      );

      blocTest<LibraryCubit, LibraryState>(
        'GIVEN a write error '
        'WHEN a later subscribe succeeds '
        'THEN errorMessage is cleared',
        build: buildCubit,
        seed: () => const LibraryState(
          status: LibraryStatus.ready,
          errorMessage: 'Could not save your changes',
        ),
        act: (cubit) => cubit.subscribe(first),
        expect: () => const [
          LibraryState(status: LibraryStatus.ready, podcasts: [first]),
        ],
      );

      blocTest<LibraryCubit, LibraryState>(
        'GIVEN a write error '
        'WHEN another write fails with the same message '
        'THEN errorMessage is cleared and set again, so the SnackBar reshows',
        setUp: () => when(() => repository.save(any())).thenThrow(saveError),
        build: buildCubit,
        seed: () => const LibraryState(
          status: LibraryStatus.ready,
          errorMessage: 'Could not save your changes',
        ),
        act: (cubit) => cubit.subscribe(first),
        expect: () => const [
          LibraryState(status: LibraryStatus.ready),
          LibraryState(
            status: LibraryStatus.ready,
            errorMessage: 'Could not save your changes',
          ),
        ],
        errors: () => [saveError],
      );

      for (final status in [
        LibraryStatus.initial,
        LibraryStatus.loading,
        LibraryStatus.error,
      ]) {
        blocTest<LibraryCubit, LibraryState>(
          'GIVEN the library is ${status.name} '
          'WHEN subscribe '
          'THEN nothing is saved, so the stored list is not overwritten',
          build: buildCubit,
          seed: () => LibraryState(status: status),
          act: (cubit) => cubit.subscribe(first),
          expect: () => const <LibraryState>[],
          verify: (_) => verifyNever(() => repository.save(any())),
        );
      }
    });

    group('unsubscribe', () {
      blocTest<LibraryCubit, LibraryState>(
        'GIVEN two podcasts '
        'WHEN unsubscribe one '
        'THEN saves the list without it and emits it',
        build: buildCubit,
        seed: () => const LibraryState(
          status: LibraryStatus.ready,
          podcasts: [first, second],
        ),
        act: (cubit) => cubit.unsubscribe(first.id),
        expect: () => const [
          LibraryState(status: LibraryStatus.ready, podcasts: [second]),
        ],
        verify: (_) => verify(() => repository.save([second])).called(1),
      );

      blocTest<LibraryCubit, LibraryState>(
        'GIVEN save throws '
        'WHEN unsubscribe '
        'THEN the list is unchanged and errorMessage set',
        setUp: () => when(() => repository.save(any())).thenThrow(saveError),
        build: buildCubit,
        seed: () => const LibraryState(
          status: LibraryStatus.ready,
          podcasts: [first],
        ),
        act: (cubit) => cubit.unsubscribe(first.id),
        expect: () => const [
          LibraryState(
            status: LibraryStatus.ready,
            podcasts: [first],
            errorMessage: 'Could not save your changes',
          ),
        ],
        errors: () => [saveError],
      );
    });
  });

  group('LibraryState', () {
    test('GIVEN podcasts '
        'WHEN isSubscribed '
        'THEN true only for their ids', () {
      const state = LibraryState(podcasts: [first]);

      expect(state.isSubscribed(first.id), isTrue);
      expect(state.isSubscribed(second.id), isFalse);
    });
  });
}
