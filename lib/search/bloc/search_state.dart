part of 'search_bloc.dart';

enum SearchStatus { initial, loading, ready, error }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.errorMessage,
  });

  final SearchStatus status;
  final String query;
  final List<Podcast> results;
  final String? errorMessage;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Podcast>? results,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, query, results, errorMessage];
}
