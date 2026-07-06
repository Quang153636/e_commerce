import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../auth/login_screen.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (context.read<AuthProvider>().isLoggedIn) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // 1. Lấy danh sách đơn hàng cơ bản
      final basicOrders = await OrderService.getOrders();
      
      // 2. Mẹo: Gọi thêm API chi tiết cho từng đơn hàng để lấy dữ liệu ảnh (vì API danh sách bị thiếu)
      // Future.wait sẽ chạy tất cả các yêu cầu cùng một lúc để tiết kiệm thời gian
      final detailedOrders = await Future.wait(
        basicOrders.map((order) => OrderService.getOrderDetail(order.id))
      );
      
      if (mounted) {
        setState(() {
          _orders = detailedOrders;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải đơn hàng: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'shipping':
        return Colors.blue;
      case 'delivered':
        return Colors.teal;
      case 'received':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      body: !auth.isLoggedIn
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Đăng nhập để xem đơn hàng'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
                  ? const Center(child: Text('Bạn chưa có đơn hàng nào'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(orderId: order.id)),
                              ).then((_) => _load());
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textDark.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(order.code,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _statusColor(order.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          order.statusLabel,
                                          style: TextStyle(
                                              color: _statusColor(order.status),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (order.createdAt != null)
                                              Text(
                                                DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt!),
                                                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                                              ),
                                            const SizedBox(height: 8),
                                            Text(currencyFormatter.format(order.total),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary,
                                                    fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                      if (order.items.isNotEmpty)
                                        SizedBox(
                                          height: 52,
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            itemCount: order.items.length > 3 ? 3 : order.items.length,
                                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                                            itemBuilder: (context, i) {
                                              final item = order.items[i];
                                              final img = item.productImage;
                                              
                                              // Copy chính xác logic từ OrderDetailScreen (Trang bạn bảo là hiện được ảnh)
                                              final imageUrl = (img != null && img.isNotEmpty)
                                                  ? (img.startsWith('http')
                                                      ? img
                                                      : 'http://10.0.2.2:8000/$img')
                                                  : '';
                                              
                                              return Container(
                                                width: 52,
                                                height: 52,
                                                margin: const EdgeInsets.only(right: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: AppColors.background, width: 1.5),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                                          loadingBuilder: (_, child, progress) => 
                                                            progress == null ? child : _buildPlaceholder(loading: true),
                                                        )
                                                      : _buildPlaceholder(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildPlaceholder({bool loading = false}) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: loading 
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.image_outlined, size: 18, color: AppColors.textGrey),
      ),
    );
  }
}
