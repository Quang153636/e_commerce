import '../models/product.dart';
import '../models/category.dart';
import 'api_service.dart';

class ProductService {
  static Future<List<Category>> getCategories() async {
    final res = await ApiService.get('/categories', auth: false);
    return List<Category>.from(res.map((e) => Category.fromJson(e)));
  }

  static Future<List<Product>> getProducts({int? categoryId, String? query}) async {
    String path = '/products?per_page=20';
    if (categoryId != null) path += '&category_id=$categoryId';
    if (query != null && query.isNotEmpty) path += '&q=$query';

    final res = await ApiService.get(path, auth: false);
    final List data = res['data'] ?? [];
    return List<Product>.from(data.map((e) => Product.fromJson(e)));
  }

  static Future<Product> getProductDetail(int id) async {
    final res = await ApiService.get('/products/$id', auth: false);
    return Product.fromJson(res);
  }
}
