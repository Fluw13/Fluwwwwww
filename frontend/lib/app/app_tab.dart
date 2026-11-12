import 'package:flutter/material.dart';

enum AppTab {
  home(
    path: '/',
    label: 'Trang Chủ',
    title: 'Trang Chủ',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
  ),
  search(path: '/search', label: 'Tra Cứu', title: 'Tra Cứu', icon: Icons.search, selectedIcon: Icons.search),
  scan(
    path: '/scan',
    label: 'Quét Món',
    title: 'Quét Món Ăn & Mã Vạch',
    icon: Icons.qr_code_scanner,
    selectedIcon: Icons.qr_code_scanner,
  ),
  note(
    path: '/note',
    label: 'Nhật Ký',
    title: 'Nhật Ký',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
  ),
  profile(path: '/profile', label: 'Hồ Sơ', title: 'Hồ Sơ', icon: Icons.person_outline, selectedIcon: Icons.person);

  const AppTab({
    required this.path,
    required this.label,
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
}
