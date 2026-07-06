import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/product_card.dart';
import '../auth/login_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<FavoriteProvider>().fetchFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm yêu thích')),
      body: !auth.isLoggedIn
          ? _LoginPrompt()
          : favoriteProvider.loading
              ? const Center(child: CircularProgressIndicator())
              : favoriteProvider.favorites.isEmpty
                  ? const Center(child: Text('Bạn chưa có sản phẩm yêu thích nào'))
                  : RefreshIndicator(
                      onRefresh: () => favoriteProvider.fetchFavorites(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: favoriteProvider.favorites.length,
                        itemBuilder: (context, index) =>
                            ProductCard(product: favoriteProvider.favorites[index]),
                      ),
                    ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Đăng nhập để xem sản phẩm yêu thích'),
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
