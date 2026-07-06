# Tính năng chọn vị trí trên Google Map khi đặt hàng

## Tổng quan
Tính năng cho phép khách hàng chọn vị trí giao hàng chính xác trên bản đồ Google Maps khi đặt hàng, giúp shipper dễ dàng tìm địa chỉ và theo dõi đơn hàng.

## Các thay đổi đã thực hiện

### 1. Backend (Laravel API)

#### Database Migration
- **File**: `laravel_api/database/migrations/2026_06_30_000001_add_location_to_orders_table.php`
- **Thay đổi**: Thêm 2 cột `customer_lat` và `customer_lng` vào bảng `orders` để lưu vị trí của khách hàng
- **Lệnh chạy migration**:
  ```bash
  cd laravel_api
  php artisan migrate
  ```

#### Model
- **File**: `laravel_api/app/Models/Order.php`
- **Thay đổi**: Thêm `customer_lat` và `customer_lng` vào `$fillable`

#### Controller
- **File**: `laravel_api/app/Http/Controllers/Api/OrderController.php`
- **Thay đổi**: 
  - Thêm validation cho `customer_lat` và `customer_lng` trong method `store()`
  - Lưu vị trí khách hàng khi tạo đơn hàng

### 2. Flutter App

#### Dependencies
- **File**: `flutter_app/pubspec.yaml`
- **Thêm packages**:
  - `google_maps_flutter: ^2.5.3` - Hiển thị bản đồ
  - `geolocator: ^11.0.0` - Lấy vị trí hiện tại của thiết bị
  - `geocoding: ^2.1.1` - Chuyển đổi tọa độ thành địa chỉ

#### Models
- **File**: `flutter_app/lib/models/order.dart`
- **Thay đổi**: Thêm 2 trường `customerLat` và `customerLng` vào `OrderModel`

#### Services
- **File**: `flutter_app/lib/services/order_service.dart`
- **Thay đổi**: Cập nhật method `placeOrder()` để nhận và gửi `customerLat` và `customerLng` lên API

#### Widgets
- **File mới**: `flutter_app/lib/widgets/map_location_picker.dart`
- **Chức năng**: 
  - Hiển thị Google Map
  - Cho phép người dùng chọn vị trí bằng cách tap trên bản đồ
  - Tự động lấy vị trí hiện tại của thiết bị
  - Chuyển đổi tọa độ thành địa chỉ text
  - Hiển thị marker đỏ tại vị trí đã chọn

#### Screens
- **File**: `flutter_app/lib/screens/order/checkout_screen.dart`
- **Thay đổi**:
  - Thêm 3 biến state: `_customerLat`, `_customerLng`, `_selectedLocationAddress`
  - Thêm method `_openMapPicker()` để mở màn hình chọn vị trí
  - Thêm nút "Chọn vị trí trên bản đồ" trong UI
  - Hiển thị thông tin vị trí đã chọn (nếu có)
  - Gửi vị trí khi đặt hàng

## Cách sử dụng

### Bước 1: Lấy Google Maps API Key

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới hoặc chọn project hiện tại
3. Bật các API sau:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API**
4. Tạo API Key:
   - Vào **APIs & Services** > **Credentials**
   - Click **Create Credentials** > **API Key**
   - Copy API Key
5. (Optional) Giới hạn API Key để bảo mật:
   - Click vào API Key vừa tạo
   - Ở mục **API restrictions**, chọn **Restrict key**
   - Chọn các API đã bật ở bước 3
   - Ở mục **Application restrictions**, thêm package name Android (ví dụ: `com.example.flutter_app`) và SHA-1 certificate

### Bước 2: Cấu hình API Key vào ứng dụng

**Android** (`flutter_app/android/app/src/main/AndroidManifest.xml`):
```xml
<!-- Tìm dòng này và thay YOUR_GOOGLE_MAPS_API_KEY bằng API Key thực tế -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**iOS** (`flutter_app/ios/Runner/Info.plist`):
```xml
<!-- Tìm dòng này và thay YOUR_GOOGLE_MAPS_API_KEY bằng API Key thực tế -->
<key>GMSApiKey</key>
<string>YOUR_GOOGLE_MAPS_API_KEY</string>
```

### Bước 3: Chạy ứng dụng

```bash
# Backend
cd laravel_api
php artisan migrate

# Flutter
cd flutter_app
flutter pub get
flutter run
```

### Cho người dùng:
1. Mở màn hình checkout (xác nhận đặt hàng)
2. Nhập địa chỉ giao hàng thủ công hoặc chọn từ danh sách địa chỉ đã lưu
3. Nhấn nút **"Chọn vị trí trên bản đồ"**
4. Trên bản đồ:
   - **Cách 1**: Nhấn nút "Vị trí hiện tại" (FAB) để tự động lấy vị trí hiện tại
   - **Cách 2**: Tap trực tiếp vào vị trí mong muốn trên bản đồ
5. Hệ thống sẽ hiển thị:
   - Marker đỏ tại vị trí đã chọn
   - Địa chỉ được chuyển từ tọa độ (nếu có)
6. Nhấn nút ✓ (check) ở góc trên bên phải để xác nhận
7. Quay lại màn hình checkout, vị trí đã chọn sẽ hiển thị
8. Hoàn tất đặt hàng

### Cho developer:

#### Cấu hình Google Maps API Key

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest>
    <application>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
    </application>
</manifest>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Hoặc sử dụng `AppDelegate.m`:
```objc
#import <GoogleMaps/GoogleMaps.h>

