import 'product.dart';
import 'product_variant.dart';

class CartItem {
  final int id;
  final Product product;
  final ProductVariant? variant;
  int quantity;

  CartItem({required this.id, required this.product, this.variant, required this.quantity});

  double get subtotal => product.displayPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      variant: json['variant'] != null ? ProductVariant.fromJson(json['variant']) : null,
      quantity: json['quantity'] ?? 1,
    );
  }
}