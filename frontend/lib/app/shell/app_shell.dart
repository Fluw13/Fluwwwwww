import 'package:flutter/material.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/shell/fluw_bottom_bar.dart';
import 'package:fluw/app/shell/fluw_top_bar.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentTab = AppTab.values[navigationShell.currentIndex];

    return Scaffold(
      appBar: FluwTopBar(title: currentTab.title, onProfileTap: () => _open(AppTab.profile)),
      body: navigationShell,
      bottomNavigationBar: FluwBottomBar(currentTab: currentTab, onSelected: _open),
    );
  }

  void _open(AppTab tab) {
    navigationShell.goBranch(tab.index, initialLocation: tab.index == navigationShell.currentIndex);
  }
}