- (BOOL)application:(UIApplication *)application 
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GMSServices provideAPIKey:@"YOUR_GOOGLE_MAPS_API_KEY"];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
```

#### Cấp quyền:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
</manifest>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần quyền truy cập vị trí để hiển thị bản đồ</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Ứng dụng cần quyền truy cập vị trí để hiển thị bản đồ</string>
```

## Cấu trúc dữ liệu

### Order Model (Flutter)
```dart
class OrderModel {
  // ... các trường khác
  final double? customerLat;  // Vĩ độ của khách hàng
  final double? customerLng;  // Kinh độ của khách hàng
}
```

### Database (orders table)
```sql
customer_lat  DECIMAL(10,7) NULL  -- Vĩ độ
customer_lng  DECIMAL(10,7) NULL  -- Kinh độ
```

## Luồng dữ liệu

```
User Flow:
1. Checkout Screen → Nhấn "Chọn vị trí trên bản đồ"
2. MapLocationPicker → Chọn vị trí (tap hoặc current location)
3. MapLocationPicker → Return (lat, lng, address) to Checkout
4. Checkout Screen → Hiển thị địa chỉ đã chọn
5. Checkout Screen → Gửi order với customer_lat, customer_lng
6. Backend → Lưu vào database
7. Shipper có thể xem vị trí khách hàng trên bản đồ

Data Flow:
Flutter App → POST /api/orders 
  { shipping_address, shipping_phone, payment_method, customer_lat, customer_lng }
  → Laravel API 
  → Lưu vào orders table
```

## Testing

### Test Backend:
```bash
cd laravel_api
php artisan migrate
php artisan serve
```

### Test Flutter:
```bash
cd flutter_app
flutter pub get
flutter run
```

### Test Cases:
1. ✅ Chọn vị trí bằng cách tap trên bản đồ
2. ✅ Chọn vị trí bằng "Vị trí hiện tại"
3. ✅ Địa chỉ được tự động chuyển từ tọa độ
4. ✅ Vị trí được lưu khi đặt hàng thành công
5. ✅ Có thể xóa vị trí đã chọn
6. ✅ Đặt hàng thành công với vị trí
7. ✅ Đặt hàng thành công không có vị trí (optional)

## Lưu ý

1. **API Key**: Cần có Google Maps API Key hợp lệ với các API đã bật:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - Places API (optional, cho autocomplete)

2. **Quyền**: Ứng dụng cần được cấp quyền truy cập vị trí (location permission)

3. **Optional Feature**: Vị trí là tùy chọn, người dùng có thể đặt hàng mà không cần chọn vị trí

4. **Accuracy**: Độ chính xác phụ thuộc vào:
   - GPS của thiết bị
   - Mạng internet
   - Google Maps API

## Troubleshooting

### Lỗi "Google Maps not available"
- Kiểm tra API Key đã được cấu hình đúng chưa
- Kiểm tra API Key có đang active không
- Kiểm tra internet connection

### Lỗi "Location permission denied"
- Yêu cầu người dùng cấp quyền vị trí trong settings
- Kiểm tra permission trong AndroidManifest.xml và Info.plist

### Lỗi "Geocoding failed"
- Kiểm tra Geocoding API đã được bật trong Google Cloud Console
- Kiểm tra tọa độ có hợp lệ không

## Future Enhancements

1. **Autocomplete**: Thêm Google Places Autocomplete cho địa chỉ
2. **Save Location**: Lưu vị trí yêu thích vào địa chỉ
3. **Share Location**: Cho phép share vị trí qua link
4. **Multiple Stops**: Hỗ trợ nhiều điểm dừng cho đơn hàng
5. **Real-time Tracking**: Hiển thị vị trí shipper real-time trên bản đồ
6. **Distance Calculation**: Tính khoảng cách và phí ship tự động

## Files Modified/Created

### Backend:
- ✅ `laravel_api/database/migrations/2026_06_30_000001_add_location_to_orders_table.php` (NEW)
- ✅ `laravel_api/app/Models/Order.php` (MODIFIED)
- ✅ `laravel_api/app/Http/Controllers/Api/OrderController.php` (MODIFIED)

### Flutter:
- ✅ `flutter_app/pubspec.yaml` (MODIFIED)
- ✅ `flutter_app/lib/models/order.dart` (MODIFIED)
- ✅ `flutter_app/lib/services/order_service.dart` (MODIFIED)
- ✅ `flutter_app/lib/widgets/map_location_picker.dart` (NEW)
- ✅ `flutter_app/lib/screens/order/checkout_screen.dart` (MODIFIED)

## Support

Nếu có vấn đề hoặc cần hỗ trợ, vui lòng liên hệ team development.