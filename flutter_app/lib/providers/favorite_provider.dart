import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  List<Product> _favorites = [];
  bool _loading = false;

  List<Product> get favorites => _favorites;
  bool get loading => _loading;

  bool isFavorite(int productId) => _favorites.any((p) => p.id == productId);

  Future<void> fetchFavorites() async {
    _loading = true;
    notifyListeners();
    try {
      _favorites = await FavoriteService.getFavorites();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Product product) async {
    if (isFavorite(product.id)) {
      await FavoriteService.removeFavorite(product.id);
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      await FavoriteService.addFavorite(product.id);
      _favorites.add(product);
    }
    notifyListeners();
  }
}
