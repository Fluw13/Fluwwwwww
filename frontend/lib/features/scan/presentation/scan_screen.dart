import 'package:flutter/material.dart';
import 'package:fluw/core/widgets/empty_state.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét')),
      body: const EmptyState(
        icon: Icons.qr_code_scanner,
        title: 'Quét thực phẩm',
        message: 'Đang xây dựng. Có hai chế độ: quét mã vạch sản phẩm và chụp ảnh để nhận diện thực phẩm tươi.',
      ),
    );
  }
}
