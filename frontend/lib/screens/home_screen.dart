import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import 'scanner_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResultItem> _searchResults = [];
  bool _isLoading = false;

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final results = await ApiService.searchProducts(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _openDetail(String barcode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.black),
                SizedBox(height: 14),
                Text('Trợ lý AI Zero đang suy nghĩ...', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

    final detail = await ApiService.getProductByBarcode(barcode);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (detail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(detail: detail),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy dữ liệu chi tiết cho sản phẩm này.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Text(
              'Fluw',
              style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            SizedBox(width: 6),
            Icon(Icons.auto_awesome, color: Color(0xFF40C057), size: 18),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: Color(0xFF40C057)),
                SizedBox(width: 6),
                Text('AI Zero Online', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ "What are you eating?"
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Log Food', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF495057))),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hôm nay bạn đang ăn gì?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quét mã vạch hoặc gõ tên để Trợ lý Zero phân tích tức thì',
                    style: TextStyle(fontSize: 13, color: Color(0xFF868E96)),
                  ),
                  const SizedBox(height: 20),

                  // Nút Quét Camera đen tuyền dạng Pill
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScannerScreen()),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                      label: const Text(
                        'QUÉT MÃ VẠCH TỨC THÌ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141414),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Thanh tìm kiếm thủ công
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên món ăn (ví dụ: Milo, Hảo Hảo, Bánh gạo)...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF495057)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                      onPressed: _performSearch,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
            ),

            // Danh sách kết quả dạng Card bo tròn cao cấp
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lunch_dining_outlined, size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Sẵn sàng theo dõi dinh dưỡng cùng Zero\nBấm nút Quét hoặc tìm kiếm phía trên',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF1F3F5)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 50,
                                            height: 50,
                                            color: const Color(0xFFF1F3F5),
                                            child: const Icon(Icons.fastfood, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: const Color(0xFFF1F3F5),
                                          child: const Icon(Icons.fastfood, color: Colors.grey),
                                        ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    const Icon(Icons.check_circle, color: Color(0xFF1C7ED6), size: 16),
                                  ],
                                ),
                                subtitle: Text(
                                  '${item.brand} • Mã: ${item.barcode}',
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF868E96)),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Color(0xFFCED4DA)),
                                onTap: () => _openDetail(item.barcode),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
