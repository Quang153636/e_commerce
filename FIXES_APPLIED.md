# Các lỗi đã được sửa

## 1. Lỗi: Địa chỉ không hiển thị sau khi thêm

### Nguyên nhân:
Hàm `getAddresses()` trong `AddressService` không xử lý đúng định dạng response từ API. Laravel trả về mảng trực tiếp, nhưng code Flutter lại trông đợi response có wrapper `data`.

### Giải pháp:
Đã sửa hàm `getAddresses()` trong `flutter_app/lib/services/address_service.dart` để xử lý cả hai trường hợp:
- Response là mảng trực tiếp (từ Laravel)
- Response có wrapper `data`

```dart
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
```

## 2. Lỗi: Bản đồ hiển thị tọa độ thay vì địa chỉ rõ ràng

### Nguyên nhân:
- Geocoding bị tắt (commented out) trong `map_location_picker.dart`
- Không có package geocoding được cài đặt

### Giải pháp:
1. **Thêm package geocoding** vào `pubspec.yaml`:
```yaml
geocoding: ^2.1.1
```

2. **Kích hoạt geocoding** trong `flutter_app/lib/widgets/map_location_picker.dart`:
   - Import package `geocoding`
   - Implement hàm `_getAddressFromLatLng()` để chuyển tọa độ thành địa chỉ rõ ràng
   - Hiển thị địa chỉ đầy đủ (street, name, subLocality, locality, administrativeArea, country)

### Kết quả:
- Khi chọn vị trí trên bản đồ, app sẽ hiển thị địa chỉ rõ ràng thay vì tọa độ
- Ví dụ: "123 Nguyễn Văn Linh, Tân Phong, Quận 7, Hồ Chí Minh, Vietnam" thay vì "10.823456, 106.629700"

## Cách test:

1. **Test thêm địa chỉ:**
   - Mở màn hình "Địa chỉ giao hàng"
   - Nhấn "Thêm địa chỉ"
   - Điền thông tin và lưu
   - Kiểm tra xem địa chỉ có hiển thị trong danh sách không

2. **Test chọn vị trí trên bản đồ:**
   - Mở màn hình checkout
   - Nhấn "Chọn vị trí trên bản đồ"
   - Chọn một vị trí trên bản đồ
   - Kiểm tra xem có hiển thị địa chỉ rõ ràng không (không phải tọa độ)

## Lưu ý:
- Cần chạy `flutter pub get` để cài đặt package geocoding
- Geocoding yêu cầu kết nối internet để chuyển tọa độ thành địa chỉ
- Trong trường hợp geocoding thất bại, app sẽ vẫn hiển thị tọa độ làm fallback