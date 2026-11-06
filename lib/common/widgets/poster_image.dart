import 'package:cabina/common/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Square artwork used across discover/search/detail/player. Renders a rounded
/// image cached on disk, with graceful loading + error states.
class PosterImage extends StatelessWidget {
  const PosterImage({
    required this.url,
    this.size,
    this.borderRadius = 12,
    super.key,
  });

  final String? url;
  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final url = this.url;
    final placeholder = Container(
      width: size,
      height: size,
      color: theme.surface,
      child: Icon(Icons.podcasts, color: theme.foregroundSoft),
    );
    final loading = Container(
      width: size,
      height: size,
      color: theme.surface,
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              useOldImageOnUrlChange: true,
              placeholder: (_, _) => loading,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}
