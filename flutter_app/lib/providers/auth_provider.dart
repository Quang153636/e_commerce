import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  Future<void> tryAutoLogin() async {
    if (!await AuthService.isLoggedIn()) return;
    try {
      _user = await AuthService.me();
      notifyListeners();
    } catch (_) {
      // token hết hạn hoặc lỗi -> bỏ qua, coi như chưa đăng nhập
    }
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await AuthService.login(email: email, password: password);
      _user = AppUser.fromJson(res['user']);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await AuthService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );
      _user = AppUser.fromJson(res['user']);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }
}
