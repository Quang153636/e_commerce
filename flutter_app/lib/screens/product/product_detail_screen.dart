import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../services/api_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../auth/login_screen.dart';
import '../order/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  int _imageIndex = 0;
  int _quantity = 1;
  final Map<String, String> _selectedVariants = {}; // Lưu biến thể đã chọn
  ProductVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final product = await ProductService.getProductDetail(widget.productId);
    if (mounted) {
      setState(() {
        _product = product;
        _loading = false;
      });
    }
  }

  bool _requireLogin() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return false;
    }
    return true;
  }

  // Tìm variant phù hợp với lựa chọn hiện tại
  ProductVariant? _findMatchingVariant() {
    if (_product!.variants.isEmpty || _selectedVariants.isEmpty) return null;
    
    return _product!.variants.firstWhere(
      (variant) {
        for (final entry in _selectedVariants.entries) {
          if (variant.attributes[entry.key] != entry.value) return false;
        }
        return true;
      },
      orElse: () => _product!.variants.first,
    );
  }

  double get _currentPrice {
    if (_selectedVariant != null && _selectedVariant!.price != null) {
      return _selectedVariant!.price!;
    }
    return _product!.displayPrice;
  }

  bool get _hasVariants => _product!.variantTypes.isNotEmpty;

  bool get _allVariantsSelected {
    if (!_hasVariants) return true;
    return _product!.variantTypes.every((type) => _selectedVariants.containsKey(type.name));
  }

  int get _currentStock {
    if (_selectedVariant != null) {
      return _selectedVariant!.stock;
    }
    return _product!.stock;
  }

  bool get _canPurchase {
    if (!_allVariantsSelected) return false;
    if (_hasVariants && _selectedVariant == null) return false;
    return _currentStock > 0;
  }

  String? _getPurchaseDisabledReason() {
    if (!_allVariantsSelected) {
      final missing = _product!.variantTypes
          .where((type) => !_selectedVariants.containsKey(type.name))
          .map((t) => t.name)
          .join(', ');
      return 'Vui lòng chọn: $missing';
    }
    if (_hasVariants && _selectedVariant != null && _selectedVariant!.stock <= 0) {
      return 'Loại sản phẩm này đã hết hàng';
    }
    return null;
  }

  Future<void> _addToCart() async {
    if (!_requireLogin()) return;
    
    final reason = _getPurchaseDisabledReason();
    if (reason != null) {
      Fluttertoast.showToast(msg: reason);
      return;
    }

    try {
      await context.read<CartProvider>().addToCart(
        _product!.id,
        quantity: _quantity,
        variantId: _selectedVariant?.id,
      );
      Fluttertoast.showToast(msg: 'Đã thêm vào giỏ hàng');
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }
  }

  void _buyNow() {
    if (!_requireLogin()) return;
    
    final reason = _getPurchaseDisabledReason();
    if (reason != null) {
      Fluttertoast.showToast(msg: reason);
      return;
    }

    Map<String, dynamic> itemData = {
      'product_id': _product!.id,
      'quantity': _quantity,
    };
    
    // Thêm thông tin variant khi mua ngay
    if (_selectedVariant != null) {
      itemData['variant_id'] = _selectedVariant!.id;
      itemData['variant_info'] = Map<String, String>.from(_selectedVariant!.attributes);
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        directItems: [itemData],
        directProducts: [_product!],
        directQuantities: [_quantity],
      ),
    ));
  }

  void _selectVariant(String typeName, String value) {
    setState(() {
      _selectedVariants[typeName] = value;
      _selectedVariant = _findMatchingVariant();
      if (_product != null) {
        _product!.selectedVariant = _selectedVariant;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _product == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final product = _product!;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final isFav = favoriteProvider.isFavorite(product.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            expandedHeight: 340,
            leading: const BackButton(color: Colors.black),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty
                        ? product.images[_imageIndex]
                        : product.thumbnail,
                    fit: BoxFit.cover,
                  ),
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(product.images.length, (i) {
                          return GestureDetector(
                            onTap: () => setState(() => _imageIndex = i),
                            child: Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _imageIndex ? AppColors.primary : Colors.white,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(product.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        onPressed: () {
                          if (!_requireLogin()) return;
                          favoriteProvider.toggleFavorite(product);
                        },
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppColors.danger : AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${product.rating > 0 ? product.rating.toInt() : 0} sao',
                          style: const TextStyle(color: AppColors.textGrey)),
                      const SizedBox(width: 12),
                      Text('Tổng sản phẩm trong kho: ${product.stock}', style: const TextStyle(color: AppColors.textGrey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currencyFormatter.format(_currentPrice),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      if (product.hasDiscount && _selectedVariant == null) ...[
                        const SizedBox(width: 10),
                        Text(currencyFormatter.format(product.price),
                            style: const TextStyle(
                                color: AppColors.textGrey, decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedVariant != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedVariant!.attributes.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(' • '),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_selectedVariant!.sku != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SKU: ${_selectedVariant!.sku}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Tồn kho: ${_currentStock > 0 ? _currentStock : "Hết hàng"}',
                        style: TextStyle(
                          color: _currentStock > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ] else if (_hasVariants && !_allVariantsSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vui lòng chọn loại sản phẩm để xem giá và tồn kho',
                              style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 32),
                  const Text('Mô tả sản phẩm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description ?? 'Chưa có mô tả',
                      style: const TextStyle(color: AppColors.textGrey, height: 1.5)),
                  const SizedBox(height: 16),
                  if (product.variantTypes.isNotEmpty) ...[
                    ...product.variantTypes.map((type) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: type.options.map((option) {
                              final isSelected = _selectedVariants[type.name] == option;
                              return ChoiceChip(
                                label: Text(option),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) _selectVariant(type.name, option);
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    if (_hasVariants && !_allVariantsSelected)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.orange[50],
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vui lòng chọn đầy đủ loại sản phẩm trước khi mua',
                                style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  Row(
                    children: [
                      const Text('Số lượng:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => setState(() {
                          if (_quantity > 1) _quantity--;
                        }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_quantity', style: const TextStyle(fontSize: 16)),
                      IconButton(
                        onPressed: () => setState(() {
                          if (_quantity < _currentStock) _quantity++;
                        }),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  const Divider(height: 32),
                  const Text('Đánh giá sản phẩm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (product.reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có đánh giá nào',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...product.reviews.map((review) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    (review.userName ?? '?')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    review.userName ?? 'Ẩn danh',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < review.rating ? Icons.star : Icons.star_border,
                                      size: 14,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (review.comment != null && review.comment!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(review.comment!,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canPurchase ? _addToCart : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Thêm vào giỏ'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canPurchase ? _buyNow : null,
                  child: const Text('Mua ngay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
