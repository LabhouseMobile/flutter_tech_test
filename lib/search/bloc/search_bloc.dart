import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/discover/models/podcast.dart';
import 'package:cabina/search/data/search_repository.dart';
import 'package:equatable/equatable.dart';

part 'search_event.dart';
part 'search_state.dart';

/// Waits [duration] after the last keystroke before searching, and cancels
/// the previous search (pending or in flight) when a new term arrives.
///
/// Built on [restartable]. An empty term skips the wait, so clearing the
/// field resets the state instantly and drops any in-flight results.
EventTransformer<SearchTermChanged> _debounceSearch(Duration duration) {
  final restart = restartable<SearchTermChanged>();
  return (events, mapper) => restart(events, (event) {
    if (event.term.trim().isEmpty) return mapper(event);
    return Stream<void>.fromFuture(
      Future<void>.delayed(duration),
    ).asyncExpand((_) => mapper(event));
  });
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchRepository searchRepository})
    : _searchRepository = searchRepository,
      super(const SearchState()) {
    on<SearchTermChanged>(
      _onTermChanged,
      transformer: _debounceSearch(debounceDuration),
    );
  }

  static const debounceDuration = Duration(milliseconds: 300);

  final SearchRepository _searchRepository;

  Future<void> _onTermChanged(
    SearchTermChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.term.trim();
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }

    emit(SearchState(status: SearchStatus.loading, query: query));
    try {
      final results = await _searchRepository.search(query);
      emit(state.copyWith(status: SearchStatus.ready, results: results));
    } on CabinaException catch (e) {
      emit(state.copyWith(status: SearchStatus.error, errorMessage: e.message));
    }
  }
}
