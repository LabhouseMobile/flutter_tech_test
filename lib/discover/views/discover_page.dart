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
    unawaited(context.read<DiscoverCubit>().loadFeatured());
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
      body: BlocBuilder<DiscoverCubit, DiscoverState>(
        builder: (context, state) {
          switch (state.status) {
            case DiscoverStatus.initial:
            case DiscoverStatus.loading:
              return const LoaderView();
            case DiscoverStatus.error:
              return ErrorView(
                message: state.errorMessage ?? 'Something went wrong',
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
