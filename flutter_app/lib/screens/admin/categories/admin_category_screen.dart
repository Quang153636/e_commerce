import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../models/category.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';
import '../admin_theme.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  List<Category> _categories = [];
  bool _loading = true;
  final _nameCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _categories = await AdminService.getCategories();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddDialog() async {
    _nameCtrl.clear();
    _iconCtrl.clear();
    await showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        title: 'Thêm danh mục mới',
        nameCtrl: _nameCtrl,
        iconCtrl: _iconCtrl,
        onConfirm: () async {
          if (_nameCtrl.text.trim().isEmpty) {
            Fluttertoast.showToast(msg: 'Tên danh mục không được để trống');
            return;
          }
          try {
            await AdminService.createCategory(
              _nameCtrl.text.trim(),
              icon: _iconCtrl.text.trim().isEmpty ? null : _iconCtrl.text.trim(),
            );
            if (mounted) Navigator.pop(context);
            Fluttertoast.showToast(msg: 'Đã thêm danh mục!');
            _load();
          } on ApiException catch (e) {
            Fluttertoast.showToast(msg: e.message);
          }
        },
      ),
    );
  }

  Future<void> _showEditDialog(Category category) async {
    _nameCtrl.text = category.name;
    _iconCtrl.text = category.icon ?? '';
    await showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        title: 'Sửa danh mục',
        nameCtrl: _nameCtrl,
        iconCtrl: _iconCtrl,
        onConfirm: () async {
          if (_nameCtrl.text.trim().isEmpty) {
            Fluttertoast.showToast(msg: 'Tên danh mục không được để trống');
            return;
          }
          try {
            await AdminService.updateCategory(
              category.id,
              _nameCtrl.text.trim(),
              icon: _iconCtrl.text.trim().isEmpty ? null : _iconCtrl.text.trim(),
            );
            if (mounted) Navigator.pop(context);
            Fluttertoast.showToast(msg: 'Đã cập nhật danh mục!');
            _load();
          } on ApiException catch (e) {
            Fluttertoast.showToast(msg: e.message);
          }
        },
      ),
    );
  }

  Future<void> _delete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá danh mục'),
        content: Text(
          'Xoá "${category.name}"?\n\nCảnh báo: Tất cả sản phẩm trong danh mục này cũng sẽ bị xoá!',
        ),
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
      await AdminService.deleteCategory(category.id);
      Fluttertoast.showToast(msg: 'Đã xoá danh mục!');
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
        title: const Text('Quản lý danh mục'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Chưa có danh mục nào',
                          style: TextStyle(color: AdminColors.textGrey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm danh mục'),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminColors.accent),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Column(
                    children: [
                      // Summary bar
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              '${_categories.length} danh mục',
                              style: const TextStyle(
                                  color: AdminColors.textGrey, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showAddDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AdminColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('Thêm mới',
                                        style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final cat = _categories[i];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AdminColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.category_outlined,
                                      color: AdminColors.accent, size: 22),
                                ),
                                title: Text(cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (cat.icon != null && cat.icon!.isNotEmpty)
                                      Text('Icon: ${cat.icon}',
                                          style: const TextStyle(fontSize: 11, color: AdminColors.textGrey)),
                                    Text('Slug: ${cat.slug}',
                                        style: const TextStyle(fontSize: 11, color: AdminColors.textGrey)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AdminColors.info, size: 20),
                                      onPressed: () => _showEditDialog(cat),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AdminColors.danger, size: 20),
                                      onPressed: () => _delete(cat),
                                    ),
                                  ],
                                ),
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

class _CategoryDialog extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController iconCtrl;
  final VoidCallback onConfirm;

  const _CategoryDialog({
    required this.title,
    required this.nameCtrl,
    required this.iconCtrl,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Tên danh mục *',
              filled: true,
              fillColor: AdminColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: iconCtrl,
            decoration: InputDecoration(
              labelText: 'Icon (phone, shirt, book...)',
              filled: true,
              fillColor: AdminColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
