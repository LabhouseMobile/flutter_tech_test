import 'package:bloc/bloc.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/discover/data/discover_repository.dart';
import 'package:cabina/discover/data/favourites_repository.dart';
import 'package:cabina/discover/models/podcast.dart';
import 'package:equatable/equatable.dart';

part 'discover_state.dart';

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit({
    required DiscoverRepository discoverRepository,
    required FavouritesRepository favouritesRepository,
  }) : _discoverRepository = discoverRepository,
       _favouritesRepository = favouritesRepository,
       super(const DiscoverState());

  final DiscoverRepository _discoverRepository;
  final FavouritesRepository _favouritesRepository;

  /// Loads the saved favourite ids. If they can't be read (storage failure or
  /// corrupt data), the error goes to [addError] and `favouriteIds` stays
  /// empty: the hearts start unfilled instead of blocking Discover.
  Future<void> restoreFavourites() async {
    try {
      final favouriteIds = await _favouritesRepository.load();
      emit(state.copyWith(favouriteIds: favouriteIds));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  Future<void> loadFeatured() async {
    emit(
      state.copyWith(
        status: DiscoverStatus.loading,
        podcasts: const [],
        clearError: true,
      ),
    );
    try {
      final podcasts = await _discoverRepository.featured();
      emit(state.copyWith(status: DiscoverStatus.ready, podcasts: podcasts));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: DiscoverStatus.error,
          errorMessage: CabinaException.messageOf(error),
        ),
      );
    }
  }

  /// Adds or removes [podcastId]. The new list is saved first and emitted
  /// only once the save succeeds. On failure the list stays as it was and the
  /// error goes to [addError].
  ///
  /// `errorMessage` is touched only while featured is ready: a failure sets
  /// it and a success clears it. In loading or error it belongs to the
  /// featured load, so a failed save from Search only reaches [addError].
  Future<void> toggleFavourite(int podcastId) async {
    final current = state.favouriteIds;
    final favouriteIds = current.contains(podcastId)
        ? current.where((id) => id != podcastId).toList()
        : [...current, podcastId];
    try {
      await _favouritesRepository.save(favouriteIds);
      emit(
        state.copyWith(
          favouriteIds: favouriteIds,
          clearError: state.status == DiscoverStatus.ready,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      if (state.status == DiscoverStatus.ready) {
        emit(state.copyWith(errorMessage: CabinaException.messageOf(error)));
      }
    }
  }
}
