import 'package:flutter/material.dart';

class AdminColors {
  static const primary    = Color(0xFF1E293B); // slate-800
  static const accent     = Color(0xFFFF6B35); // orange
  static const bg         = Color(0xFFF1F5F9); // slate-100
  static const card       = Colors.white;
  static const textDark   = Color(0xFF0F172A);
  static const textGrey   = Color(0xFF64748B);
  static const success    = Color(0xFF10B981);
  static const warning    = Color(0xFFF59E0B);
  static const danger     = Color(0xFFEF4444);
  static const info       = Color(0xFF3B82F6);
}

class AdminStatusColor {
  static Color bg(String status) {
    switch (status) {
      case 'pending':   return const Color(0xFFFEF3C7);
      case 'confirmed': return const Color(0xFFDBEAFE);
      case 'shipping':  return const Color(0xFFE0E7FF);
      case 'delivered': return const Color(0xFFCCFBF1);
      case 'received':  return const Color(0xFFDCFCE7);
      case 'cancelled': return const Color(0xFFFEE2E2);
      default:          return const Color(0xFFF1F5F9);
    }
  }

  static Color text(String status) {
    switch (status) {
      case 'pending':   return const Color(0xFFD97706);
      case 'confirmed': return const Color(0xFF2563EB);
      case 'shipping':  return const Color(0xFF4F46E5);
      case 'delivered': return const Color(0xFF0D9488);
      case 'received':  return const Color(0xFF16A34A);
      case 'cancelled': return const Color(0xFFDC2626);
      default:          return const Color(0xFF64748B);
    }
  }

  static String label(String status) {
    const map = {
      'pending':   'Chờ xác nhận',
      'confirmed': 'Đã xác nhận',
      'shipping':  'Đang giao',
      'delivered': 'Đã giao',
      'received':  'Đã nhận',
      'cancelled': 'Đã huỷ',
    };
    return map[status] ?? status;
  }
}
