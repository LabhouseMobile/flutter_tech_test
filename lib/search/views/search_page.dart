import 'package:cabina/common/theme/app_theme.dart';
import 'package:cabina/common/widgets/status_views.dart';
import 'package:cabina/discover/widgets/show_grid.dart';
import 'package:cabina/search/bloc/search_bloc.dart';
import 'package:cabina/search/data/search_repository.dart';
import 'package:cabina/show_detail/views/show_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  static const routeName = 'search';
  static const routePath = '/search';

  static GoRoute route() => GoRoute(
        path: routePath,
        name: routeName,
        builder: (context, state) => BlocProvider(
          create: (ctx) =>
              SearchBloc(searchRepository: ctx.read<SearchRepository>()),
          child: const SearchPage(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search podcasts',
            border: InputBorder.none,
            hintStyle: AppTextStyles.body.copyWith(color: theme.foregroundSoft),
          ),
            onChanged: (value) =>
                context.read<SearchBloc>().add(SearchTermChanged(value)),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          switch (state.status) {
            case SearchStatus.initial:
              return const EmptyView(
                message: 'Find your next listen',
                icon: Icons.search,
              );
            case SearchStatus.loading:
              return const LoaderView();
            case SearchStatus.error:
              return ErrorView(message: state.errorMessage ?? 'Search failed');
            case SearchStatus.ready:
              if (state.results.isEmpty) {
                return EmptyView(message: 'No results for "${state.query}"');
              }
              return ShowGrid(
                podcasts: state.results,
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
