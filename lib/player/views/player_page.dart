import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/poster_image.dart';
import 'package:cabina/common/widgets/status_views.dart';
import 'package:cabina/player/bloc/player_bloc.dart';
import 'package:cabina/player/data/services/just_audio_player_service.dart';
import 'package:cabina/player/models/player_args.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:cabina/player/widgets/player_controls.dart';
import 'package:cabina/player/widgets/seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({required this.args, super.key});

  final PlayerArgs args;

  static const routeName = 'player';
  static const routePath = '/player';

  static GoRoute route() => GoRoute(
    path: routePath,
    name: routeName,
    builder: (_, state) {
      final args = state.extra! as PlayerArgs;
      return BlocProvider(
        create: (_) => PlayerBloc(repository: JustAudioPlayerService()),
        child: PlayerPage(args: args),
      );
    },
  );

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  @override
  void initState() {
    super.initState();
    context.read<PlayerBloc>().add(PlayerOpened(widget.args));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          if (state.status == PlayerStatus.error) {
            return ErrorView(message: state.errorMessage!);
          }
          final args = state.args ?? widget.args;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: [
                const Spacer(),
                AspectRatio(
                  aspectRatio: 1,
                  child: PosterImage(url: args.artworkUrl, borderRadius: 20),
                ),
                const SizedBox(height: 28),
                Text(
                  args.episode.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline.copyWith(
                    color: theme.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  args.podcastTitle,
                  style: AppTextStyles.caption.copyWith(
                    color: theme.foregroundSoft,
                  ),
                ),
                const Spacer(),
                SeekBar(position: state.position),
                const SizedBox(height: 12),
                PlayerControls(
                  status: state.status,
                  speed: state.speed,
                  position: state.position,
                ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}
