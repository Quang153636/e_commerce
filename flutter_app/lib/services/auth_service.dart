import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final res = await ApiService.post('/register', auth: false, data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'phone': phone,
    });
    await _saveToken(res['token']);
    return res;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post('/login', auth: false, data: {
      'email': email,
      'password': password,
    });
    await _saveToken(res['token']);
    return res;
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('/logout');
    } catch (_) {
      // bỏ qua lỗi mạng khi logout, vẫn xoá token local
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<AppUser> me() async {
    final res = await ApiService.get('/me');
    return AppUser.fromJson(res);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
}
