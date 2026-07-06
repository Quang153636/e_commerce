import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import 'order_detail_screen.dart';

final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class PaymentQRScreen extends StatefulWidget {
  final int orderId;
  final String orderCode;
  final double amount;

  const PaymentQRScreen({
    super.key,
    required this.orderId,
    required this.orderCode,
    required this.amount,
  });

  @override
  State<PaymentQRScreen> createState() => _PaymentQRScreenState();
}

class _PaymentQRScreenState extends State<PaymentQRScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _qrData;
  bool _loading = true;
  bool _paid = false;
  Timer? _pollTimer;
  int _pollCount = 0;
  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadQR();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQR() async {
    try {
      final data = await PaymentService.getQRInfo(widget.orderId);
      if (data['paid'] == true) {
        setState(() { _paid = true; _loading = false; });
        return;
      }
      setState(() {
        _qrData = data;
        _loading = false;
      });
      // Bắt đầu polling mỗi 3 giây
      _startPolling();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelOrder() async {
    try {
      await OrderService.cancelOrder(widget.orderId);
    } catch (e) {
      // Ignore cancellation errors
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _pollCount++;
      // Tự dừng sau 10 phút (200 lần * 3s)
      if (_pollCount > 200) {
        _pollTimer?.cancel();
        return;
      }
      try {
        final status = await PaymentService.checkStatus(widget.orderId);
        if (status['paid'] == true && mounted) {
          _pollTimer?.cancel();
          setState(() => _paid = true);
          _successCtrl.forward();
        }
      } catch (_) {}
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _paid) return;
        
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Thoát thanh toán?'),
            content: const Text('Đơn hàng vẫn ở trạng thái chưa thanh toán. Bạn có thể quay lại thanh toán sau.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ở lại')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Thoát')),
            ],
          ),
        );
        
        if (confirm == true && !_paid) {
          await _cancelOrder();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán chuyển khoản'),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _paid
                ? _buildSuccessView()
                : _buildQRView(),
      ),
    );
  }

  // ===================== Màn hình QR =====================
  Widget _buildQRView() {
    final qr = _qrData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.5 + _pulseCtrl.value * 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Đang chờ thanh toán...', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // QR Image
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // Logo ngân hàng
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://img.vietqr.io/image/MB-logo.png',
                      height: 28,
                      errorBuilder: (_, __, ___) => const Text('MBBank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                    const SizedBox(width: 12),
                    Image.network(
                      'https://vietqr.io/img/logo.png',
                      height: 24,
                      errorBuilder: (_, __, ___) => const Text('VietQR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // QR Code image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    qr['qr_url'],
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 220,
                      height: 220,
                      child: Center(child: Icon(Icons.error_outline, color: Colors.red, size: 40)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Thông tin chuyển khoản
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Ngân hàng',
                  value: 'MBBank',
                  canCopy: false,
                ),
                const Divider(height: 16),
                _InfoRow(
                  label: 'Số tài khoản',
                  value: qr['account_no'],
                  onCopy: () => _copyToClipboard(qr['account_no']),
                ),
                const Divider(height: 16),
                _InfoRow(
                  label: 'Chủ tài khoản',
                  value: qr['account_name'],
                  canCopy: false,
                ),
                const Divider(height: 16),
                _InfoRow(
                  label: 'Số tiền',
                  value: _currency.format(qr['amount']),
                  valueColor: AppColors.primary,
                  onCopy: () => _copyToClipboard('${qr['amount']}'),
                ),
                const Divider(height: 16),
                _InfoRow(
                  label: 'Nội dung CK',
                  value: qr['description'],
                  valueColor: Colors.red.shade700,
                  onCopy: () => _copyToClipboard(qr['description']),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cảnh báo quan trọng
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 18),
                    const SizedBox(width: 6),
                    Text('Lưu ý quan trọng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                  ],
                ),
                const SizedBox(height: 8),
                _bulletPoint('Nhập đúng số tiền và nội dung chuyển khoản'),
                _bulletPoint('Nội dung CK phải chứa mã: ${qr['description']}'),
                _bulletPoint('Màn hình tự động cập nhật khi thanh toán thành công'),
                _bulletPoint('Không tắt ứng dụng trong khi chờ xác nhận'),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Đang kiểm tra trạng thái... (${_pollCount}s)',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.amber)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textDark))),
        ],
      ),
    );
  }

  // ===================== Màn hình thành công =====================
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thanh toán thành công!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Cảm ơn bạn đã mua hàng.\nĐơn hàng ${widget.orderCode} đã được xác nhận.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currency.format(widget.amount),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: widget.orderId),
                    ),
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Xem chi tiết đơn hàng'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onCopy;
  final bool canCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onCopy,
    this.canCopy = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ),
        if (canCopy && onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: const Icon(Icons.copy, size: 16, color: AppColors.textGrey),
          ),
      ],
    );
  }
}
