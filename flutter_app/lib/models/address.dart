class AddressModel {
  final int id;
  final int userId;
  final String? label;
  final String recipientName;
  final String phone;
  final String address;
  final String? addressDetail;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    this.label,
    required this.recipientName,
    required this.phone,
    required this.address,
    this.addressDetail,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      label: json['label'],
      recipientName: json['recipient_name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      addressDetail: json['address_detail'],
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'recipient_name': recipientName,
      'phone': phone,
      'address': address,
      'address_detail': addressDetail,
      'is_default': isDefault,
    };
  }

  String get displayLabel {
    if (label != null && label!.isNotEmpty) {
      return label!;
    }
    return isDefault ? 'Mặc định' : 'Địa chỉ';
  }

  String get shortAddress {
    if (address.length > 50) {
      return '${address.substring(0, 50)}...';
    }
    return address;
  }
}