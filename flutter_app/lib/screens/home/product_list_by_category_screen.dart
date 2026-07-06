import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';

class ProductListByCategoryScreen extends StatefulWidget {
  final List<Category> categories;
  const ProductListByCategoryScreen({super.key, required this.categories});

  @override
  State<ProductListByCategoryScreen> createState() => _ProductListByCategoryScreenState();
}

class _ProductListByCategoryScreenState extends State<ProductListByCategoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sản phẩm theo mục'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: widget.categories.map((c) => Tab(text: c.name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.categories.map((c) => _CategoryProductGrid(category: c)).toList(),
      ),
    );
  }
}

class _CategoryProductGrid extends StatefulWidget {
  final Category category;
  const _CategoryProductGrid({required this.category});

  @override
  State<_CategoryProductGrid> createState() => _CategoryProductGridState();
}

class _CategoryProductGridState extends State<_CategoryProductGrid>
    with AutomaticKeepAliveClientMixin {
  List<Product> _products = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await ProductService.getProducts(categoryId: widget.category.id);
    if (mounted) setState(() {
      _products = products;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_products.isEmpty) return const Center(child: Text('Chưa có sản phẩm trong mục này'));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) => ProductCard(product: _products[index]),
    );
  }
}
