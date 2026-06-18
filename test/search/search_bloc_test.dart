import 'package:bloc_test/bloc_test.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/discover/models/podcast.dart';
import 'package:cabina/search/bloc/search_bloc.dart';
import 'package:cabina/search/data/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late _MockSearchRepository repository;

  const podcast = Podcast(
    id: 1,
    title: 'Reply All',
    author: 'Gimlet',
    feedUrl: 'https://example.com/feed.xml',
  );

  // Give the asynchronous search handler time to settle before asserting.
  const settle = Duration(milliseconds: 400);

  setUp(() => repository = _MockSearchRepository());

  SearchBloc buildBloc() => SearchBloc(searchRepository: repository);

  group('SearchBloc', () {
    blocTest<SearchBloc, SearchState>(
      'emits [loading, ready] with results for a non-empty query',
      build: () {
        when(() => repository.search(any()))
            .thenAnswer((_) async => [podcast]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchTermChanged('reply all')),
      wait: settle,
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'reply all'),
        const SearchState(
          status: SearchStatus.ready,
          query: 'reply all',
          results: [podcast],
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'resets to initial state for an empty query',
      build: buildBloc,
      seed: () => const SearchState(
        status: SearchStatus.ready,
        query: 'old',
        results: [podcast],
      ),
      act: (bloc) => bloc.add(const SearchTermChanged('   ')),
      wait: settle,
      expect: () => [const SearchState()],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [error] when the repository throws a CabinaException',
      build: () {
        when(() => repository.search(any()))
            .thenThrow(const NetworkException('offline'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SearchTermChanged('reply')),
      wait: settle,
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'reply'),
        const SearchState(
          status: SearchStatus.error,
          query: 'reply',
          errorMessage: 'offline',
        ),
      ],
    );
  });
}
