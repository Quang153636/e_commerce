# 🗺️ Hướng dẫn cấu hình Google Maps - Nhanh & Dễ

## 📋 Checklist các bước cần làm:

- [ ] Bước 1: Bật 3 APIs
- [ ] Bước 2: Tạo API Key
- [ ] Bước 3: Copy API Key vào code
- [ ] Bước 4: Chạy thử ứng dụng

---

## 🚀 Bước 1: Bật 3 APIs (5 phút)

### 1.1. Mở Google Cloud Console
```
https://console.cloud.google.com/
```

### 1.2. Chọn project "e-commerce"
- Bạn sẽ thấy thông báo: "Displaying the 'e-commerce' project"
- Click vào project dropdown ở trên cùng để chọn project "e-commerce"

### 1.3. Bật APIs (làm theo thứ tự)

**API 1: Maps SDK for Android**
1. Click vào thanh tìm kiếm ở giữa màn hình
2. Gõ: `Maps SDK for Android`
3. Click vào kết quả đầu tiên
4. Click nút **ENABLE** (màu xanh)
5. Đợi 10 giây

**API 2: Maps SDK for iOS**
1. Click mũi tên **← Back** để quay lại
2. Gõ: `Maps SDK for iOS`
3. Click vào kết quả
4. Click **ENABLE**
5. Đợi 10 giây

**API 3: Geocoding API**
1. Click **← Back**
2. Gõ: `Geocoding API`
3. Click vào kết quả
4. Click **ENABLE**
5. Đợi 10 giây

---

## 🔑 Bước 2: Tạo API Key (2 phút)

### Cách DỄ NHẤT - Dùng URL trực tiếp:

1. Copy URL này và paste vào trình duyệt (tab mới):
   ```
   https://console.cloud.google.com/apis/credentials
   ```

2. Click nút **"+ CREATE CREDENTIALS"** ở trên cùng

3. Chọn **"API key"**

4. **Một dialog sẽ hiện ra như trong hình của bạn**

5. **Trong dialog, làm theo các bước sau:**

   **a) Chọn APIs (quan trọng):**
   - Click vào dropdown **"No API selected"** ở phần "APIs accessible using this key"
   - Tích chọn 3 APIs:
     - ☑️ **Maps SDK for Android**
     - ☑️ **Maps SDK for iOS**
     - ☑️ **Geocoding API**

   **b) Chọn Application restrictions (bảo mật):**
   - Ở phần "Application restrictions", chọn radio button **"Android apps"**
   - Click **"ADD PACKAGE NAME AND FINGERPRINT"**
   - Package name: `com.example.flutter_app`
   - SHA-1: (có thể để trống)

   **c) Tạo API Key:**
   - Click nút **"CREATE"** (màu xanh ở dưới)
   - Một dialog mới hiện ra với **API Key** (dạng: `AIzaSy...`)
   - **COPY API Key** (click icon copy bên cạnh key)
   - Click **"CLOSE"**

✅ **Xong! Bạn đã có API Key**

---

## 📝 Bước 3: Cấu hình API Key (1 phút)

### File 1: Android
Mở file: `flutter_app/android/app/src/main/AndroidManifest.xml`

Tìm dòng này (dòng ~32):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

Thay `YOUR_GOOGLE_MAPS_API_KEY` bằng API Key thực tế của bạn:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSy..."/>
```

### File 2: iOS
Mở file: `flutter_app/ios/Runner/Info.plist`

Tìm dòng này (dòng ~72):
```xml
<key>GMSApiKey</key>
<string>YOUR_GOOGLE_MAPS_API_KEY</string>
```

Thay `YOUR_GOOGLE_MAPS_API_KEY` bằng API Key thực tế:
```xml
<key>GMSApiKey</key>
<string>AIzaSy..."></string>
```

---

## ▶️ Bước 4: Chạy ứng dụng

### Terminal 1 - Backend:
```bash
cd laravel_api
php artisan migrate
php artisan serve
```

### Terminal 2 - Flutter:
```bash
cd flutter_app
flutter pub get
flutter run
```

---

## ✅ Test chức năng

1. Mở app trên thiết bị/emulator
2. Thêm sản phẩm vào giỏ hàng
3. Vào **Giỏ hàng** → **Thanh toán**
4. Nhấn nút **"Chọn vị trí trên bản đồ"**
5. Chọn vị trí trên bản đồ
6. Nhấn **✓** để xác nhận
7. Hoàn tất đặt hàng

---

## 🆘 Nếu gặp vấn đề

### Không thấy nút "+ CREATE CREDENTIALS"
→ Dùng URL trực tiếp: https://console.cloud.google.com/apis/credentials

### Bản đồ không hiển thị
→ Kiểm tra lại API Key đã được cấu hình đúng chưa

### Không lấy được vị trí hiện tại
→ Bật GPS và cấp quyền location cho app

---

## 📚 Tài liệu tham khảo

- Chi tiết đầy đủ: `GOOGLE_MAPS_LOCATION_FEATURE.md`
- Hướng dẫn nhanh: `SETUP_GOOGLE_MAPS.md`

---

## 💡 Mẹo nhỏ

- API Key MIỄN PHÍ cho đến $300 credit
- Không cần nhập thông tin thanh toán để dùng
- Có thể giới hạn API Key để bảo mật (xem SETUP_GOOGLE_MAPS.md)

---

**Lưu ý quan trọng:**
- Thay thế `YOUR_GOOGLE_MAPS_API_KEY` bằng API Key thực tế (dạng `AIzaSy...`)
- Chỉ cần thay trong 2 file: AndroidManifest.xml và Info.plist
- Vị trí là TÙY CHỌN - người dùng có thể đặt hàng không cần chọn vị trí