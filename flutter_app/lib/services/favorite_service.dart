import '../models/product.dart';
import 'api_service.dart';

class FavoriteService {
  static Future<List<Product>> getFavorites() async {
    final res = await ApiService.get('/favorites');
    return List<Product>.from(res.map((e) => Product.fromJson(e['product'])));
  }

  static Future<void> addFavorite(int productId) async {
    await ApiService.post('/favorites', data: {'product_id': productId});
  }

  static Future<void> removeFavorite(int productId) async {
    await ApiService.delete('/favorites/$productId');
  }
}
