import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';
import '../../../services/api_service.dart';
import '../admin_theme.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  List<AppUser> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _users = await AdminService.getUsers(
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAdmin(AppUser user) async {
    final currentUser = context.read<AuthProvider>().user;
    if (user.id == currentUser?.id) {
      Fluttertoast.showToast(msg: 'Không thể thay đổi quyền của chính mình!');
      return;
    }

    final action = user.isAdmin ? 'Bỏ quyền admin' : 'Cấp quyền admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(action),
        content: Text('$action cho ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isAdmin ? AdminColors.danger : AdminColors.accent,
            ),
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await AdminService.toggleAdmin(user.id);
      Fluttertoast.showToast(
          msg: user.isAdmin ? 'Đã bỏ quyền admin' : 'Đã cấp quyền admin');
      _load();
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final currentUser = context.read<AuthProvider>().user;
    if (user.id == currentUser?.id) {
      Fluttertoast.showToast(msg: 'Không thể xoá tài khoản đang đăng nhập!');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá người dùng'),
        content: Text('Xoá tài khoản "${user.name}"?\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: AdminColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await AdminService.deleteUser(user.id);
      Fluttertoast.showToast(msg: 'Đã xoá người dùng!');
      _load();
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    }
  }

  void _showUserDetail(AppUser user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      user.isAdmin ? AdminColors.accent : AdminColors.info,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(user.email,
                          style: const TextStyle(color: AdminColors.textGrey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(icon: Icons.phone_outlined, label: 'SĐT', value: user.phone ?? 'Chưa cập nhật'),
            _DetailRow(icon: Icons.location_on_outlined, label: 'Địa chỉ', value: user.address ?? 'Chưa cập nhật'),
            _DetailRow(
              icon: Icons.receipt_long_outlined,
              label: 'Đơn hàng',
              value: '${user.ordersCount ?? 0} đơn',
            ),
            _DetailRow(
              icon: Icons.shield_outlined,
              label: 'Quyền',
              value: user.isAdmin ? 'Admin' : 'Khách hàng',
              valueColor: user.isAdmin ? AdminColors.accent : AdminColors.textGrey,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleAdmin(user);
                    },
                    icon: Icon(user.isAdmin ? Icons.person_remove_outlined : Icons.admin_panel_settings_outlined),
                    label: Text(user.isAdmin ? 'Bỏ admin' : 'Cấp admin'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: user.isAdmin ? AdminColors.danger : AdminColors.accent,
                      side: BorderSide(color: user.isAdmin ? AdminColors.danger : AdminColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteUser(user);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xoá'),
                    style: ElevatedButton.styleFrom(backgroundColor: AdminColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Quản lý người dùng'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AdminColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc email...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Stats bar
          if (!_loading && _users.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Tổng',
                    value: _users.length,
                    color: AdminColors.info,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Admin',
                    value: _users.where((u) => u.isAdmin).length,
                    color: AdminColors.accent,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Khách hàng',
                    value: _users.where((u) => !u.isAdmin).length,
                    color: AdminColors.success,
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 56, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Không tìm thấy người dùng',
                                style: TextStyle(color: AdminColors.textGrey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final user = _users[i];
                            final isMe = context.read<AuthProvider>().user?.id == user.id;

                            return GestureDetector(
                              onTap: () => _showUserDetail(user),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isMe
                                      ? Border.all(color: AdminColors.accent, width: 1.5)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: user.isAdmin
                                          ? AdminColors.accent
                                          : AdminColors.info.withOpacity(0.8),
                                      child: Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                user.name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AdminColors.accent.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text('Bạn',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: AdminColors.accent)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(user.email,
                                              style: const TextStyle(
                                                  color: AdminColors.textGrey,
                                                  fontSize: 12)),
                                          if (user.phone != null) ...[
                                            const SizedBox(height: 2),
                                            Text(user.phone!,
                                                style: const TextStyle(
                                                    color: AdminColors.textGrey,
                                                    fontSize: 11)),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Right side
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: user.isAdmin
                                                ? AdminColors.accent.withOpacity(0.1)
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            user.isAdmin ? 'Admin' : 'Khách hàng',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: user.isAdmin
                                                  ? AdminColors.accent
                                                  : AdminColors.textGrey,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${user.ordersCount ?? 0} đơn',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AdminColors.textGrey),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right,
                                        color: AdminColors.textGrey, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: $value',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(
      {required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AdminColors.textGrey),
          const SizedBox(width: 12),
          SizedBox(
              width: 70,
              child: Text(label,
                  style: const TextStyle(color: AdminColors.textGrey, fontSize: 13))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
