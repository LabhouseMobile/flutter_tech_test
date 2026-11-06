import 'package:bloc/bloc.dart';
import 'package:cabina/common/errors/exceptions.dart';
import 'package:cabina/library/data/library_repository.dart';
import 'package:cabina/library/models/subscribed_podcast.dart';
import 'package:equatable/equatable.dart';

part 'library_state.dart';

/// App-scoped owner of the subscriptions, shared by the Library tab and every
/// `SubscribeButton`, so a change in one shows up in the other.
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({required LibraryRepository libraryRepository})
    : _libraryRepository = libraryRepository,
      super(const LibraryState());

  final LibraryRepository _libraryRepository;

  Future<void> load() async {
    emit(state.copyWith(status: LibraryStatus.loading, clearError: true));
    try {
      final podcasts = await _libraryRepository.load();
      emit(state.copyWith(status: LibraryStatus.ready, podcasts: podcasts));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: LibraryStatus.error,
          errorMessage: CabinaException.messageOf(error),
        ),
      );
    }
  }

  /// Adds [podcast] at the end. Does nothing if it's already there, or while
  /// the library isn't `ready` (see [_save]).
  Future<void> subscribe(SubscribedPodcast podcast) async {
    if (state.isSubscribed(podcast.id)) return;
    await _save([...state.podcasts, podcast]);
  }

  /// Removes the podcast with [id]. Does nothing while the library isn't
  /// `ready` (see [_save]).
  Future<void> unsubscribe(int id) =>
      _save(state.podcasts.where((podcast) => podcast.id != id).toList());

  /// Saves [podcasts] and emits them once the save succeeds, clearing the
  /// last write error. On failure the list stays as it was, the error goes to
  /// [addError] and `errorMessage` is set, with the status still `ready`.
  ///
  /// Ignored unless the library is `ready`: before the load finishes the list
  /// is empty, and saving it would overwrite the stored subscriptions.
  Future<void> _save(List<SubscribedPodcast> podcasts) async {
    if (state.status != LibraryStatus.ready) return;
    try {
      await _libraryRepository.save(podcasts);
      emit(state.copyWith(podcasts: podcasts, clearError: true));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      // Cleared first, so a second failure with the same message is still a
      // change and `LibraryPage` shows the SnackBar again.
      emit(state.copyWith(clearError: true));
      emit(state.copyWith(errorMessage: CabinaException.messageOf(error)));
    }
  }
}
