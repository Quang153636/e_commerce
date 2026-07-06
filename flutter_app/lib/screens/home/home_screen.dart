import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import 'product_list_by_category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loading = true;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ProductService.getCategories(),
        ProductService.getProducts(
          categoryId: _selectedCategoryId,
          query: _searchCtrl.text.trim(),
        ),
      ]);
      _categories = results[0] as List<Category>;
      _products = results[1] as List<Product>;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Find your perfect match',
                        style: TextStyle(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      // Minimalist Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textDark.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onSubmitted: (_) => _loadData(),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey, size: 20),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                                onPressed: _loadData,
                              ),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories - Pill Style
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: _loading && _categories.isEmpty
                      ? const SizedBox()
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length + 1,
                          itemBuilder: (context, index) {
                            final isAll = index == 0;
                            final category = isAll ? null : _categories[index - 1];
                            final selected = isAll
                                ? _selectedCategoryId == null
                                : _selectedCategoryId == category!.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedCategoryId = isAll ? null : category!.id);
                                _loadData();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: selected
                                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  isAll ? 'All' : category!.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                    color: selected ? Colors.white : AppColors.textGrey,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Product Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                sliver: _loading
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(80),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : _products.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(80),
                                child: Text('No products found', style: TextStyle(color: AppColors.textGrey)),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => ProductCard(product: _products[index]),
                              childCount: _products.length,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
