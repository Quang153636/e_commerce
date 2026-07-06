import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../admin/admin_main_navigation.dart';
import '../home/main_navigation.dart';
import '../order/order_list_screen.dart';
import '../favorite/favorite_screen.dart';
import 'address_list_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tài khoản')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Đăng nhập để quản lý tài khoản của bạn'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    final user = auth.user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user.email, style: const TextStyle(color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            label: 'Đơn hàng của tôi',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const OrderListScreen())),
          ),
          _MenuTile(
            icon: Icons.favorite_border,
            label: 'Sản phẩm yêu thích',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FavoriteScreen())),
          ),
          _MenuTile(
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ giao hàng',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AddressListScreen())),
          ),
          _MenuTile(icon: Icons.notifications_outlined, label: 'Thông báo', onTap: () {}),
          _MenuTile(
            icon: Icons.help_outline,
            label: 'Trợ giúp & hỗ trợ',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
          ),
          if (user.isAdmin) ...[
            const SizedBox(height: 4),
            _MenuTile(
              icon: Icons.admin_panel_settings,
              label: 'Quản trị (Admin)',
              color: const Color(0xFF6C5CE7),
              onTap: () => Navigator.of(context)
                  .pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AdminMainNavigation()),
                    (route) => false,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.logout,
            label: 'Đăng xuất',
            color: AppColors.danger,
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: color ?? AppColors.textDark),
          title: Text(label, style: TextStyle(color: color)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
          onTap: onTap,
        ),
      ),
    );
  }
}
