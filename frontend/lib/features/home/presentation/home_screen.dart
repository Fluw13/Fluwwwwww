import 'package:flutter/material.dart';
import 'package:fluw/core/widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.insights_outlined,
      title: 'Tổng quan dinh dưỡng hôm nay',
      message: 'Đang xây dựng. Màn này sẽ hiện calo và protein đã nạp so với mục tiêu của bạn.',
    );
  }
}
