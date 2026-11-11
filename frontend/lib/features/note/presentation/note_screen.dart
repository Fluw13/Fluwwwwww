import 'package:flutter/material.dart';
import 'package:fluw/core/widgets/empty_state.dart';

class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Note')),
      body: const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Note ăn uống',
        message: 'Đang xây dựng. Món bạn thêm sẽ được xếp theo ngày và 4 khung giờ, kèm tổng calo và protein.',
      ),
    );
  }
}
