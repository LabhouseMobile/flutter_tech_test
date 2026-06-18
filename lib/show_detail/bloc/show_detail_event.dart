part of 'show_detail_bloc.dart';

sealed class ShowDetailEvent extends Equatable {
  const ShowDetailEvent();

  @override
  List<Object?> get props => [];
}

class ShowDetailRequested extends ShowDetailEvent {
  const ShowDetailRequested(this.podcast);

  final Podcast podcast;

  @override
  List<Object?> get props => [podcast];
}
