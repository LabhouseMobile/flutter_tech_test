import 'dart:async';

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
  final settle =
      SearchBloc.debounceDuration + const Duration(milliseconds: 100);

  const leyendas = Podcast(
    id: 2,
    title: 'Leyendas Legendarias',
    author: 'Leyendas Legendarias',
    feedUrl: 'https://example.com/leyendas.xml',
  );
  const historias = Podcast(
    id: 3,
    title: 'Historias del mas aca',
    author: 'Leyendas Legendarias',
    feedUrl: 'https://example.com/historias.xml',
  );

  setUp(() => repository = _MockSearchRepository());

  SearchBloc buildBloc() => SearchBloc(searchRepository: repository);

  group('SearchBloc', () {
    blocTest<SearchBloc, SearchState>(
      'emits [loading, ready] with results for a non-empty query',
      build: () {
        when(() => repository.search(any())).thenAnswer(
          (_) async => [podcast],
        );
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
        when(() => repository.search(any())).thenThrow(
          const NetworkException('offline'),
        );
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

    blocTest<SearchBloc, SearchState>(
      'clears the previous error message when a search succeeds',
      build: () {
        when(() => repository.search(any())).thenAnswer(
          (_) async => [podcast],
        );
        return buildBloc();
      },
      seed: () => const SearchState(
        status: SearchStatus.error,
        query: 'reply',
        errorMessage: 'offline',
      ),
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
      'searches only the last term when typing within the debounce window',
      build: () {
        when(() => repository.search(any())).thenAnswer(
          (_) async => [leyendas],
        );
        return buildBloc();
      },
      act: (bloc) => bloc
        ..add(const SearchTermChanged('l'))
        ..add(const SearchTermChanged('le'))
        ..add(const SearchTermChanged('ley'))
        ..add(const SearchTermChanged('leye')),
      wait: settle,
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'leye'),
        const SearchState(
          status: SearchStatus.ready,
          query: 'leye',
          results: [leyendas],
        ),
      ],
      verify: (_) {
        verify(() => repository.search('leye')).called(1);
        verifyNoMoreInteractions(repository);
      },
    );

    late Completer<List<Podcast>> olderSearch;
    late Completer<List<Podcast>> newerSearch;

    blocTest<SearchBloc, SearchState>(
      'discards the results of an older search that resolves late',
      build: () {
        olderSearch = Completer<List<Podcast>>();
        newerSearch = Completer<List<Podcast>>();
        when(() => repository.search('ley')).thenAnswer(
          (_) => olderSearch.future,
        );
        when(() => repository.search('leyendas')).thenAnswer(
          (_) => newerSearch.future,
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const SearchTermChanged('ley'));
        await Future<void>.delayed(settle);
        bloc.add(const SearchTermChanged('leyendas'));
        await Future<void>.delayed(settle);
        newerSearch.complete([historias]);
        await Future<void>.delayed(Duration.zero);
        olderSearch.complete([leyendas]);
      },
      wait: settle,
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'ley'),
        const SearchState(status: SearchStatus.loading, query: 'leyendas'),
        const SearchState(
          status: SearchStatus.ready,
          query: 'leyendas',
          results: [historias],
        ),
      ],
    );

    late Completer<List<Podcast>> ghostSearch;

    blocTest<SearchBloc, SearchState>(
      'resets immediately when the query is cleared while search is in flight',
      build: () {
        ghostSearch = Completer<List<Podcast>>();
        when(() => repository.search(any())).thenAnswer(
          (_) => ghostSearch.future,
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const SearchTermChanged('ley'));
        await Future<void>.delayed(settle); // waiting longer than next event
        bloc.add(const SearchTermChanged(''));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        ghostSearch.complete([leyendas]);
      },
      wait: settle,
      expect: () => [
        const SearchState(status: SearchStatus.loading, query: 'ley'),
        const SearchState(),
      ],
    );
  });
}
