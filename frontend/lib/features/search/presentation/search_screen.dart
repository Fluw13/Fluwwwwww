import 'package:flutter/material.dart';
import 'package:fluw/core/widgets/empty_state.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.search,
      title: 'Tra cứu thực phẩm',
      message:
          'Đang xây dựng. Bạn sẽ tra được calo, protein và đường của đồ đóng gói, trái cây, món nấu chín và bánh kẹo.',
    );
  }
}
