# Tính năng Quản lý Địa chỉ Giao hàng

## Tổng quan
Tính năng này cho phép người dùng quản lý nhiều địa chỉ giao hàng và chọn địa chỉ mong muốn khi đặt hàng, thay vì phải nhập thủ công mỗi lần.

## Cấu trúc Backend (Laravel API)

### 1. Database Migration
- **File**: `laravel_api/database/migrations/2024_01_10_000000_create_addresses_table.php`
- Tạo bảng `addresses` với các trường:
  - `id`: Khóa chính
  - `user_id`: Khóa ngoại đến bảng users
  - `label`: Nhãn địa chỉ (ví dụ: "Nhà", "Văn phòng")
  - `recipient_name`: Tên người nhận hàng
  - `phone`: Số điện thoại liên hệ
  - `address`: Địa chỉ đầy đủ
  - `is_default`: Đánh dấu địa chỉ mặc định
  - `timestamps`: Thời gian tạo và cập nhật

### 2. Model
- **File**: `laravel_api/app/Models/Address.php`
- Eloquent Model với các relationship và scope:
  - `user()`: Relationship với User model
  - `scopeDefault()`: Lấy địa chỉ mặc định
  - `scopeByUser()`: Lấy địa chỉ theo user

### 3. Controller
- **File**: `laravel_api/app/Http/Controllers/Api/AddressController.php`
- Các API endpoints:
  - `GET /api/addresses`: Lấy danh sách địa chỉ
  - `GET /api/addresses/default`: Lấy địa chỉ mặc định
  - `POST /api/addresses`: Tạo địa chỉ mới
  - `GET /api/addresses/{address}`: Xem chi tiết địa chỉ
  - `PUT /api/addresses/{address}`: Cập nhật địa chỉ
  - `DELETE /api/addresses/{address}`: Xóa địa chỉ

### 4. Routes
- **File**: `laravel_api/routes/api.php`
- Tất cả routes đều được bảo vệ bởi middleware `auth:sanctum`

## Cấu trúc Frontend (Flutter)

### 1. Models
- **File**: `flutter_app/lib/models/address.dart`
- `AddressModel`: Model chính cho địa chỉ
  - `id`, `userId`, `label`, `recipientName`, `phone`, `address`, `isDefault`
  - `displayLabel`: Getter để hiển thị nhãn
  - `shortAddress`: Getter để hiển thị địa chỉ rút gọn

### 2. Services
- **File**: `flutter_app/lib/services/address_service.dart`
- Các methods:
  - `getAddresses()`: Lấy danh sách địa chỉ
  - `getDefaultAddress()`: Lấy địa chỉ mặc định
  - `createAddress()`: Tạo địa chỉ mới
  - `updateAddress()`: Cập nhật địa chỉ
  - `deleteAddress()`: Xóa địa chỉ
  - `setDefaultAddress()`: Đặt địa chỉ làm mặc định

### 3. Screens

#### a. Address List Screen
- **File**: `flutter_app/lib/screens/profile/address_list_screen.dart`
- Hiển thị danh sách tất cả địa chỉ
- Chức năng:
  - Xem danh sách địa chỉ
  - Thêm địa chỉ mới (FAB)
  - Chọn địa chỉ (khi mở từ checkout)
  - Sửa địa chỉ
  - Xóa địa chỉ (với confirmation dialog)
  - Hiển thị badge "Mặc định" cho địa chỉ mặc định

#### b. Add/Edit Address Screen
- **File**: `flutter_app/lib/screens/profile/add_edit_address_screen.dart`
- Form để thêm/sửa địa chỉ với các trường:
  - Nhãn (tùy chọn)
  - Tên người nhận (bắt buộc)
  - Số điện thoại (bắt buộc)
  - Địa chỉ đầy đủ (bắt buộc)
  - Checkbox đặt làm mặc định

