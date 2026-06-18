import 'dart:async';

import 'package:cabina/library/library_store.dart';
import 'package:cabina/library/subscribed_podcast.dart';
import 'package:flutter/material.dart';

// Toggles a Library subscription. Talks straight to LibraryStore and rebuilds
// itself with setState — the original Library implementation.
class SubscribeButton extends StatefulWidget {
  const SubscribeButton({
    required this.id,
    required this.title,
    required this.author,
    this.artworkUrl,
    super.key,
  });

  final int id;
  final String title;
  final String author;
  final String? artworkUrl;

  @override
  State<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<SubscribeButton> {
  @override
  void initState() {
    super.initState();
    unawaited(
      LibraryStore.instance.load().then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  Future<void> _toggle() async {
    final store = LibraryStore.instance;
    if (store.isSubscribed(widget.id)) {
      await store.unsubscribe(widget.id);
    } else {
      await store.subscribe(
        SubscribedPodcast(
          id: widget.id,
          title: widget.title,
          author: widget.author,
          artworkUrl: widget.artworkUrl,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final subscribed = LibraryStore.instance.isSubscribed(widget.id);
    return FilledButton.icon(
      onPressed: _toggle,
      icon: Icon(subscribed ? Icons.check : Icons.add),
      label: Text(subscribed ? 'Subscribed' : 'Subscribe'),
    );
  }
}
