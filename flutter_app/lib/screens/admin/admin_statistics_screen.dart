import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../admin/admin_theme.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  final List<ProductSalesData> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? productId}) async {
    setState(() => _loading = true);
    try {
      final path = productId != null ? '/admin/stats/products/$productId' : '/admin/stats/products';
      _stats = await ApiService.get(path);
    } on ApiException catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final result = await ApiService.get('/admin/stats/products?q=${Uri.encodeComponent(query)}');
      if (result is List) {
        _searchResults.clear();
        for (var item in result) {
          _searchResults.add(ProductSalesData.fromJson(item is Map ? Map<String, dynamic>.from(item) : {}));
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        title: const Text('Thống kê sản phẩm'),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary))
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      _searchResults.clear();
                      _isSearching = false;
                    });
                  } else {
                    _searchProducts(value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Show search results or detailed stats
              if (_searchResults.isNotEmpty) ...[
                _buildSearchResults(),
              ] else if (_stats != null) ...[
                _buildDetailStats(),
              ] else if (_loading) ...[
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kết quả tìm kiếm (${_searchResults.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._searchResults.map((product) => Card(
          margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Đã bán: ${product.totalSold} | Doanh thu: ${_formatCurrency(product.revenue)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(product.avgRating.toString()),
                  ],
                ),
                onTap: () {
                  _load(productId: product.id);
                  setState(() => _searchResults.clear());
                },
              ),
            )).toList(),
      ],
    );
  }

  Widget _buildDetailStats() {
    final productName = _stats!['name'] ?? 'Sản phẩm';
    final totalSold = _stats!['total_sold'] ?? 0;
    final revenue = _stats!['revenue'] ?? 0;
    final totalReviews = _stats!['total_reviews'] ?? 0;
    final avgRating = _stats!['avg_rating'] ?? 0;
    final ratings = (_stats!['ratings'] as Map?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Danh mục: ${_stats!['category'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stat cards
        Row(
          children: [
            Expanded(child: _buildMiniCard('Đã bán', '$totalSold', Icons.shopping_cart, AdminColors.info)),
            const SizedBox(width: 8),
            Expanded(child: _buildMiniCard('Doanh thu', _formatShortRevenue(revenue), Icons.attach_money, AdminColors.success)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMiniCard('Đánh giá', '$totalReviews', Icons.rate_review, AdminColors.warning)),
            const SizedBox(width: 8),
            Expanded(child: _buildMiniCard('Điểm TB', '$avgRating', Icons.star, Colors.amber)),
          ],
        ),
        const SizedBox(height: 16),

        // Sales chart
        _buildSectionTitle('Biểu đồ số lượng bán'),
        const SizedBox(height: 8),
        Container(
          height: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (totalSold + 5).toDouble(),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= ratings.length) return const Text('');
                      final star = 5 - value.toInt();
                      return Text('$star sao', style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(5, (index) {
                final star = 5 - index;
                final count = ratings['$star'] ?? 0;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: count.toDouble(),
                      color: AdminColors.primary,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Rating distribution
        _buildSectionTitle('Phân bố đánh giá'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(5, (index) {
              final star = 5 - index;
              final count = ratings['$star'] ?? 0;
              final pct = totalReviews > 0 ? count / totalReviews : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 50, child: Text('$star sao', style: const TextStyle(fontSize: 12))),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 30, child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Recent orders
        if (_stats!['recent_orders'] != null && (_stats!['recent_orders'] as List).isNotEmpty) ...[
          _buildSectionTitle('Đơn hàng gần đây'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: (_stats!['recent_orders'] as List).asMap().entries.map((entry) {
                final order = entry.value as Map;
                final isLast = entry.key == (_stats!['recent_orders'] as List).length - 1;
                return Column(
                  children: [
                    ListTile(
                      title: Text(order['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('Khách: ${order['user_name'] ?? 'Ẩn danh'}'),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_formatCurrency(order['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AdminStatusColor.bg(order['status'] ?? ''),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AdminStatusColor.label(order['status'] ?? ''),
                              style: TextStyle(fontSize: 10, color: AdminStatusColor.text(order['status'] ?? ''), fontWeight: FontWeight.w600),
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMiniCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  String _formatCurrency(dynamic amount) {
    double value;
    if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    } else {
      value = 0.0;
    }
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(value);
  }

  String _formatShortRevenue(dynamic amount) {
    double value;
    if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    } else {
      value = 0.0;
    }
    final format = NumberFormat.compact(locale: 'vi');
    return format.format(value) + 'đ';
  }
}

class ProductSalesData {
  final int id;
  final String name;
  final int totalSold;
  final double revenue;
  final double avgRating;

  ProductSalesData({
    required this.id,
    required this.name,
    required this.totalSold,
    required this.revenue,
    required this.avgRating,
  });

  factory ProductSalesData.fromJson(Map<String, dynamic> json) {
    return ProductSalesData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      totalSold: json['total_sold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
    );
  }
}

// Dummy AdminStatusColor class to avoid compilation errors
class AdminStatusColor {
  static Color text(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipping': return Colors.blue;
      case 'delivered': return Colors.teal;
      case 'received': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  static Color bg(String status) {
    return text(status).withOpacity(0.1);
  }

  static String label(String status) {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'shipping': return 'Đang giao';
      case 'delivered': return 'Đã giao';
      case 'received': return 'Đã nhận';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}