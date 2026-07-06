import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import 'order_detail_screen.dart';
import 'order_list_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;
  final bool isMultiple;
  const OrderSuccessScreen({super.key, required this.order, this.isMultiple = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 88),
              const SizedBox(height: 20),
              Text(
                isMultiple ? 'Các đơn hàng đã được đặt!' : 'Đặt hàng thành công!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isMultiple 
                    ? 'Mỗi sản phẩm trong giỏ hàng đã được tách thành một đơn hàng riêng biệt.'
                    : 'Mã đơn hàng: ${order.code}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Chuyển thẳng về danh sách đơn hàng để xem tất cả đơn vừa tạo
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OrderListScreen()),
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text('Xem danh sách đơn hàng'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Tiếp tục mua sắm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
