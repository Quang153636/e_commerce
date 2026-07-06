import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/order.dart';
import '../../../services/admin_service.dart';
import '../admin_theme.dart';
import 'admin_order_detail_screen.dart';

final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String _selectedStatus = '';
  final _searchCtrl = TextEditingController();

  static const _statuses = ['', 'pending', 'confirmed', 'shipping', 'delivered', 'received', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _orders = await AdminService.getOrders(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Quản lý đơn hàng'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search + filter
          Container(
            color: AdminColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _load(),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm mã đơn, tên khách...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statuses.map((s) {
                      final selected = _selectedStatus == s;
                      final label = s.isEmpty ? 'Tất cả' : AdminStatusColor.label(s);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedStatus = s);
                          _load();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AdminColors.accent : Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Không có đơn hàng nào', style: TextStyle(color: AdminColors.textGrey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final o = _orders[i];
                            return GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AdminOrderDetailScreen(orderId: o.id),
                                ),
                              ).then((_) => _load()),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(o.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AdminStatusColor.bg(o.status),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            AdminStatusColor.label(o.status),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AdminStatusColor.text(o.status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 14, color: AdminColors.textGrey),
                                        const SizedBox(width: 4),
                                        Text(o.shippingPhone, style: const TextStyle(fontSize: 12, color: AdminColors.textGrey)),
                                        const Spacer(),
                                        Text(_fmt.format(o.total),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AdminColors.accent)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: AdminColors.textGrey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            o.shippingAddress,
                                            style: const TextStyle(fontSize: 11, color: AdminColors.textGrey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (o.createdAt != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(o.createdAt!),
                                        style: const TextStyle(fontSize: 11, color: AdminColors.textGrey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
