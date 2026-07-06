import 'product_variant.dart';
import 'review.dart';

class Product {
  final int id;
  final int categoryId;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? salePrice;
  final int stock;
  final List<String> images;
  final double rating;
  final bool isActive;
  bool isFavorite;
  final List<ProductVariantType> variantTypes;
  final List<ProductVariant> variants;
  final List<ReviewModel> reviews;
  ProductVariant? selectedVariant;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.salePrice,
    required this.stock,
    required this.images,
    required this.rating,
    required this.isActive,
    this.isFavorite = false,
    this.variantTypes = const [],
    this.variants = const [],
    this.reviews = const [],
    this.selectedVariant,
  });

  double get displayPrice => salePrice ?? price;
  bool get hasDiscount => salePrice != null && salePrice! < price;
  String get thumbnail => images.isNotEmpty ? images.first : '';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0,
      salePrice: json['sale_price'] != null
          ? double.tryParse(json['sale_price'].toString())
          : null,
      stock: json['stock'] ?? 0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      rating: double.tryParse(json['rating'].toString()) ?? 0,
      isActive: json['is_active'] ?? true,
      variantTypes: json['variant_types'] != null
          ? List<ProductVariantType>.from(
              json['variant_types'].map((e) => ProductVariantType.fromJson(e)))
          : [],
      variants: json['variants'] != null
          ? List<ProductVariant>.from(
              json['variants'].map((e) => ProductVariant.fromJson(e)))
          : [],
      reviews: json['reviews'] != null
          ? List<ReviewModel>.from(
              json['reviews'].map((e) => ReviewModel.fromJson(e)))
          : [],
    );
  }
}
