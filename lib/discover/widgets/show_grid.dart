import 'package:cabina/discover/models/podcast.dart';
import 'package:cabina/discover/widgets/show_card.dart';
import 'package:flutter/material.dart';

class ShowGrid extends StatelessWidget {
  const ShowGrid({
    required this.podcasts,
    required this.onTapPodcast,
    super.key,
  });

  final List<Podcast> podcasts;
  final void Function(Podcast podcast) onTapPodcast;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.74,
      ),
      itemCount: podcasts.length,
      itemBuilder: (context, index) {
        final podcast = podcasts[index];
        return ShowCard(
          podcast: podcast,
          onTap: () => onTapPodcast(podcast),
        );
      },
    );
  }
}
