import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/discover/cubit/discover_cubit.dart';
import 'package:cabina/discover/data/discover_repository.dart';
import 'package:cabina/discover/data/favourites_repository.dart';
import 'package:cabina/discover/models/podcast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscoverRepository extends Mock implements DiscoverRepository {}

class _MockFavouritesRepository extends Mock implements FavouritesRepository {}

void main() {
  late _MockDiscoverRepository discoverRepository;
  late _MockFavouritesRepository favouritesRepository;

  const podcast = Podcast(
    id: 1,
    title: 'Reply All',
    author: 'Gimlet',
    feedUrl: 'https://example.com/feed.xml',
  );

  setUp(() {
    discoverRepository = _MockDiscoverRepository();
    favouritesRepository = _MockFavouritesRepository();
  });

  DiscoverCubit buildCubit() => DiscoverCubit(
    discoverRepository: discoverRepository,
    favouritesRepository: favouritesRepository,
  );

  group('DiscoverCubit', () {
    blocTest<DiscoverCubit, DiscoverState>(
      'GIVEN an error state '
      'WHEN loadFeatured succeeds '
      'THEN errorMessage is null',
      build: () {
        when(
          () => discoverRepository.featured(),
        ).thenAnswer((_) async => [podcast]);
        return buildCubit();
      },
      seed: () => const DiscoverState(
        status: DiscoverStatus.error,
        errorMessage: 'x',
      ),
      act: (cubit) => cubit.loadFeatured(),
      expect: () => const [
        DiscoverState(status: DiscoverStatus.loading),
        DiscoverState(
          status: DiscoverStatus.ready,
          podcasts: [podcast],
        ),
      ],
    );

    blocTest<DiscoverCubit, DiscoverState>(
      'GIVEN restored favourites [1] '
      'WHEN loadFeatured runs '
      'THEN favouriteIds stays [1]',
      build: () {
        when(
          () => discoverRepository.featured(),
        ).thenAnswer((_) async => [podcast]);
        return buildCubit();
      },
      seed: () => const DiscoverState(favouriteIds: [1]),
      act: (cubit) => cubit.loadFeatured(),
      expect: () => const [
        DiscoverState(
          status: DiscoverStatus.loading,
          favouriteIds: [1],
        ),
        DiscoverState(
          status: DiscoverStatus.ready,
          podcasts: [podcast],
          favouriteIds: [1],
        ),
      ],
    );

    blocTest<DiscoverCubit, DiscoverState>(
      'GIVEN a repository that throws a CabinaException '
      'WHEN loadFeatured runs '
      'THEN emits [loading, error] with the exception message',
      build: () {
        when(
          () => discoverRepository.featured(),
        ).thenThrow(const NetworkException('offline'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadFeatured(),
      errors: () => [isA<CabinaException>()],
      expect: () => const [
        DiscoverState(status: DiscoverStatus.loading),
        DiscoverState(
          status: DiscoverStatus.error,
          errorMessage: 'offline',
        ),
      ],
    );

    blocTest<DiscoverCubit, DiscoverState>(
      'GIVEN the repository throws a StateError '
      'WHEN loadFeatured runs '
      'THEN emits error with CabinaException.fallbackMessage',
      build: () {
        when(
          () => discoverRepository.featured(),
        ).thenThrow(StateError('unexpected'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadFeatured(),
      errors: () => [isA<StateError>()],
      expect: () => const [
        DiscoverState(status: DiscoverStatus.loading),
        DiscoverState(
          status: DiscoverStatus.error,
          errorMessage: CabinaException.fallbackMessage,
        ),
      ],
    );

    group('toggleFavourite', () {
      setUp(() {
        when(
          () => favouritesRepository.save(any()),
        ).thenAnswer((_) async {});
      });

      blocTest<DiscoverCubit, DiscoverState>(
        'GIVEN the initial state '
        'WHEN toggleFavourite(1) '
        'THEN saves and emits [1]',
        build: buildCubit,
        act: (cubit) => cubit.toggleFavourite(1),
        expect: () => const [
          DiscoverState(favouriteIds: [1]),
        ],
        verify: (_) => verify(() => favouritesRepository.save([1])).called(1),
      );

      blocTest<DiscoverCubit, DiscoverState>(
        'GIVEN favourites [1] '
        'WHEN toggleFavourite(1) '
        'THEN saves and emits []',
        build: buildCubit,
        seed: () => const DiscoverState(favouriteIds: [1]),
        act: (cubit) => cubit.toggleFavourite(1),
        expect: () => const [DiscoverState()],
        verify: (_) => verify(() => favouritesRepository.save([])).called(1),
      );

      blocTest<DiscoverCubit, DiscoverState>(
        'GIVEN ready and save throws '
        'WHEN toggleFavourite '
        'THEN favouriteIds unchanged, status ready and errorMessage set',
        build: () {
          when(
            () => favouritesRepository.save(any()),
          ).thenThrow(const StorageException('Could not save'));
          return buildCubit();
        },
        seed: () => const DiscoverState(
          status: DiscoverStatus.ready,
          favouriteIds: [1],
        ),
        act: (cubit) => cubit.toggleFavourite(2),
        errors: () => [isA<StorageException>()],
        expect: () => const [
          DiscoverState(
            status: DiscoverStatus.ready,
            favouriteIds: [1],
            errorMessage: 'Could not save',
          ),
        ],
      );

      blocTest<DiscoverCubit, DiscoverState>(
        'GIVEN ready with an error '
        'WHEN a later toggle succeeds '
        'THEN errorMessage is cleared',
        build: buildCubit,
        seed: () => const DiscoverState(
          status: DiscoverStatus.ready,
          errorMessage: 'Could not save',
        ),
        act: (cubit) => cubit.toggleFavourite(1),
        expect: () => const [
          DiscoverState(status: DiscoverStatus.ready, favouriteIds: [1]),
        ],
      );

      blocTest<DiscoverCubit, DiscoverState>(
        'GIVEN the featured load failed '
        'WHEN a toggle succeeds '
        'THEN the featured errorMessage is kept',
        build: buildCubit,
        seed: () => const DiscoverState(
          status: DiscoverStatus.error,
          errorMessage: 'offline',
        ),
        act: (cubit) => cubit.toggleFavourite(1),
        expect: () => const [
          DiscoverState(
            status: DiscoverStatus.error,
            favouriteIds: [1],
            errorMessage: 'offline',
          ),
        ],
      );

      blocTest<DiscoverCubit, DiscoverState>(
        'GIVEN the featured load failed and save throws '
        'WHEN toggleFavourite '
        'THEN adds the error and emits nothing',
        build: () {
          when(
            () => favouritesRepository.save(any()),
          ).thenThrow(const StorageException('Could not save'));
          return buildCubit();
        },
        seed: () => const DiscoverState(
          status: DiscoverStatus.error,
          errorMessage: 'offline',
        ),
        act: (cubit) => cubit.toggleFavourite(1),
        errors: () => [isA<StorageException>()],
        expect: () => const <DiscoverState>[],
      );
    });

    group('restoreFavourites', () {
      blocTest<DiscoverCubit, DiscoverState>(
        'GIVEN stored favourites [1] '
        'WHEN restoreFavourites '
        'THEN favouriteIds is [1]',
        build: () {
          when(
            () => favouritesRepository.load(),
          ).thenAnswer((_) async => [1]);
          return buildCubit();
        },
        act: (cubit) => cubit.restoreFavourites(),
        expect: () => const [
          DiscoverState(favouriteIds: [1]),
        ],
      );

      blocTest<DiscoverCubit, DiscoverState>(
        'GIVEN load throws '
        'WHEN restoreFavourites '
        'THEN adds the error and favouriteIds stays empty',
        build: () {
          when(
            () => favouritesRepository.load(),
          ).thenThrow(const StorageException('corrupt'));
          return buildCubit();
        },
        act: (cubit) => cubit.restoreFavourites(),
        errors: () => [isA<StorageException>()],
        expect: () => const <DiscoverState>[],
        verify: (cubit) => expect(cubit.state.favouriteIds, isEmpty),
      );
    });
  });
}
