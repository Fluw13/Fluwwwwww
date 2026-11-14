import 'package:flutter/widgets.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/shell/app_shell.dart';
import 'package:fluw/features/home/presentation/home_screen.dart';
import 'package:fluw/features/note/presentation/note_screen.dart';
import 'package:fluw/features/profile/presentation/profile_screen.dart';
import 'package:fluw/features/profile/presentation/profile_setup_screen.dart';
import 'package:fluw/features/scan/presentation/scan_screen.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/presentation/food_detail_screen.dart';
import 'package:fluw/features/search/presentation/search_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String profileSetup = '/profile/setup';
  static const String foodDetail = '/search/food';
}

GoRouter createAppRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppTab.home.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (context, state) => _screenFor(context, tab),
                  routes: [
                    if (tab == AppTab.search)
                      GoRoute(
                        path: 'food',
                        parentNavigatorKey: rootNavigatorKey,
                        // The item travels in memory; a restored route without it goes back to the search tab.
                        redirect: (context, state) => state.extra is FoodItem ? null : AppTab.search.path,
                        builder: (context, state) => FoodDetailScreen(item: state.extra! as FoodItem),
                      ),
                    if (tab == AppTab.profile)
                      GoRoute(
                        // Full screen above the tab bar, like the design's setup page with its own back button.
                        path: 'setup',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => const ProfileSetupScreen(),
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

Widget _screenFor(BuildContext context, AppTab tab) {
  return switch (tab) {
    AppTab.home => const HomeScreen(),
    AppTab.search => SearchScreen(onOpenFood: (item) => context.push(AppRoutes.foodDetail, extra: item)),
    AppTab.scan => const ScanScreen(),
    AppTab.note => const NoteScreen(),
    AppTab.profile => ProfileScreen(onEditProfile: () => context.push(AppRoutes.profileSetup)),
  };
}
