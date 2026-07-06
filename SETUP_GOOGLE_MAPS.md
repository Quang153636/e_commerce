# Hướng dẫn cấu hình Google Maps nhanh

## Bước 1: Lấy API Key

### 1.1. Truy cập Google Cloud Console
- Mở trình duyệt và vào: https://console.cloud.google.com/
- Đăng nhập bằng tài khoản Google

### 1.2. Chọn hoặc tạo Project
- Nếu chưa có project, click **"CREATE PROJECT"**
- Đặt tên project (ví dụ: "E-commerce App")
- Click **"CREATE"**
- Chọn project vừa tạo

### 1.3. Bật 3 APIs cần thiết

**Cách vào trang API Library:**
- Click vào menu hamburger (☰) ở góc trên bên trái
- Chọn **"APIs & Services"** → **"Library"**
- Hoặc gõ "API Library" vào thanh tìm kiếm ở giữa màn hình

**Bật từng API:**

#### API 1: Maps SDK for Android
1. Trong ô tìm kiếm, gõ: **`Maps SDK for Android`**
2. Click vào kết quả **"Maps SDK for Android"**
3. Click nút **"ENABLE"** (màu xanh)
4. Đợi 10-20 giây để API được bật

#### API 2: Maps SDK for iOS
1. Click mũi tên **← Back** để quay lại API Library
2. Gõ: **`Maps SDK for iOS`**
3. Click vào kết quả **"Maps SDK for iOS"**
4. Click nút **"ENABLE"**
5. Đợi 10-20 giây

#### API 3: Geocoding API
1. Click mũi tên **← Back** để quay lại API Library
2. Gõ: **`Geocoding API`**
3. Click vào kết quả **"Geocoding API"**
4. Click nút **"ENABLE"**
5. Đợi 10-20 giây

### 1.4. Tạo API Key

**Cách 1: Từ menu APIs & Services (Khuyến nghị)**
1. Click vào menu hamburger (☰) ở góc trên bên trái
2. Hover chuột vào **"APIs & Services"** (không click)
3. Một submenu sẽ hiện ra bên phải
4. Click vào **"Credentials"** (trong submenu)
   - **Lưu ý**: Nếu bạn không thấy "Credentials" trong submenu, hãy thử **Cách 2** bên dưới
5. Ở trang Credentials, click nút **"+ CREATE CREDENTIALS"** ở trên cùng
6. Chọn **"API key"**
7. Một dialog hiện ra với **API Key mới** (dạng: `AIzaSy...`)
8. **Copy API Key này** (click vào icon copy bên cạnh key)
9. Click **"CLOSE"**

**Cách 2: Từ trang API Library (Dễ nhất)**
1. Ở trang **API Library** (sau khi bạn đã bật 3 APIs ở bước 1.3)
2. Click vào nút **"+ CREATE CREDENTIALS"** ở trên cùng bên phải
   - Nếu không thấy nút này, hãy xem **Cách 3** bên dưới
3. Chọn **"API key"**
4. Một dialog hiện ra với **API Key mới** (dạng: `AIzaSy...`)
5. **Copy API Key này** (click vào icon copy bên cạnh key)
6. Click **"CLOSE"**

**Cách 3: Dùng thanh tìm kiếm (Chắc chắn thành công)**
1. Gõ **"Credentials"** vào thanh tìm kiếm ở giữa màn hình
2. Chọn **"Credentials"** trong kết quả tìm kiếm
3. Ở trang Credentials, click **"+ CREATE CREDENTIALS"** → **"API key"**

**Cách 4: Từ URL trực tiếp**
1. Copy URL này và paste vào trình duyệt:
   ```
   https://console.cloud.google.com/apis/credentials
   ```
2. Click **"+ CREATE CREDENTIALS"** → **"API key"**

**Lưu ý quan trọng:**
- Nếu bạn thấy thông báo **"Displaying the 'e-commerce' project of the organization 'No organization'"**, đó là bình thường
- Bạn vẫn có thể tạo Credentials cho project này
- API Key sẽ có dạng: `AIzaSyABC123...` (bắt đầu bằng `AIzaSy`)
- Nếu không thấy nút "+ CREATE CREDENTIALS", hãy thử Cách 3 hoặc Cách 4

### 1.5. (Optional) Giới hạn API Key để bảo mật

1. Trong trang **Credentials**, tìm API Key vừa tạo
2. Click vào **icon bút chì** (✏️) để edit
3. Ở phần **"API restrictions"**:
   - Chọn **"Restrict key"**
   - Tích chọn 3 APIs: **Maps SDK for Android**, **Maps SDK for iOS**, **Geocoding API**
4. Ở phần **"Application restrictions"**:
   - Chọn **"Android apps"**
   - Click **"ADD PACKAGE NAME AND FINGERPRINT"**
   - Package name: `com.example.flutter_app` (hoặc package name thực tế của bạn)
   - SHA-1 certificate: Lấy từ file `android/app/build.gradle` (tìm dòng `sha1`)
5. Click **"SAVE"**

## Bước 2: Cấu hình API Key

### Android
Mở file `flutter_app/android/app/src/main/AndroidManifest.xml` và thay thế:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```
Thành:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSy..."/> <!-- API Key thực tế của bạn -->
```

### iOS
Mở file `flutter_app/ios/Runner/Info.plist` và thay thế:
```xml
<key>GMSApiKey</key>
<string>YOUR_GOOGLE_MAPS_API_KEY</string>
```
Thành:
```xml
<key>GMSApiKey</key>
<string>AIzaSy..."></string> <!-- API Key thực tế của bạn -->
```

## Bước 3: Chạy ứng dụng

```bash
# Terminal 1: Backend
cd laravel_api
php artisan migrate
php artisan serve

# Terminal 2: Flutter
cd flutter_app
flutter pub get
flutter run
```

## Lưu ý quan trọng

⚠️ **Thay thế `YOUR_GOOGLE_MAPS_API_KEY` bằng API Key thực tế của bạn trong cả 2 file:**
- `flutter_app/android/app/src/main/AndroidManifest.xml` (dòng ~32)
- `flutter_app/ios/Runner/Info.plist` (dòng ~72)

## Test chức năng

1. Mở app, thêm sản phẩm vào giỏ hàng
2. Vào giỏ hàng → Thanh toán
3. Nhấn nút **"Chọn vị trí trên bản đồ"**
4. Chọn vị trí trên bản đồ hoặc nhấn "Vị trí hiện tại"
5. Nhấn ✓ để xác nhận
6. Hoàn tất đặt hàng

## Troubleshooting

### Bản đồ không hiển thị
- Kiểm tra API Key đã được cấu hình đúng chưa
- Kiểm tra internet connection
- Kiểm tra API Key có đang active không

### Không lấy được vị trí hiện tại
- Kiểm tra quyền location đã được cấp chưa
- Bật GPS trên thiết bị
- Restart app sau khi cấp quyền

## Chi tiết đầy đủ

Xem file `GOOGLE_MAPS_LOCATION_FEATURE.md` để biết thêm thông tin chi tiết về cấu trúc dữ liệu, luồng dữ liệu, và các tính năng mở rộng.