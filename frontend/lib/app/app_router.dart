import 'package:flutter/widgets.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/erase_all_data_flow.dart';
import 'package:fluw/app/shell/app_shell.dart';
import 'package:fluw/features/home/presentation/home_screen.dart';
import 'package:fluw/features/note/presentation/note_screen.dart';
import 'package:fluw/features/privacy/presentation/privacy_screen.dart';
import 'package:fluw/features/profile/presentation/profile_screen.dart';
import 'package:fluw/features/profile/presentation/profile_setup_screen.dart';
import 'package:fluw/features/reminders/presentation/reminder_settings_screen.dart';
import 'package:fluw/features/scan/presentation/scan_screen.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/presentation/barcode_lookup_screen.dart';
import 'package:fluw/features/search/presentation/food_detail_screen.dart';
import 'package:fluw/features/search/presentation/search_screen.dart';
import 'package:go_router/go_router.dart';

abstract final class AppRoutes {
  static const String profileSetup = '/profile/setup';
  static const String foodDetail = '/search/food';
  static const String reminders = '/reminders';
  static const String privacy = '/privacy';

  static String foodBarcode(String code) => '/search/barcode/$code';
}

GoRouter createAppRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppTab.home.path,
    routes: [
      // Opened from the header bell on any tab, so it sits outside the tab branches, above the tab bar.
      GoRoute(path: AppRoutes.reminders, builder: (context, state) => const ReminderSettingsScreen()),
      // Opened from the profile tab, the setup form and the photo consent, so it also sits above the tab bar.
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => PrivacyScreen(
          onEraseAllData: () async {
            final router = GoRouter.of(context);
            if (await confirmAndEraseAllData(context)) {
              // The profile tab now offers to set up a new profile.
              router.pop();
              router.go(AppTab.profile.path);
            }
          },
        ),
      ),
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
                    if (tab == AppTab.search)
                      GoRoute(
                        path: 'barcode/:code',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => BarcodeLookupScreen(
                          code: state.pathParameters['code']!,
                          // Pop first: the scan tab waits for this page's push to complete before it scans again,
                          // and a `go` that only replaces the page never completes it.
                          onSearchByName: () {
                            final router = GoRouter.of(context);
                            router.pop();
                            router.go(AppTab.search.path);
                          },
                        ),
                      ),
                    if (tab == AppTab.profile)
                      GoRoute(
                        // Full screen above the tab bar, like the design's setup page with its own back button.
                        path: 'setup',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) =>
                            ProfileSetupScreen(onOpenPrivacy: () => context.push(AppRoutes.privacy)),
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
    AppTab.home => HomeScreen(
      onOpenSearch: () => context.go(AppTab.search.path),
      onOpenScan: () => context.go(AppTab.scan.path),
      onOpenNote: () => context.go(AppTab.note.path),
      onOpenProfile: () => context.go(AppTab.profile.path),
      onSetupProfile: () => context.push(AppRoutes.profileSetup),
    ),
    AppTab.search => SearchScreen(onOpenFood: (item) => context.push(AppRoutes.foodDetail, extra: item)),
    AppTab.scan => ScanScreen(
      onBarcode: (code) => context.push<void>(AppRoutes.foodBarcode(code)),
      onOpenSearch: () => context.go(AppTab.search.path),
      onOpenPrivacy: () => context.push(AppRoutes.privacy),
    ),
    AppTab.note => NoteScreen(onAddFood: () => context.go(AppTab.search.path)),
    AppTab.profile => ProfileScreen(
      onEditProfile: () => context.push(AppRoutes.profileSetup),
      onOpenPrivacy: () => context.push(AppRoutes.privacy),
      onEraseAllData: () => confirmAndEraseAllData(context),
    ),
  };
}
