import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../auth/login_screen.dart';
import '../order/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          if (auth.isLoggedIn && cart.items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Xoá giỏ hàng'),
                    content: const Text('Bạn có chắc muốn xoá toàn bộ giỏ hàng?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoá', style: TextStyle(color: AppColors.danger))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  context.read<CartProvider>().clearCart();
                }
              },
              child: const Text('Xoá tất cả', style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: !auth.isLoggedIn
          ? const _LoginPrompt()
          : cart.loading
          ? const Center(child: CircularProgressIndicator())
          : cart.items.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text('Giỏ hàng của bạn đang trống',
                style: TextStyle(color: AppColors.textGrey)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () => cart.fetchCart(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          itemCount: cart.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = cart.items[index];
            final product = item.product;
            final thumbnail = product.thumbnail;

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh sản phẩm — dùng Image.network thay CachedNetworkImage tránh lỗi
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: thumbnail.isNotEmpty
                          ? Image.network(
                        thumbnail,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderImage(),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _PlaceholderImage();
                        },
                      )
                          : _PlaceholderImage(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(product.displayPrice),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () {
                                  if (item.quantity > 1) {
                                    cart.updateQuantity(item.id, item.quantity - 1);
                                  } else {
                                    cart.removeItem(item.id);
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () => cart.updateQuantity(
                                    item.id, item.quantity + 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.danger),
                          onPressed: () => cart.removeItem(item.id),
                        ),
                        Text(
                          currencyFormatter.format(item.subtotal),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: (auth.isLoggedIn && cart.items.isNotEmpty)
          ? SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.itemCount} sản phẩm',
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                    Text(
                      currencyFormatter.format(cart.total),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: const Text('Đặt hàng'),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Đăng nhập để xem giỏ hàng',
              style: TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }
}