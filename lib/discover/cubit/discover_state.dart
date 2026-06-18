part of 'discover_cubit.dart';

enum DiscoverStatus { initial, loading, ready, error }

class DiscoverState extends Equatable {
  const DiscoverState({
    this.status = DiscoverStatus.initial,
    this.podcasts = const [],
    this.favouriteIds = const [],
    this.errorMessage,
  });

  final DiscoverStatus status;
  final List<Podcast> podcasts;
  final List<int> favouriteIds;
  final String? errorMessage;

  DiscoverState copyWith({
    DiscoverStatus? status,
    List<Podcast>? podcasts,
    List<int>? favouriteIds,
    String? errorMessage,
  }) {
    return DiscoverState(
      status: status ?? this.status,
      podcasts: podcasts ?? this.podcasts,
      favouriteIds: favouriteIds ?? this.favouriteIds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, podcasts, favouriteIds, errorMessage];
}
