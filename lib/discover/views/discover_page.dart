import 'dart:async';

import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/status_views.dart';
import 'package:cabina/discover/cubit/discover_cubit.dart';
import 'package:cabina/discover/widgets/show_grid.dart';
import 'package:cabina/search/views/search_page.dart';
import 'package:cabina/show_detail/views/show_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<DiscoverCubit>();
    unawaited(cubit.loadFeatured());
    unawaited(cubit.restoreFavourites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover', style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed(SearchPage.routeName),
          ),
        ],
      ),
      body: BlocConsumer<DiscoverCubit, DiscoverState>(
        listenWhen: (previous, current) =>
            current.status == DiscoverStatus.ready &&
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        // TODO(marco): If this will be the standard usage, we could extend cxt
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!))),
        builder: (context, state) {
          switch (state.status) {
            case DiscoverStatus.initial:
            case DiscoverStatus.loading:
              return const LoaderView();
            case DiscoverStatus.error:
              return ErrorView(
                message: state.errorMessage!,
                onRetry: () => context.read<DiscoverCubit>().loadFeatured(),
              );
            case DiscoverStatus.ready:
              if (state.podcasts.isEmpty) {
                return const EmptyView(message: 'No podcasts to show');
              }
              return ShowGrid(
                podcasts: state.podcasts,
                onTapPodcast: (podcast) => context.pushNamed(
                  ShowDetailPage.routeName,
                  extra: podcast,
                ),
              );
          }
        },
      ),
    );
  }
}
