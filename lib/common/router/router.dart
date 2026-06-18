import 'package:cabina/home/home_page.dart';
import 'package:cabina/player/views/player_page.dart';
import 'package:cabina/search/views/search_page.dart';
import 'package:cabina/show_detail/views/show_detail_page.dart';
import 'package:go_router/go_router.dart';

class RouterBuilder {
  static GoRouter build() {
    return GoRouter(
      initialLocation: HomePage.routePath,
      routes: [
        HomePage.route(),
        SearchPage.route(),
        ShowDetailPage.route(),
        PlayerPage.route(),
      ],
    );
  }
}
