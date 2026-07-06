import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  double _total = 0;
  bool _loading = false;

  List<CartItem> get items => _items;
  double get total => _total;
  bool get loading => _loading;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> fetchCart() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await CartService.getCart();
      _items = res['items'];
      _total = res['total'];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(int productId, {int quantity = 1, int? variantId}) async {
    await CartService.addToCart(productId, quantity: quantity, variantId: variantId);
    await fetchCart();
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    await CartService.updateQuantity(cartItemId, quantity);
    await fetchCart();
  }

  Future<void> removeItem(int cartItemId) async {
    await CartService.removeItem(cartItemId);
    await fetchCart();
  }

  Future<void> clearCart() async {
    await CartService.clearCart();
    _items = [];
    _total = 0;
    notifyListeners();
  }
}
