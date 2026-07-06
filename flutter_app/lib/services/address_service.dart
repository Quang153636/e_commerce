import '../models/address.dart';
import 'api_service.dart';

class AddressService {
  // Lấy danh sách địa chỉ của user
  static Future<List<AddressModel>> getAddresses() async {
    final res = await ApiService.get('/addresses');
    List data;
    if (res is List) {
      data = res;
    } else if (res is Map && res['data'] != null) {
      data = res['data'];
    } else {
      data = [];
    }
    return List<AddressModel>.from(data.map((e) => AddressModel.fromJson(e)));
  }

  // Lấy địa chỉ mặc định
  static Future<AddressModel?> getDefaultAddress() async {
    try {
      final res = await ApiService.get('/addresses/default');
      if (res == null) return null;
      return AddressModel.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  // Tạo địa chỉ mới
  static Future<AddressModel> createAddress({
    required String recipientName,
    required String phone,
    required String address,
    String? addressDetail,
    String? label,
    bool isDefault = false,
  }) async {
    final res = await ApiService.post('/addresses', data: {
      'recipient_name': recipientName,
      'phone': phone,
      'address': address,
      if (addressDetail != null) 'address_detail': addressDetail,
      if (label != null) 'label': label,
      'is_default': isDefault,
    });
    return AddressModel.fromJson(res);
  }

  // Cập nhật địa chỉ
  static Future<AddressModel> updateAddress(
    int addressId, {
    String? recipientName,
    String? phone,
    String? address,
    String? addressDetail,
    String? label,
    bool? isDefault,
  }) async {
    final data = <String, dynamic>{};
    if (recipientName != null) data['recipient_name'] = recipientName;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    if (addressDetail != null) data['address_detail'] = addressDetail;
    if (label != null) data['label'] = label;
    if (isDefault != null) data['is_default'] = isDefault;

    final res = await ApiService.put('/addresses/$addressId', data: data);
    return AddressModel.fromJson(res);
  }

  // Xóa địa chỉ
  static Future<void> deleteAddress(int addressId) async {
    await ApiService.delete('/addresses/$addressId');
  }

  // Đặt địa chỉ làm mặc định
  static Future<AddressModel> setDefaultAddress(int addressId) async {
    final res = await ApiService.put('/addresses/$addressId', data: {
      'is_default': true,
    });
    return AddressModel.fromJson(res);
  }
}