part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchTermChanged extends SearchEvent {
  const SearchTermChanged(this.term);

  final String term;

  @override
  List<Object?> get props => [term];
}
