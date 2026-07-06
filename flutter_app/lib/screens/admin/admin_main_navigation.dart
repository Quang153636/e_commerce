import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import 'admin_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_statistics_screen.dart';
import 'orders/admin_order_list_screen.dart';
import 'products/admin_product_list_screen.dart';
import 'categories/admin_category_screen.dart';
import 'users/admin_user_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _index = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminStatisticsScreen(),
    AdminOrderListScreen(),
    AdminProductListScreen(),
    AdminCategoryScreen(),
    AdminUserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AdminColors.accent.withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AdminColors.accent),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: AdminColors.accent),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AdminColors.accent),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AdminColors.accent),
            label: 'Sản phẩm',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: AdminColors.accent),
            label: 'Danh mục',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: AdminColors.accent),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
