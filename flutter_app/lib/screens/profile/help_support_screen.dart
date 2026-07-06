import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $phoneNumber');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp & Hỗ trợ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'Chúng tôi ở đây để giúp bạn!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Liên hệ với chúng tôi nếu bạn có bất kỳ câu hỏi hoặc cần hỗ trợ',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Liên hệ trực tiếp
          Text(
            'Liên hệ trực tiếp',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.phone_outlined,
            title: 'Hotline',
            subtitle: '1900 1234 5678',
            description: 'Thứ 2 - Chủ nhật, 8:00 - 22:00',
            color: Colors.green,
            onTap: () => _makePhoneCall('190012345678'),
          ),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'Email hỗ trợ',
            subtitle: 'support@shopapp.com',
            description: 'Phản hồi trong 24 giờ',
            color: Colors.blue,
            onTap: () => _sendEmail('support@shopapp.com'),
          ),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.chat_outlined,
            title: 'Chat trực tuyến',
            subtitle: 'Nhân viên hỗ trợ trực tuyến',
            description: 'Phản hồi tức thì',
            color: Colors.orange,
            onTap: () {
              // TODO: Implement chat support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          const SizedBox(height: 24),

          // Câu hỏi thường gặp
          Text(
            'Câu hỏi thường gặp (FAQ)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const _FAQItem(
            question: 'Làm sao để theo dõi đơn hàng?',
            answer: 'Bạn có thể theo dõi đơn hàng trong mục "Đơn hàng của tôi" trên trang cá nhân. Ở đó bạn sẽ thấy trạng thái đơn hàng và vị trí shipper nếu đang giao.',
          ),
          const _FAQItem(
            question: 'Làm sao để đổi/trả sản phẩm?',
            answer: 'Bạn có thể yêu cầu đổi/trả trong vòng 7 ngày kể từ ngày nhận hàng. Vào mục "Đơn hàng của tôi", chọn đơn hàng và nhấn "Yêu cầu đổi trả". Sản phẩm phải còn nguyên seal và không có dấu hiệu sử dụng.',
          ),
          const _FAQItem(
            question: 'Phương thức thanh toán nào được hỗ trợ?',
            answer: 'Chúng tôi hỗ trợ thanh toán COD (tiền mặt khi nhận hàng), Ví MoMo và thẻ tín dụng/ghi nợ. Tất cả các giao dịch đều được bảo mật.',
          ),
          const _FAQItem(
            question: 'Làm sao để thêm địa chỉ giao hàng?',
            answer: 'Vào mục "Địa chỉ giao hàng" trên trang cá nhân, nhấn "Thêm địa chỉ" và điền thông tin. Bạn cũng có thể chọn vị trí trực tiếp trên bản đồ để điền địa chỉ tự động.',
          ),
          const _FAQItem(
            question: 'Tôi quên mật khẩu, phải làm sao?',
            answer: 'Nhấn "Quên mật khẩu" trên màn hình đăng nhập. Chúng tôi sẽ gửi link đặt lại mật khẩu qua email của bạn.',
          ),
          const _FAQItem(
            question: 'Làm sao để hủy đơn hàng?',
            answer: 'Bạn có thể hủy đơn hàng trong mục "Đơn hàng của tôi" trước khi đơn hàng được xác nhận. Sau khi đơn hàng đã được xác nhận, vui lòng liên hệ hotline để được hỗ trợ.',
          ),
          const SizedBox(height: 24),

          // Hướng dẫn sử dụng
          Text(
            'Hướng dẫn sử dụng',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _GuideCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Cách đặt hàng',
            steps: [
              'Chọn sản phẩm bạn muốn mua',
              'Thêm vào giỏ hàng hoặc mua ngay',
              'Chọn địa chỉ giao hàng',
              'Chọn phương thức thanh toán',
              'Xác nhận đặt hàng',
            ],
          ),
          const SizedBox(height: 12),
          _GuideCard(
            icon: Icons.payment_outlined,
            title: 'Thanh toán an toàn',
            steps: [
              'COD: Thanh toán khi nhận hàng',
              'Ví MoMo: Quét mã QR hoặc xác nhận trên app',
              'Thẻ: Nhập thông tin thẻ an toàn',
            ],
          ),
          const SizedBox(height: 24),

          // Điều khoản & Chính sách
          Text(
            'Điều khoản & Chính sách',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _PolicyTile(
            icon: Icons.description_outlined,
            title: 'Điều khoản sử dụng',
            onTap: () {
              // TODO: Navigate to terms of service
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _PolicyTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách bảo mật',
            onTap: () {
              // TODO: Navigate to privacy policy
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _PolicyTile(
            icon: Icons.assignment_return_outlined,
            title: 'Chính sách đổi/trả hàng',
            onTap: () {
              // TODO: Navigate to return policy
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          _PolicyTile(
            icon: Icons.local_shipping_outlined,
            title: 'Chính sách vận chuyển',
            onTap: () {
              // TODO: Navigate to shipping policy
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          const SizedBox(height: 24),

          // Báo lỗi & Góp ý
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.feedback_outlined, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Báo lỗi & Góp ý',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Giúp chúng tôi cải thiện dịch vụ bằng cách gửi phản hồi của bạn',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _sendEmail('feedback@shopapp.com'),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Gửi phản hồi'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.blue),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Phiên bản
          Center(
            child: Text(
              'Phiên bản 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> steps;

  const _GuideCard({
    required this.icon,
    required this.title,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PolicyTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}