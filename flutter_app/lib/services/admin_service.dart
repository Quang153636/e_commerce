import '../models/order.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/user.dart';
import 'api_service.dart';

class AdminService {
  // ─── Dashboard ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await ApiService.get('/admin/stats');
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    throw ApiException('Dữ liệu dashboard không hợp lệ');
  }

  // ─── Orders ──────────────────────────────────────────────────
  static Future<List<OrderModel>> getOrders({String? status, String? q, int page = 1}) async {
    String path = '/admin/orders?page=$page';
    if (status != null && status.isNotEmpty) path += '&status=$status';
    if (q != null && q.isNotEmpty) path += '&q=${Uri.encodeComponent(q)}';
    final res = await ApiService.get(path);
    final List data = res['data'] ?? [];
    return List<OrderModel>.from(data.map((e) => OrderModel.fromJson(e)));
  }

  static Future<OrderModel> getOrderDetail(int id) async {
    final res = await ApiService.get('/admin/orders/$id');
    return OrderModel.fromJson(res);
  }

  static Future<void> updateOrderStatus(int id, String status, {String? note}) async {
    await ApiService.post('/admin/orders/$id/status', data: {
      'status': status,
      'note': note ?? '',
    });
  }

  static Future<void> updateOrderLocation(int id, {
    required double lat,
    required double lng,
    String? shipperName,
    String? shipperPhone,
  }) async {
    await ApiService.post('/admin/orders/$id/location', data: {
      'lat': lat,
      'lng': lng,
      if (shipperName != null) 'shipper_name': shipperName,
      if (shipperPhone != null) 'shipper_phone': shipperPhone,
    });
  }

  static Future<void> confirmPayment(int orderId) async {
    await ApiService.post('/payment/$orderId/manual-confirm');
  }

  // ─── Products ────────────────────────────────────────────────
  static Future<List<Product>> getProducts({int? categoryId, String? q, int page = 1}) async {
    String path = '/admin/products?page=$page';
    if (categoryId != null) path += '&category_id=$categoryId';
    if (q != null && q.isNotEmpty) path += '&q=${Uri.encodeComponent(q)}';
    final res = await ApiService.get(path);
    final List data = res['data'] ?? [];
    return List<Product>.from(data.map((e) => Product.fromJson(e)));
  }

  static Future<Product> createProduct(Map<String, dynamic> data) async {
    final res = await ApiService.post('/admin/products', data: data);
    return Product.fromJson(res);
  }

  static Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await ApiService.put('/admin/products/$id', data: data);
    return Product.fromJson(res);
  }

  static Future<void> deleteProduct(int id) async {
    await ApiService.delete('/admin/products/$id');
  }

  // ─── Categories ──────────────────────────────────────────────
  static Future<List<Category>> getCategories() async {
    final res = await ApiService.get('/admin/categories');
    return List<Category>.from((res as List).map((e) => Category.fromJson(e)));
  }

  static Future<void> createCategory(String name, {String? icon}) async {
    await ApiService.post('/admin/categories', data: {'name': name, 'icon': icon ?? ''});
  }

  static Future<void> updateCategory(int id, String name, {String? icon}) async {
    await ApiService.put('/admin/categories/$id', data: {'name': name, 'icon': icon ?? ''});
  }

  static Future<void> deleteCategory(int id) async {
    await ApiService.delete('/admin/categories/$id');
  }

  // ─── Users ───────────────────────────────────────────────────
  static Future<List<AppUser>> getUsers({String? q, int page = 1}) async {
    String path = '/admin/users?page=$page';
    if (q != null && q.isNotEmpty) path += '&q=${Uri.encodeComponent(q)}';
    final res = await ApiService.get(path);
    final List data = res['data'] ?? [];
    return List<AppUser>.from(data.map((e) => AppUser.fromJson(e)));
  }

  static Future<void> toggleAdmin(int userId) async {
    await ApiService.post('/admin/users/$userId/toggle-admin');
  }

  static Future<void> deleteUser(int userId) async {
    await ApiService.delete('/admin/users/$userId');
  }
}
