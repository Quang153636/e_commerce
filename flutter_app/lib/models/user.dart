class AppUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatar;
  final bool isAdmin;
  final int? ordersCount;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatar,
    this.isAdmin = false,
    this.ordersCount,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      avatar: json['avatar'],
      isAdmin: json['is_admin'] == true || json['is_admin'] == 1,
      ordersCount: json['orders_count'],
    );
  }
}
