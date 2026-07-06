import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/auth/login_screen.dart';
import '../../../services/admin_service.dart';
import '../admin/admin_theme.dart';

class AdminProductStat {
  final int id;
  final String name;
  final int totalSold;
  final String? image;
  final double price;

  AdminProductStat({
    required this.id,
    required this.name,
    required this.totalSold,
    this.image,
    required this.price,
  });

  factory AdminProductStat.fromJson(Map<String, dynamic> json) {
    return AdminProductStat(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      totalSold: json['total_sold'] ?? 0,
      image: json['image'],
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
final _fmtShort = NumberFormat.compact(locale: 'vi');

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<AdminProductStat>? _topProducts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _stats = await AdminService.getDashboardStats();
      // Parse top products
      if (_stats != null && _stats!['top_products'] != null) {
        final List<dynamic> topProductsList = _stats!['top_products'] is List
            ? _stats!['top_products']
            : [];
        _topProducts = topProductsList
            .map((item) => AdminProductStat.fromJson(item is Map ? Map<String, dynamic>.from(item) : {}))
            .toList();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(auth, context),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_stats != null) ...[
                SliverToBoxAdapter(child: _buildStats()),
                SliverToBoxAdapter(child: _buildStatusChart()),
                if (_topProducts != null && _topProducts!.isNotEmpty)
                  SliverToBoxAdapter(child: _buildTopProducts()),
                SliverToBoxAdapter(child: _buildRecentOrders()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, BuildContext context) {
    return Container(
      color: AdminColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AdminColors.accent,
            child: Text(
              (auth.user?.name.isNotEmpty == true)
                  ? auth.user!.name[0].toUpperCase()
                  : 'A',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, ${auth.user?.name ?? 'Admin'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text('Bảng điều khiển quản trị',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final s = _stats!;
    final cards = [
      _StatCard(label: 'Tổng đơn', value: '${s['total_orders'] ?? 0}', icon: Icons.receipt_long, color: AdminColors.info),
      _StatCard(label: 'Doanh thu', value: _fmtShort.format(num.tryParse('${s['total_revenue']}') ?? 0) + 'đ', icon: Icons.monetization_on, color: AdminColors.success),
      _StatCard(label: 'Sản phẩm', value: '${s['total_products'] ?? 0}', icon: Icons.inventory_2, color: AdminColors.accent),
      _StatCard(label: 'Khách hàng', value: '${s['total_users'] ?? 0}', icon: Icons.people, color: AdminColors.warning),
      _StatCard(label: 'Chờ xác nhận', value: '${s['pending_orders'] ?? 0}', icon: Icons.hourglass_empty, color: AdminColors.warning),
      _StatCard(label: 'Đang giao', value: '${s['shipping_orders'] ?? 0}', icon: Icons.local_shipping, color: AdminColors.info),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: cards,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    final raw = _stats!['orders_by_status'];
    if (raw == null) return const SizedBox();

    final Map<String, dynamic> byStatus = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    if (byStatus.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạng thái đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: byStatus.entries.map((e) {
                final total = byStatus.values.fold<int>(0, (s, v) => s + (v as int? ?? 0));
                final pct = total > 0 ? (e.value as int) / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AdminStatusColor.text(e.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: Text(AdminStatusColor.label(e.key),
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation(AdminStatusColor.text(e.key)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final products = _topProducts!;
    if (products.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sản phẩm bán chạy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: products.asMap().entries.map((entry) {
                final p = entry.value;
                final isLast = entry.key == products.length - 1;
                return Column(
                  children: [
                    ListTile(
                      leading: p.image != null && p.image!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p.image!.startsWith('http') ? p.image! : 'http://10.0.2.2:8000/${p.image}',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.inventory_2, size: 20, color: Colors.grey),
                                ),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: Colors.grey[200],
                              child: const Icon(Icons.inventory_2, size: 20, color: Colors.grey),
                            ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Đã bán: ${p.totalSold}'),
                      trailing: Text(
                        _fmtShort.format(p.price),
                        style: TextStyle(fontWeight: FontWeight.w700, color: AdminColors.accent, fontSize: 12),
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    final orders = (_stats!['recent_orders'] as List?) ?? [];
    if (orders.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đơn hàng mới nhất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: orders.asMap().entries.map((entry) {
                final o = entry.value as Map;
                final isLast = entry.key == orders.length - 1;
                return Column(
                  children: [
                    ListTile(
                      title: Text(o['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(o['user']?['name'] ?? 'Ẩn danh', style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _fmt.format(double.tryParse('${o['total']}') ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AdminColors.accent),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AdminStatusColor.bg(o['status'] ?? ''),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AdminStatusColor.label(o['status'] ?? ''),
                              style: TextStyle(fontSize: 10, color: AdminStatusColor.text(o['status'] ?? ''), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label, style: const TextStyle(color: AdminColors.textGrey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}