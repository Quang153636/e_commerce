import 'api_service.dart';

class PaymentService {
  /// Lấy thông tin QR và URL ảnh QR từ server
  static Future<Map<String, dynamic>> getQRInfo(int orderId) async {
    final res = await ApiService.get('/payment/$orderId/qr');
    return res as Map<String, dynamic>;
  }

  /// Kiểm tra trạng thái thanh toán (Flutter gọi mỗi 3 giây)
  static Future<Map<String, dynamic>> checkStatus(int orderId) async {
    final res = await ApiService.get('/payment/$orderId/status');
    return res as Map<String, dynamic>;
  }
}
