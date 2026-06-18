import 'package:cabina/common/network/api_client.dart';
import 'package:cabina/discover/cubit/discover_cubit.dart';
import 'package:cabina/discover/data/discover_repository.dart';
import 'package:cabina/discover/data/favourites_repository.dart';
import 'package:cabina/discover/data/services/itunes_search_service.dart';
import 'package:cabina/search/data/search_repository.dart';
import 'package:cabina/show_detail/data/services/rss_feed_service.dart';
import 'package:cabina/show_detail/data/show_detail_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wires the object graph (services → repositories → app-scoped blocs) using
/// `RepositoryProvider`/`BlocProvider`, the same manual DI approach used across
/// the Labhouse apps. Route-scoped blocs (search, show detail, player) are
/// created in the router.
class AppDependencyInjection extends StatelessWidget {
  const AppDependencyInjection({
    required this.prefs,
    required this.child,
    super.key,
  });

  final SharedPreferences prefs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => ApiClient(),
        ),
        RepositoryProvider(
          create: (ctx) =>
              ItunesSearchService(apiClient: ctx.read<ApiClient>()),
        ),
        RepositoryProvider(
          create: (ctx) => DiscoverRepository(
            searchService: ctx.read<ItunesSearchService>(),
          ),
        ),
        RepositoryProvider(
          create: (ctx) =>
              SearchRepository(searchService: ctx.read<ItunesSearchService>()),
        ),
        RepositoryProvider(
          create: (ctx) => RssFeedService(apiClient: ctx.read<ApiClient>()),
        ),
        RepositoryProvider(
          create: (ctx) =>
              ShowDetailRepository(feedService: ctx.read<RssFeedService>()),
        ),
        RepositoryProvider(
          create: (_) => FavouritesRepository(prefs: prefs),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => DiscoverCubit(
              discoverRepository: ctx.read<DiscoverRepository>(),
              favouritesRepository: ctx.read<FavouritesRepository>(),
            ),
          ),
        ],
        child: child,
      ),
    );
  }
}
