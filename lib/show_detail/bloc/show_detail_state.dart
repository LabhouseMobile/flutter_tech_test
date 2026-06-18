part of 'show_detail_bloc.dart';

enum ShowDetailStatus { initial, loading, ready, error }

class ShowDetailState extends Equatable {
  const ShowDetailState({
    this.status = ShowDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final ShowDetailStatus status;
  final PodcastDetail? detail;
  final String? errorMessage;

  ShowDetailState copyWith({
    ShowDetailStatus? status,
    PodcastDetail? detail,
    String? errorMessage,
  }) {
    return ShowDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, detail, errorMessage];
}
