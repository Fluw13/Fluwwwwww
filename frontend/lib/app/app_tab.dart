import 'package:flutter/material.dart';

enum AppTab {
  home(path: '/', label: 'Trang chủ', icon: Icons.home_outlined, selectedIcon: Icons.home),
  search(path: '/search', label: 'Tìm kiếm', icon: Icons.search, selectedIcon: Icons.search),
  scan(path: '/scan', label: 'Quét', icon: Icons.qr_code_scanner, selectedIcon: Icons.qr_code_scanner),
  note(path: '/note', label: 'Note', icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book),
  profile(path: '/profile', label: 'Cá nhân', icon: Icons.person_outline, selectedIcon: Icons.person);

  const AppTab({required this.path, required this.label, required this.icon, required this.selectedIcon});

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
