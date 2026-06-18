import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/poster_image.dart';
import 'package:cabina/discover/cubit/discover_cubit.dart';
import 'package:cabina/discover/models/podcast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A single podcast tile in the discover/search grid.
class ShowCard extends StatelessWidget {
  const ShowCard({required this.podcast, required this.onTap, super.key});

  final Podcast podcast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isFavourite =
        context.watch<DiscoverCubit>().state.favouriteIds.contains(podcast.id);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: PosterImage(url: podcast.artworkUrl!),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => context
                        .read<DiscoverCubit>()
                        .toggleFavourite(podcast.id),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      child: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavourite ? theme.primary : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            podcast.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(color: theme.foreground),
          ),
          Text(
            podcast.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: theme.foregroundSoft),
          ),
        ],
      ),
    );
  }
}
