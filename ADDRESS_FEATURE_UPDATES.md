# Cập nhật tính năng quản lý địa chỉ

## Tổng quan các thay đổi

Đã cập nhật hệ thống quản lý địa chỉ theo yêu cầu:
1. Di chuyển trường "Chi tiết địa chỉ" xuống dưới phần "Địa chỉ"
2. Nút "Sử dụng vị trí hiện tại" chỉ hiển thị khi người dùng đã chọn vị trí khác
3. Hiển thị đầy đủ thông tin địa chỉ giao hàng: Nhãn, Tên người nhận, Số điện thoại, Địa chỉ, Chi tiết địa chỉ

## Thay đổi Backend (Laravel)

### 1. Database Migration
**File:** `laravel_api/database/migrations/2024_01_10_000000_create_addresses_table.php`
- Thêm cột `address_detail` vào bảng addresses (text, nullable)

**File:** `laravel_api/database/migrations/2026_06_30_000001_add_address_detail_to_addresses_table.php` (MỚI)
- Migration để thêm cột `address_detail` vào bảng addresses đã tồn tại
- Chạy lệnh: `php artisan migrate`

### 2. Model
**File:** `laravel_api/app/Models/Address.php`
- Thêm `address_detail` vào `$fillable` array

### 3. Controller
**File:** `laravel_api/app/Http/Controllers/Api/AddressController.php`
- Thêm validation rule cho `address_detail` trong method `store()`
- Thêm validation rule cho `address_detail` trong method `update()`

## Thay đổi Frontend (Flutter)

### 1. Màn hình Thêm/Sửa địa chỉ
**File:** `flutter_app/lib/screens/profile/add_edit_address_screen.dart`

#### Thay đổi thứ tự trường:
- **Trước:** Chi tiết địa chỉ → Địa chỉ
- **Sau:** Địa chỉ → Chi tiết địa chỉ

#### Cải thiện UI:
- Đổi tiêu đề "Vị trí hiện tại" → "Vị trí đã chọn" (chỉ hiển thị khi có vị trí)
- Đổi nút từ `ElevatedButton` → `OutlinedButton.icon` để nhấn mạnh đây là tùy chọn
- Thêm icon `Icons.my_location` vào nút
- Cập nhật hint text: "Nhập số nhà, tầng, tên tòa nhà (không bắt buộc)"

### 2. Màn hình Danh sách địa chỉ
**File:** `flutter_app/lib/screens/profile/address_list_screen.dart`

- Thêm hiển thị `addressDetail` sau địa chỉ chính
- Sử dụng icon `Icons.place_outlined` màu xanh để phân biệt
- Chỉ hiển thị khi `addressDetail` có giá trị

### 3. Màn hình Checkout
**File:** `flutter_app/lib/screens/order/checkout_screen.dart`

- Đã có sẵn hiển thị đầy đủ thông tin địa chỉ (không cần thay đổi)
- Hiển thị: Label, Tên người nhận, Số điện thoại, Địa chỉ, Chi tiết địa chỉ (nếu có)

## Cấu trúc hiển thị địa chỉ đầy đủ

### Khi thêm/sửa địa chỉ:
```
┌─────────────────────────────────────┐
│ Nhãn (tùy chọn)                     │
│ Ví dụ: Nhà, Văn phòng               │
├─────────────────────────────────────┤
│ Tên người nhận                      │
├─────────────────────────────────────┤
│ Số điện thoại                       │
├─────────────────────────────────────┤
│ ĐỊA CHỈ                             │
│ [Chọn địa chỉ từ bản đồ]            │
│                                     │
│ (Nếu có vị trí đã chọn)             │
│ 📍 Vị trí đã chọn                  │
│ [Địa chỉ từ bản đồ]                 │
│ [Sử dụng vị trí hiện tại]           │
├─────────────────────────────────────┤
│ Chi tiết địa chỉ                    │
│ Số nhà, tầng, tên tòa nhà           │
├─────────────────────────────────────┤
│ Đặt làm địa chỉ mặc định            │
└─────────────────────────────────────┘
```

### Khi hiển thị danh sách địa chỉ:
```
┌─────────────────────────────────────┐
│ [Nhà] [Mặc định]                    │
│ 👤 Nguyễn Văn A                     │
│ 📞 0912345678                       │
│ 📍 123 Đường ABC, Quận 1, TP.HCM   │
│ 📌 Số 5, tầng 2, Tòa nhà XYZ       │ (nếu có)
│                    [Sửa] [Xóa]      │
└─────────────────────────────────────┘
```

### Khi đặt hàng (Checkout):
```
┌─────────────────────────────────────┐
│ Địa chỉ giao hàng          [Chọn]   │
│ ─────────────────────────────────── │
│ ✓ [Nhà]                            │
│   👤 Nguyễn Văn A                  │
│   📞 0912345678                     │
│   📍 123 Đường ABC, Quận 1, TP.HCM │
│   📌 Số 5, tầng 2, Tòa nhà XYZ     │ (nếu có)
└─────────────────────────────────────┘
```

## Hướng dẫn cài đặt

### Backend:
```bash
cd laravel_api
composer install
php artisan migrate
```

### Frontend:
```bash
cd flutter_app
flutter pub get
flutter run
```

## Lưu ý

1. Migration mới đã được tạo để thêm cột `address_detail` vào bảng addresses đã tồn tại
2. Nếu database đã có dữ liệu, cột `address_detail` sẽ có giá trị NULL
3. Trường `address_detail` là tùy chọn (nullable), không bắt buộc
4. Hiển thị `address_detail` chỉ xuất hiện khi có giá trị

## Kiểm tra

- [x] Backend: Model Address có `address_detail` trong fillable
- [x] Backend: Controller validate `address_detail` trong store/update
- [x] Backend: Migration tạo cột `address_detail`
- [x] Backend: Migration thêm cột `address_detail` vào table đã tồn tại
- [x] Frontend: Thứ tự field đúng (Địa chỉ → Chi tiết địa chỉ)
- [x] Frontend: Nút "Sử dụng vị trí hiện tại" chỉ hiện khi có vị trí đã chọn
- [x] Frontend: Hiển thị đầy đủ thông tin địa chỉ trong danh sách
- [x] Frontend: Hiển thị đầy đủ thông tin địa chỉ trong checkout