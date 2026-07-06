import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../models/order.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';
import '../admin_theme.dart';

final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  OrderModel? _order;
  bool _loading = true;
  bool _updating = false;
  String _selectedStatus = '';
  final _noteCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _shipperNameCtrl = TextEditingController();
  final _shipperPhoneCtrl = TextEditingController();

  static const _statuses = ['pending', 'confirmed', 'shipping', 'delivered', 'received', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await AdminService.getOrderDetail(widget.orderId);
      setState(() {
        _order = order;
        _selectedStatus = order.status;
        final loc = order.latestLocation;
        if (loc != null) {
          _latCtrl.text = '${loc.lat}';
          _lngCtrl.text = '${loc.lng}';
          _shipperNameCtrl.text = loc.shipperName ?? '';
          _shipperPhoneCtrl.text = loc.shipperPhone ?? '';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus() async {
    setState(() => _updating = true);
    try {
      await AdminService.updateOrderStatus(
        widget.orderId,
        _selectedStatus,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      _noteCtrl.clear();
      Fluttertoast.showToast(msg: 'Đã cập nhật trạng thái!');
      await _load();
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _updateLocation() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      Fluttertoast.showToast(msg: 'Lat/Lng không hợp lệ');
      return;
    }
    try {
      await AdminService.updateOrderLocation(
        widget.orderId,
        lat: lat,
        lng: lng,
        shipperName: _shipperNameCtrl.text.trim().isEmpty ? null : _shipperNameCtrl.text.trim(),
        shipperPhone: _shipperPhoneCtrl.text.trim().isEmpty ? null : _shipperPhoneCtrl.text.trim(),
      );
      Fluttertoast.showToast(msg: 'Đã cập nhật vị trí shipper!');
      await _load();
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }
  }

  Future<void> _confirmPayment() async {
    try {
      await AdminService.confirmPayment(widget.orderId);
      Fluttertoast.showToast(msg: 'Đã xác nhận thanh toán!');
      await _load();
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        title: Text(_order?.code ?? 'Chi tiết đơn hàng'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildOrderInfo(),
                const SizedBox(height: 12),
                _buildStatusUpdate(),
                const SizedBox(height: 12),
                if (_order!.paymentStatus == 'unpaid' && _order!.paymentMethod != 'cod')
                  _buildPaymentConfirm(),
                if (_order!.paymentStatus == 'unpaid' && _order!.paymentMethod != 'cod')
                  const SizedBox(height: 12),
                if (_order!.status == 'shipping' || _order!.status == 'confirmed')
                  _buildLocationUpdate(),
                if (_order!.status == 'shipping' || _order!.status == 'confirmed')
                  const SizedBox(height: 12),
                _buildItems(),
                const SizedBox(height: 12),
                _buildTimeline(),
              ],
            ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    final o = _order!;
    return _buildCard(
      title: 'Thông tin đơn hàng',
      child: Column(
        children: [
          _Row(label: 'Khách hàng', value: o.shippingPhone),
          _Row(label: 'Địa chỉ giao', value: o.shippingAddress),
          _Row(label: 'Thanh toán', value: o.paymentMethod.toUpperCase()),
          _Row(
            label: 'Trạng thái TT',
            value: o.paymentStatus == 'paid' ? 'Đã thanh toán' : 'Chưa thanh toán',
            valueColor: o.paymentStatus == 'paid' ? AdminColors.success : AdminColors.danger,
          ),
          _Row(
            label: 'Tổng tiền',
            value: _fmt.format(o.total),
            valueColor: AdminColors.accent,
            valueBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdate() {
    return _buildCard(
      title: 'Cập nhật trạng thái',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              filled: true,
              fillColor: AdminColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _statuses.map((s) => DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: AdminStatusColor.text(s), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(AdminStatusColor.label(s)),
                ],
              ),
            )).toList(),
            onChanged: (v) => setState(() => _selectedStatus = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              hintText: 'Ghi chú (tuỳ chọn)',
              filled: true,
              fillColor: AdminColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updating ? null : _updateStatus,
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.accent),
              child: _updating
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Cập nhật trạng thái'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentConfirm() {
    return _buildCard(
      title: 'Xác nhận thanh toán',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đơn hàng chưa được xác nhận thanh toán.',
              style: TextStyle(color: AdminColors.textGrey, fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmPayment,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Xác nhận đã nhận tiền'),
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationUpdate() {
    return _buildCard(
      title: '📍 Cập nhật vị trí shipper',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildField(_latCtrl, 'Vĩ độ (lat)', TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _buildField(_lngCtrl, 'Kinh độ (lng)', TextInputType.number)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildField(_shipperNameCtrl, 'Tên shipper', TextInputType.text)),
              const SizedBox(width: 10),
              Expanded(child: _buildField(_shipperPhoneCtrl, 'SĐT shipper', TextInputType.phone)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _updateLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Cập nhật vị trí'),
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: AdminColors.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  Widget _buildItems() {
    final items = _order!.items;
    return _buildCard(
      title: 'Sản phẩm (${items.length})',
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 13))),
              Text('x${item.quantity}', style: const TextStyle(color: AdminColors.textGrey, fontSize: 12)),
              const SizedBox(width: 8),
              Text(_fmt.format(item.price * item.quantity),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTimeline() {
    final histories = _order!.statusHistories;
    return _buildCard(
      title: 'Lịch sử trạng thái',
      child: Column(
        children: histories.reversed.map((h) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AdminStatusColor.text(h.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AdminStatusColor.label(h.status),
                        style: TextStyle(fontWeight: FontWeight.w600, color: AdminStatusColor.text(h.status), fontSize: 13)),
                    if (h.note != null)
                      Text(h.note!, style: const TextStyle(fontSize: 11, color: AdminColors.textGrey)),
                  ],
                ),
              ),
              if (h.createdAt != null)
                Text(DateFormat('dd/MM HH:mm').format(h.createdAt!),
                    style: const TextStyle(fontSize: 11, color: AdminColors.textGrey)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _Row({required this.label, required this.value, this.valueColor, this.valueBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AdminColors.textGrey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
