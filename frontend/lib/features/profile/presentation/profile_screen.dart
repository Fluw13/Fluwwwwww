import 'package:flutter/material.dart';
import 'package:fluw/core/widgets/empty_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.person_outline,
      title: 'Hồ sơ sức khỏe',
      message:
          'Đang xây dựng. Nhập chiều cao, cân nặng, mục tiêu, dị ứng và bệnh lý để Fluw tính nhu cầu calo và protein.',
    );
  }
}
