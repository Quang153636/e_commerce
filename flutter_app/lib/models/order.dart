class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final bool hasReview; // Đã đánh giá chưa
  final Map<String, String>? variantInfo; // Thông tin biến thể đã chọn

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    this.hasReview = false,
    this.variantInfo,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // 1. Tìm ảnh ở các key trực tiếp (Ưu tiên các key phổ biến trong API danh sách)
    String? img = json['product_image'] ?? 
                  json['image'] ?? 
                  json['thumbnail'] ?? 
                  json['thumb'] ??
                  json['image_url'] ??
                  json['product_thumbnail'] ??
                  json['product_thumb'];
    
    // 2. Nếu vẫn không thấy, tìm sâu trong object 'product' (Thường có ở API chi tiết)
    if (img == null && json['product'] != null) {
      final p = json['product'];
      if (p is Map<String, dynamic>) {
        img = p['thumbnail'] ?? 
              p['image'] ?? 
              p['product_image'] ??
              p['image_url'] ??
              (p['images'] != null && (p['images'] as List).isNotEmpty ? p['images'][0] : null);
      } else if (p is String) {
        img = p; // Nếu 'product' trả về thẳng URL
      }
    }

    // Parse variant_info
    Map<String, String>? variantInfo;
    if (json['variant_info'] != null && json['variant_info'] is Map) {
      variantInfo = Map<String, String>.from(json['variant_info']);
    }

    return OrderItemModel(
      id: json['id'],
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      productImage: img,
      price: double.tryParse(json['price'].toString()) ?? 0,
      quantity: json['quantity'] ?? 1,
      hasReview: json['has_review'] ?? false,
      variantInfo: variantInfo,
    );
  }
}

class OrderStatusHistoryModel {
  final String status;
  final String? note;
  final DateTime? createdAt;

  OrderStatusHistoryModel({required this.status, this.note, this.createdAt});

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      status: json['status'] ?? '',
      note: json['note'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class OrderLocationModel {
  final double lat;
  final double lng;
  final String? shipperName;
  final String? shipperPhone;
  final DateTime? createdAt;

  OrderLocationModel({
    required this.lat,
    required this.lng,
    this.shipperName,
    this.shipperPhone,
    this.createdAt,
  });

  factory OrderLocationModel.fromJson(Map<String, dynamic> json) {
    return OrderLocationModel(
      lat: double.tryParse(json['lat'].toString()) ?? 0,
      lng: double.tryParse(json['lng'].toString()) ?? 0,
      shipperName: json['shipper_name'],
      shipperPhone: json['shipper_phone'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

/// Trạng thái đơn hàng: pending (đã đặt hàng) -> confirmed -> shipping
/// -> delivered (đã giao hàng) -> received (đã nhận hàng) hoặc cancelled
class OrderModel {
  final int id;
  final String code;
  final double total;
  final String shippingAddress;
  final String shippingPhone;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime? createdAt;
  final List<OrderItemModel> items;
  final List<OrderStatusHistoryModel> statusHistories;
  final OrderLocationModel? latestLocation;
  final double? customerLat;
  final double? customerLng;

  OrderModel({
    required this.id,
    required this.code,
    required this.total,
    required this.shippingAddress,
    required this.shippingPhone,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.createdAt,
    this.items = const [],
    this.statusHistories = const [],
    this.latestLocation,
    this.customerLat,
    this.customerLng,
  });

  static const Map<String, String> statusLabels = {
    'pending': 'Đã đặt hàng',
    'confirmed': 'Đã xác nhận',
    'shipping': 'Đang giao hàng',
    'delivered': 'Đã giao hàng',
    'received': 'Đã nhận hàng',
    'cancelled': 'Đã hủy',
  };

  String get statusLabel => statusLabels[status] ?? status;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      code: json['code'] ?? '',
      total: double.tryParse(json['total'].toString()) ?? 0,
      shippingAddress: json['shipping_address'] ?? '',
      shippingPhone: json['shipping_phone'] ?? '',
      paymentMethod: json['payment_method'] ?? 'cod',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      items: json['items'] != null
          ? List<OrderItemModel>.from(
              json['items'].map((e) => OrderItemModel.fromJson(e)))
          : [],
      statusHistories: json['status_histories'] != null
          ? List<OrderStatusHistoryModel>.from(
              json['status_histories'].map((e) => OrderStatusHistoryModel.fromJson(e)))
          : [],
      latestLocation: json['latest_location'] != null
          ? OrderLocationModel.fromJson(json['latest_location'])
          : null,
      customerLat: json['customer_lat'] != null ? double.tryParse(json['customer_lat'].toString()) : null,
      customerLng: json['customer_lng'] != null ? double.tryParse(json['customer_lng'].toString()) : null,
    );
  }
}
