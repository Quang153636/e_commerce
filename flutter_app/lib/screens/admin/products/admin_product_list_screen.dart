import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../models/product.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';
import '../admin_theme.dart';
import 'admin_product_form_screen.dart';

final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  List<Product> _products = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _products = await AdminService.getProducts(
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá sản phẩm'),
        content: Text('Bạn chắc muốn xoá "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: AdminColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminService.deleteProduct(product.id);
      Fluttertoast.showToast(msg: 'Đã xoá sản phẩm');
      _load();
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
        title: const Text('Quản lý sản phẩm'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminProductFormScreen()),
            ).then((_) => _load()),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AdminColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
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
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Không có sản phẩm nào'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = _products[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: p.thumbnail.isNotEmpty
                                      ? Image.network(
                                          p.thumbnail,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 52,
                                            height: 52,
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.image_not_supported_outlined),
                                          ),
                                        )
                                      : Container(
                                          width: 52,
                                          height: 52,
                                          color: Colors.grey.shade100,
                                          child: const Icon(Icons.inventory_2_outlined),
                                        ),
                                ),
                                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmt.format(p.displayPrice),
                                        style: const TextStyle(color: AdminColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('Kho: ${p.stock}   ★ ${p.rating}',
                                        style: const TextStyle(fontSize: 11, color: AdminColors.textGrey)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: p.isActive ? AdminColors.success.withOpacity(0.1) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.isActive ? 'Hiện' : 'Ẩn',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: p.isActive ? AdminColors.success : AdminColors.textGrey,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AdminColors.info, size: 20),
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => AdminProductFormScreen(product: p)),
                                      ).then((_) => _load()),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AdminColors.danger, size: 20),
                                      onPressed: () => _delete(p),
                                    ),
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
