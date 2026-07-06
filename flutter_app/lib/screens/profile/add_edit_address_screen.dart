import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/address.dart';
import '../../services/address_service.dart';
import '../../widgets/map_location_picker.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _addressDetailCtrl = TextEditingController();
  bool _isDefault = false;
  bool _saving = false;
  double? _selectedLat;
  double? _selectedLng;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  Position? _currentPosition;
  bool _hasDifferentLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _labelCtrl.text = widget.address!.label ?? '';
      _recipientNameCtrl.text = widget.address!.recipientName;
      _phoneCtrl.text = widget.address!.phone;
      _addressCtrl.text = widget.address!.address;
      _addressDetailCtrl.text = widget.address!.addressDetail ?? '';
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _recipientNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _addressDetailCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cần cấp quyền truy cập vị trí')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền vị trí bị từ chối vĩnh viễn')),
          );
        }
        return;
      }

      // Lấy vị trí hiện tại
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Lấy địa chỉ từ tọa độ
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        final address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        
        setState(() {
          _addressCtrl.text = address;
          _currentAddress = address;
          _selectedLat = position.latitude;
          _selectedLng = position.longitude;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lấy vị trí hiện tại')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy vị trí hiện tại')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _openMapPicker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLocation: _selectedLat != null && _selectedLng != null
              ? LatLng(_selectedLat!, _selectedLng!)
              : null,
          onLocationSelected: (latLng, address) {
            setState(() {
              _selectedLat = latLng.latitude;
              _selectedLng = latLng.longitude;
              if (address != null && address.isNotEmpty) {
                _addressCtrl.text = address;
                _currentAddress = address;
              }
              
              // Kiểm tra xem vị trí đã chọn có khác vị trí hiện tại không
              if (_currentPosition != null) {
                final distance = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  latLng.latitude,
                  latLng.longitude,
                );
                // Nếu khoảng cách > 100m thì coi là khác vị trí
                _hasDifferentLocation = distance > 100;
              } else {
                _hasDifferentLocation = true;
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.address == null) {
        await AddressService.createAddress(
          recipientName: _recipientNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          addressDetail: _addressDetailCtrl.text.trim().isEmpty ? null : _addressDetailCtrl.text.trim(),
          label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
          isDefault: _isDefault,
        );
        Fluttertoast.showToast(msg: 'Thêm địa chỉ thành công');
      } else {
        await AddressService.updateAddress(
          widget.address!.id,
          recipientName: _recipientNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          addressDetail: _addressDetailCtrl.text.trim().isEmpty ? null : _addressDetailCtrl.text.trim(),
          label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
          isDefault: _isDefault,
        );
        Fluttertoast.showToast(msg: 'Cập nhật địa chỉ thành công');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Có lỗi xảy ra, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Nhãn (tùy chọn)',
                hintText: 'Ví dụ: Nhà, Văn phòng',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recipientNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên người nhận',
                hintText: 'Nhập tên người nhận hàng',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên người nhận' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: 'Nhập số điện thoại liên hệ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'Địa chỉ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _openMapPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _addressCtrl.text.isEmpty ? 'Chọn địa chỉ' : _addressCtrl.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: _addressCtrl.text.isEmpty ? Colors.grey.shade500 : Colors.black,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
            if (_currentAddress != null && _hasDifferentLocation) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vị trí đã chọn',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentAddress!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 20),
                        label: const Text('Sử dụng vị trí hiện tại'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressDetailCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Chi tiết địa chỉ',
                hintText: 'Nhập số nhà, tầng, tên tòa nhà (không bắt buộc)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text('Đặt làm địa chỉ mặc định'),
              subtitle: const Text('Địa chỉ này sẽ được tự động chọn khi đặt hàng'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Cập nhật' : 'Thêm địa chỉ'),
            ),
          ],
        ),
      ),
    );
  }
}