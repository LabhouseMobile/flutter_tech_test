import 'package:cabina/library/cubit/library_cubit.dart';
import 'package:cabina/library/models/subscribed_podcast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Subscribes to or unsubscribes from [podcast] through the app-scoped
/// [LibraryCubit]. Disabled until the library is ready.
class SubscribeButton extends StatelessWidget {
  const SubscribeButton({required this.podcast, super.key});

  final SubscribedPodcast podcast;

  @override
  Widget build(BuildContext context) {
    final ready = context.select<LibraryCubit, bool>(
      (cubit) => cubit.state.status == LibraryStatus.ready,
    );
    final subscribed = context.select<LibraryCubit, bool>(
      (cubit) => cubit.state.isSubscribed(podcast.id),
    );
    return FilledButton.icon(
      onPressed: ready ? () => _toggle(context.read<LibraryCubit>()) : null,
      icon: Icon(subscribed ? Icons.check : Icons.add),
      label: Text(subscribed ? 'Subscribed' : 'Subscribe'),
    );
  }

  Future<void> _toggle(LibraryCubit cubit) =>
      cubit.state.isSubscribed(podcast.id)
      ? cubit.unsubscribe(podcast.id)
      : cubit.subscribe(podcast);
}
