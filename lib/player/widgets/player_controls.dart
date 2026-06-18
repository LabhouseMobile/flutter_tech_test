import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/player/bloc/audio_player_bloc.dart';
import 'package:cabina/player/models/playback_speed.dart';
import 'package:cabina/player/models/player_position.dart';
import 'package:cabina/player/models/player_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    required this.status,
    required this.speed,
    required this.position,
    super.key,
  });

  final PlayerStatus status;
  final PlaybackSpeed speed;
  final PlayerPosition position;

  void _skip(BuildContext context, Duration delta) {
    final target = position.position + delta;
    final clamped = target < Duration.zero ? Duration.zero : target;
    context.read<AudioPlayerBloc>().add(PlayerSeeked(clamped));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final bloc = context.read<AudioPlayerBloc>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: () => bloc.add(PlayerSpeedChanged(speed.next)),
          child: Text(speed.label,
              style: AppTextStyles.label.copyWith(color: theme.foreground)),
        ),
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.replay_30),
          onPressed: () => _skip(context, const Duration(seconds: -30)),
        ),
        _PlayPauseButton(status: status),
        IconButton(
          iconSize: 34,
          icon: const Icon(Icons.forward_30),
          onPressed: () => _skip(context, const Duration(seconds: 30)),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.status});

  final PlayerStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return GestureDetector(
      onTap: () =>
          context.read<AudioPlayerBloc>().add(const PlayerPlayPauseToggled()),
      child: CircleAvatar(
        radius: 34,
        backgroundColor: theme.primary,
        child: status.isBusy
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(
                status.isPlaying ? Icons.pause : Icons.play_arrow,
                color: theme.onPrimary,
                size: 40,
              ),
      ),
    );
  }
}
