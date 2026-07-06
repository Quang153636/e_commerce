import '../models/order.dart';
import '../models/review.dart';
import 'api_service.dart';

class OrderService {
  /// Đặt hàng / mua hàng. Nếu [items] = null thì server sẽ lấy từ giỏ hàng hiện tại.
  static Future<OrderModel> placeOrder({
    required String shippingAddress,
    required String shippingPhone,
    String paymentMethod = 'cod',
    List<Map<String, dynamic>>? items,
    double? customerLat,
    double? customerLng,
  }) async {
    final res = await ApiService.post('/orders', data: {
      'shipping_address': shippingAddress,
      'shipping_phone': shippingPhone,
      'payment_method': paymentMethod,
      if (items != null) 'items': items,
      if (customerLat != null) 'customer_lat': customerLat,
      if (customerLng != null) 'customer_lng': customerLng,
    });
    return OrderModel.fromJson(res);
  }

  static Future<List<OrderModel>> getOrders() async {
    final res = await ApiService.get('/orders');
    final List data = res['data'] ?? [];
    return List<OrderModel>.from(data.map((e) => OrderModel.fromJson(e)));
  }

  static Future<OrderModel> getOrderDetail(int id) async {
    final res = await ApiService.get('/orders/$id');
    return OrderModel.fromJson(res);
  }

  static Future<void> confirmReceived(int orderId) async {
    await ApiService.post('/orders/$orderId/confirm-received');
  }

  static Future<void> cancelOrder(int orderId) async {
    await ApiService.post('/orders/$orderId/cancel');
  }

  static Future<void> confirmVietinbankPayment(int orderId) async {
    await ApiService.post('/orders/$orderId/confirm-vietinbank-payment');
  }

  /// Lấy dữ liệu theo dõi vị trí đơn hàng để hiển thị trên bản đồ
  static Future<Map<String, dynamic>> trackOrder(int orderId) async {
    final res = await ApiService.get('/orders/$orderId/track');
    return res;
  }

  /// Gửi đánh giá sao + bình luận cho một sản phẩm trong đơn hàng
  static Future<ReviewModel> submitReview({
    required int orderId,
    required int orderItemId,
    required int rating,
    String? comment,
  }) async {
    final res = await ApiService.post('/orders/$orderId/reviews', data: {
      'order_item_id': orderItemId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return ReviewModel.fromJson(res);
  }

  /// Lấy danh sách đánh giá của một đơn hàng
  static Future<List<ReviewModel>> getOrderReviews(int orderId) async {
    final res = await ApiService.get('/orders/$orderId/reviews');
    final List data = res['data'] ?? res;
    return List<ReviewModel>.from(data.map((e) => ReviewModel.fromJson(e)));
  }
}
