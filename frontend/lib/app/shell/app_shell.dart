import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/app/app_router.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/shell/fluw_bottom_bar.dart';
import 'package:fluw/app/shell/fluw_top_bar.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = AppTab.values[navigationShell.currentIndex];
    void open(AppTab tab) => _open(ref, tab);

    return Scaffold(
      appBar: FluwTopBar(
        title: currentTab.title,
        onProfileTap: () => open(AppTab.profile),
        onRemindersTap: () => context.push(AppRoutes.reminders),
      ),
      body: navigationShell,
      bottomNavigationBar: FluwBottomBar(currentTab: currentTab, onSelected: open),
    );
  }

  void _open(WidgetRef ref, AppTab tab) {
    // Leaving the search and scan tabs ends the "add to this slot" flow started from Home or the diary, so a later
    // add does not land in a slot chosen hours ago.
    if (tab != AppTab.search && tab != AppTab.scan) {
      ref.read(diaryTargetProvider.notifier).choose(null);
    }
    navigationShell.goBranch(tab.index, initialLocation: tab.index == navigationShell.currentIndex);
  }
}
