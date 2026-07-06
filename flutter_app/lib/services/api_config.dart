class ApiConfig {
  /// Đổi địa chỉ này theo môi trường chạy thực tế:
  /// - Android Emulator: http://10.0.2.2:8000/api
  /// - iOS Simulator: http://127.0.0.1:8000/api
  /// - Thiết bị thật / server: http://<ip-hoặc-domain>:8000/api
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
