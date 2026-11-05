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
    when(() => favouritesRepository.load()).thenReturn(const []);
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
        when(() => favouritesRepository.load()).thenReturn(const [1]);
        when(
          () => discoverRepository.featured(),
        ).thenAnswer((_) async => [podcast]);
        return buildCubit();
      },
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
  });
}
