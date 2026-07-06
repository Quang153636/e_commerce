class ProductVariantType {
  final int id;
  final int productId;
  final String name;
  final List<String> options;

  ProductVariantType({
    required this.id,
    required this.productId,
    required this.name,
    required this.options,
  });

  factory ProductVariantType.fromJson(Map<String, dynamic> json) {
    return ProductVariantType(
      id: json['id'],
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? '',
      options: json['options'] != null ? List<String>.from(json['options']) : [],
    );
  }
}

class ProductVariant {
  final int id;
  final int productId;
  final Map<String, String> attributes;
  final double? price;
  final int stock;
  final String? sku;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.attributes,
    this.price,
    required this.stock,
    this.sku,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      productId: json['product_id'] ?? 0,
      attributes: json['attributes'] != null ? Map<String, String>.from(json['attributes']) : {},
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      stock: json['stock'] ?? 0,
      sku: json['sku'],
    );
  }
}