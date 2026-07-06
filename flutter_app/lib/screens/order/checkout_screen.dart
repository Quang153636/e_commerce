import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/address.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/address_service.dart';
import '../../services/api_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/map_location_picker.dart';
import '../../widgets/product_card.dart';
import '../profile/address_list_screen.dart';
import 'order_success_screen.dart';
import 'payment_qr_screen.dart';

/// Nếu [directItems] được truyền vào (luồng "Mua ngay" từ trang chi tiết),
/// đơn hàng sẽ được tạo trực tiếp từ sản phẩm đó thay vì từ giỏ hàng.
class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? directItems;
  final List<Product>? directProducts;
  final List<int>? directQuantities;

  const CheckoutScreen({
    super.key,
    this.directItems,
    this.directProducts,
    this.directQuantities,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _paymentMethod = 'cod';
  bool _placing = false;
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _loadingAddresses = true;
  double? _customerLat;
  double? _customerLng;
  String? _selectedLocationAddress;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final addresses = await AddressService.getAddresses();
      final defaultAddr = await AddressService.getDefaultAddress();
      
      setState(() {
        _addresses = addresses;
        _selectedAddress = defaultAddr ?? addresses.firstOrNull;
        
        // Cập nhật UI với địa chỉ đã chọn
        if (_selectedAddress != null) {
          _addressCtrl.text = _selectedAddress!.address;
          _phoneCtrl.text = _selectedAddress!.phone;
        } else {
          final user = context.read<AuthProvider>().user;
          _addressCtrl.text = user?.address ?? '';
          _phoneCtrl.text = user?.phone ?? '';
        }
        _loadingAddresses = false;
      });
    } catch (e) {
      setState(() => _loadingAddresses = false);
      final user = context.read<AuthProvider>().user;
      _addressCtrl.text = user?.address ?? '';
      _phoneCtrl.text = user?.phone ?? '';
    }
  }

  double get _total {
    if (widget.directProducts != null) {
      double sum = 0;
      for (var i = 0; i < widget.directProducts!.length; i++) {
        sum += widget.directProducts![i].displayPrice * widget.directQuantities![i];
      }
      return sum;
    }
    return context.watch<CartProvider>().total;
  }

  void _onAddressSelected(AddressModel? address) {
    if (address != null) {
      setState(() {
        _selectedAddress = address;
        _addressCtrl.text = address.address;
        _phoneCtrl.text = address.phone;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Vui lòng nhập đầy đủ địa chỉ và số điện thoại');
      return;
    }
    
    // Nếu có địa chỉ được chọn, sử dụng thông tin từ đó
    String shippingAddress = _addressCtrl.text.trim();
    String shippingPhone = _phoneCtrl.text.trim();
    
    if (_selectedAddress != null) {
      shippingAddress = _selectedAddress!.address;
      shippingPhone = _selectedAddress!.phone;
      
      // Nếu có chi tiết địa chỉ, thêm vào địa chỉ giao hàng
      if (_selectedAddress!.addressDetail != null && _selectedAddress!.addressDetail!.isNotEmpty) {
        shippingAddress = '${_selectedAddress!.address}, ${_selectedAddress!.addressDetail}';
      }
    }

    setState(() => _placing = true);
    try {
      OrderModel? lastOrder;
      bool splitMode = false;

      if (widget.directItems != null) {
        // Mua ngay 1 sản phẩm - kèm variant_info/variant_id nếu có
        final itemsWithVariant = List.generate(widget.directProducts!.length, (i) {
          final product = widget.directProducts![i];
          final selectedVariant = product.selectedVariant;
          // Lấy từ directItems đã được tạo từ product_detail_screen (có variant_id)
          final directItem = i < widget.directItems!.length ? widget.directItems![i] : null;
          return {
            'product_id': product.id,
            'quantity': widget.directQuantities![i],
            if (selectedVariant != null) ...{
              'variant_id': selectedVariant.id,
              'variant_info': Map<String, String>.from(selectedVariant.attributes),
            },
            // Nếu directItem đã có variant_id thì dùng
            if (directItem != null && directItem.containsKey('variant_id'))
              'variant_id': directItem['variant_id'],
            if (directItem != null && directItem.containsKey('variant_info'))
              'variant_info': directItem['variant_info'],
          };
        });

        lastOrder = await OrderService.placeOrder(
          shippingAddress: shippingAddress,
          shippingPhone: shippingPhone,
          paymentMethod: _paymentMethod,
          items: itemsWithVariant,
          customerLat: _customerLat,
          customerLng: _customerLng,
        );
      } else {
        // Đặt từ giỏ hàng: Tách từng món thành đơn riêng
        final cartProvider = context.read<CartProvider>();
        final itemsToProcess = List.from(cartProvider.items);
        splitMode = itemsToProcess.length > 1;

        for (var item in itemsToProcess) {
          final Map<String, dynamic> cartItemData = {
            'product_id': item.product.id,
            'quantity': item.quantity,
          };
          // Gửi variant_id khi mua từ giỏ hàng nếu có
          if (item.variant != null) {
            cartItemData['variant_id'] = item.variant!.id;
            cartItemData['variant_info'] = Map<String, String>.from(item.variant!.attributes);
          }
          lastOrder = await OrderService.placeOrder(
            shippingAddress: shippingAddress,
            shippingPhone: shippingPhone,
            paymentMethod: _paymentMethod,
            items: [cartItemData],
            customerLat: _customerLat,
            customerLng: _customerLng,
          );
        }
        await cartProvider.clearCart();
      }

      if (!mounted) return;
      
      if (lastOrder == null) {
        Fluttertoast.showToast(msg: 'Có lỗi xảy ra khi tạo đơn hàng');
        return;
      }

      final order = lastOrder!;

      // Nếu chọn thanh toán VietinBank, chuyển đến màn hình QR
      if (_paymentMethod == 'vietinbank') {
        // Mở màn hình QR, không await - không cần chờ thanh toán
        // Khi người dùng thanh toán xong qua ngân hàng, webhook sẽ được gọi
        // App sẽ tự động phát hiện và chuyển về màn hình chính
        // Nếu người dùng thoát mà không thanh toán, đơn hàng sẽ bị hủy
        // và quay lại màn hình checkout
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentQRScreen(
              orderId: order.id,
              orderCode: order.code,
              amount: _total,
            ),
          ),
        );
        // Sau khi quay lại từ màn hình QR, refresh danh sách đơn hàng
        // (đơn hàng đã bị hủy nếu người dùng thoát mà không thanh toán)
      } else {
        // COD hoặc các phương thức khác - chuyển đến màn hình thành công
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(order: order, isMultiple: splitMode),
          ),
          (route) => route.isFirst,
        );
      }
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLocation: _customerLat != null && _customerLng != null
              ? LatLng(_customerLat!, _customerLng!)
              : null,
          onLocationSelected: (latLng, address) {
            setState(() {
              _customerLat = latLng.latitude;
              _customerLng = latLng.longitude;
              _selectedLocationAddress = address;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.directProducts == null ? context.watch<CartProvider>().items : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đặt hàng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('Địa chỉ giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<AddressModel>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddressListScreen(),
                    ),
                  );
                  if (result != null) {
                    _onAddressSelected(result);
                  }
                },
                icon: const Icon(Icons.list_alt_outlined, size: 18),
                label: const Text('Chọn địa chỉ'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingAddresses)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else if (_selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedAddress!.displayLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(_selectedAddress!.recipientName, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_selectedAddress!.phone, style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedAddress!.addressDetail != null && _selectedAddress!.addressDetail!.isNotEmpty
                              ? '${_selectedAddress!.address}, ${_selectedAddress!.addressDetail}'
                              : _selectedAddress!.address,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chưa có địa chỉ. Vui lòng thêm địa chỉ giao hàng',
                      style: TextStyle(fontSize: 14, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (_selectedLocationAddress != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vị trí đã chọn:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedLocationAddress!,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _customerLat = null;
                        _customerLng = null;
                        _selectedLocationAddress = null;
                      });
                    },
                    icon: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
                    tooltip: 'Xóa vị trí',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _PaymentOption(
            value: 'cod',
            groupValue: _paymentMethod,
            label: 'Thanh toán khi nhận hàng (COD)',
            icon: Icons.payments_outlined,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          _PaymentOption(
            value: 'vietinbank',
            groupValue: _paymentMethod,
            label: 'MBBank QR',
            icon: Icons.qr_code_2_outlined,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          _PaymentOption(
            value: 'card',
            groupValue: _paymentMethod,
            label: 'Thẻ tín dụng / ghi nợ',
            icon: Icons.credit_card,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
          const SizedBox(height: 20),
          const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.directProducts != null)
            ...List.generate(widget.directProducts!.length, (i) {
              final p = widget.directProducts![i];
              final q = widget.directQuantities![i];
              final variant = p.selectedVariant;
              return _OrderLine(
                  product: p,
                  name: p.name,
                  price: p.displayPrice,
                  quantity: q,
                  variantInfo: variant != null ? Map<String, String>.from(variant.attributes) : null,
                );
            })
          else
            ...?cartItems?.map((item) {
              final variant = item.product.selectedVariant;
              return _OrderLine(
                product: item.product,
                name: item.product.name,
                price: item.product.displayPrice,
                quantity: item.quantity,
                variantInfo: variant != null ? Map<String, String>.from(variant.attributes) : null,
              );
            }),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(currencyFormatter.format(_total),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _placing ? null : _placeOrder,
            child: _placing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Đặt hàng ngay'),
          ),
        ],
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  final Product? product;
  final String name;
  final double price;
  final int quantity;
  final Map<String, String>? variantInfo;
  const _OrderLine({this.product, required this.name, required this.price, required this.quantity, this.variantInfo});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product?.thumbnail.startsWith('http') == true
        ? product!.thumbnail
        : (product != null ? 'http://10.0.2.2:8000/${product!.thumbnail}' : '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (product != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 50,
                height: 50,
                color: AppColors.background,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 20, color: AppColors.textGrey),
                      )
                    : const Icon(Icons.image_not_supported_outlined, size: 20, color: AppColors.textGrey),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                if (variantInfo != null && variantInfo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    variantInfo!.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 2),
                Text('x$quantity', style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(currencyFormatter.format(price * quantity), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textGrey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
