import '../models/cart_item.dart';
import 'api_service.dart';

class CartService {
  static Future<Map<String, dynamic>> getCart() async {
    final res = await ApiService.get('/cart');
    final items = List<CartItem>.from((res['items'] as List).map((e) => CartItem.fromJson(e)));
    final total = double.tryParse(res['total'].toString()) ?? 0;
    return {'items': items, 'total': total};
  }

  static Future<void> addToCart(int productId, {int quantity = 1, int? variantId}) async {
    final data = <String, dynamic>{
      'product_id': productId,
      'quantity': quantity,
    };
    if (variantId != null) {
      data['variant_id'] = variantId;
    }
    await ApiService.post('/cart', data: data);
  }

  static Future<void> updateQuantity(int cartItemId, int quantity) async {
    await ApiService.put('/cart/$cartItemId', data: {'quantity': quantity});
  }

  static Future<void> removeItem(int cartItemId) async {
    await ApiService.delete('/cart/$cartItemId');
  }

  static Future<void> clearCart() async {
    await ApiService.delete('/cart');
  }
}