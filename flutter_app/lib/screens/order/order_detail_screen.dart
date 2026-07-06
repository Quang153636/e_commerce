import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import 'order_tracking_map_screen.dart';
import 'review_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _loading = true;

  static const List<String> _timelineSteps = [
    'pending', 'confirmed', 'shipping', 'delivered', 'received',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _order = await OrderService.getOrderDetail(widget.orderId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReceived() async {
    try {
      await OrderService.confirmReceived(widget.orderId);
      Fluttertoast.showToast(msg: 'Đã xác nhận nhận hàng. Cảm ơn bạn!');
      _load();
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }
  }

  Future<void> _cancelOrder() async {
    try {
      await OrderService.cancelOrder(widget.orderId);
      Fluttertoast.showToast(msg: 'Đã hủy đơn hàng');
      _load();
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final order = _order!;
    final canReview = order.status == 'received';
    final currentStepIndex = _timelineSteps.indexOf(order.status);

    return Scaffold(
      appBar: AppBar(title: Text('Đơn hàng ${order.code}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (order.status != 'cancelled') ...[
              const Text('Trạng thái đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _StatusTimeline(currentStepIndex: currentStepIndex, steps: _timelineSteps),
              const SizedBox(height: 20),
              if (order.status == 'shipping' || order.status == 'delivered')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OrderTrackingMapScreen(orderId: order.id)),
                      );
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Theo dõi vị trí đơn hàng trên bản đồ'),
                  ),
                ),
              const SizedBox(height: 12),
              if (order.status == 'delivered')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmReceived,
                    child: const Text('Xác nhận đã nhận hàng'),
                  ),
                ),
              if (order.status == 'pending' || order.status == 'confirmed')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelOrder,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger)),
                    child: const Text('Hủy đơn hàng'),
                  ),
                ),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Đơn hàng đã bị hủy', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            const Divider(height: 32),
            const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...order.items.map((item) {
              final imageUrl = (item.productImage != null && item.productImage!.isNotEmpty)
                  ? (item.productImage!.startsWith('http')
                      ? item.productImage!
                      : 'http://10.0.2.2:8000/${item.productImage}')
                  : '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: AppColors.background,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: AppColors.textGrey, size: 24),
                              )
                            : const Icon(Icons.image_not_supported_outlined, color: AppColors.textGrey, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          if (item.variantInfo != null && item.variantInfo!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.variantInfo!.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text('x${item.quantity}', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                          if (canReview && !item.hasReview) ...[
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReviewScreen(
                                      orderId: order.id,
                                      orderItemId: item.id,
                                      productName: item.productName,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _load();
                                }
                              },
                              icon: const Icon(Icons.rate_review_outlined, size: 16),
                              label: const Text('Đánh giá', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ],
                          if (item.hasReview)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text('Đã đánh giá', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(currencyFormatter.format(item.price * item.quantity),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }),
            const Divider(height: 32),
            _InfoRow(label: 'Địa chỉ giao hàng', value: order.shippingAddress),
            _InfoRow(label: 'Số điện thoại', value: order.shippingPhone),
            _InfoRow(
                label: 'Phương thức thanh toán',
                value: order.paymentMethod == 'vietinbank' ? 'VietinBank QR' : order.paymentMethod.toUpperCase()),
            _InfoRow(
                label: 'Trạng thái thanh toán',
                value: order.paymentStatus == 'paid' ? 'Đã trả tiền' : 'Chưa thanh toán'),
            if (order.createdAt != null)
              _InfoRow(
                  label: 'Ngày đặt', value: DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!)),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(currencyFormatter.format(order.total),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final int currentStepIndex;
  final List<String> steps;
  const _StatusTimeline({required this.currentStepIndex, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= currentStepIndex;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i != 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= currentStepIndex ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.primary : Colors.grey.shade300,
                    ),
                    child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < currentStepIndex ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                OrderModel.statusLabels[steps[i]] ?? steps[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: done ? AppColors.primary : AppColors.textGrey,
                  fontWeight: done ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textGrey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