#### c. Checkout Screen (Updated)
- **File**: `flutter_app/lib/screens/order/checkout_screen.dart`
- Cải tiến:
  - Hiển thị địa chỉ đã chọn với thông tin chi tiết
  - Nút "Chọn địa chỉ" để mở danh sách địa chỉ
  - Tự động load địa chỉ mặc định khi mở màn hình
  - Vẫn cho phép nhập địa chỉ thủ công
  - Khi đặt hàng, ưu tiên sử dụng địa chỉ đã chọn

#### d. Profile Screen (Updated)
- **File**: `flutter_app/lib/screens/profile/profile_screen.dart`
- Thêm menu item "Địa chỉ giao hàng" với navigation đến AddressListScreen

## Cách sử dụng

### 1. Cài đặt Backend
```bash
cd laravel_api
php artisan migrate
```

Migration sẽ tạo bảng `addresses` với cấu trúc đầy đủ.

### 2. Cài đặt Frontend
```bash
cd flutter_app
flutter pub get
```

### 3. Luồng sử dụng

#### Thêm địa chỉ mới:
1. Vào màn hình "Tài khoản" (Profile)
2. Chọn "Địa chỉ giao hàng"
3. Nhấn nút "Thêm địa chỉ"
4. Điền thông tin và lưu

#### Đặt hàng với địa chỉ đã lưu:
1. Vào giỏ hàng hoặc trang sản phẩm
2. Nhấn "Đặt hàng"
3. Nhấn "Chọn địa chỉ" ở phần địa chỉ giao hàng
4. Chọn địa chỉ từ danh sách
5. Thông tin địa chỉ và số điện thoại sẽ tự động điền
6. Hoàn tất đặt hàng

#### Quản lý địa chỉ:
- Xem danh sách: Vào Profile → Địa chỉ giao hàng
- Thêm: Nhấn FAB "Thêm địa chỉ"
- Sửa: Nhấn nút "Sửa" trên card địa chỉ
- Xóa: Nhấn nút "Xóa" và xác nhận
- Đặt mặc định: Tick checkbox "Đặt làm địa chỉ mặc định" khi thêm/sửa

## Tính năng đặc biệt

1. **Địa chỉ mặc định**: 
   - Tự động đặt làm mặc định nếu là địa chỉ đầu tiên
   - Chỉ có một địa chỉ mặc định tại một thời điểm
   - Tự động load địa chỉ mặc định khi mở màn hình checkout

2. **Linh hoạt trong nhập liệu**:
   - Có thể chọn địa chỉ từ danh sách
   - Có thể nhập địa chỉ thủ công
   - Nếu chọn địa chỉ từ danh sách, thông tin sẽ tự động điền

3. **UX tốt**:
   - Hiển thị rõ địa chỉ đã chọn với badge màu sắc
   - Thông báo khi chưa có địa chỉ
   - Loading state khi tải danh sách địa chỉ
   - Confirmation dialog trước khi xóa

## API Response Format

### GET /api/addresses
```json
[
  {
    "id": 1,
    "user_id": 1,
    "label": "Nhà",
    "recipient_name": "Nguyễn Văn A",
    "phone": "0901234567",
    "address": "123 Đường ABC, Quận 1, TP.HCM",
    "is_default": true,
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
]
```

### POST /api/addresses
Request:
```json
{
  "label": "Nhà",
  "recipient_name": "Nguyễn Văn A",
  "phone": "0901234567",
  "address": "123 Đường ABC, Quận 1, TP.HCM",
  "is_default": true
}
```

Response: Same as GET /api/addresses/{id}

## Bảo mật
- Tất cả API endpoints đều yêu cầu authentication (Sanctum token)
- User chỉ có thể xem/sửa/xóa địa chỉ của chính mình
- Controller kiểm tra `user_id` trước khi cho phép thao tác

## Lưu ý
- Một user có thể có nhiều địa chỉ
- Chỉ có một địa chỉ được đánh dấu là mặc định tại một thời điểm
- Khi đặt làm mặc định, các địa chỉ khác sẽ tự động bỏ mặc định
- Địa chỉ mặc định được tự động chọn khi mở màn hình checkout