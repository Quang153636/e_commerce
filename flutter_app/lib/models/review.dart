class ReviewModel {
  final int id;
  final int userId;
  final int productId;
  final int orderId;
  final int orderItemId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.orderId,
    required this.orderItemId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      orderItemId: json['order_item_id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      userName: json['user'] != null ? (json['user']['name'] ?? json['user']['email']) : null,
      userAvatar: json['user'] != null ? json['user']['avatar'] : null,
    );
  }
}