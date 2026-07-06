import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';

class OrderTrackingMapScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingMapScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingMapScreen> createState() => _OrderTrackingMapScreenState();
}

class _OrderTrackingMapScreenState extends State<OrderTrackingMapScreen> {
  GoogleMapController? _mapController;
  Timer? _pollTimer;
  LatLng? _currentPosition;
  String? _shipperName;
  String? _shipperPhone;
  String? _destinationAddress;
  bool _loading = true;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchTracking();
    // Cập nhật vị trí mỗi 10 giây để theo dõi đơn hàng đang ở đâu theo thời gian thực
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchTracking());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTracking() async {
    try {
      final data = await OrderService.trackOrder(widget.orderId);
      final location = data['current_location'];
      _destinationAddress = data['destination'];

      if (location != null) {
        final lat = double.tryParse(location['lat'].toString()) ?? 0;
        final lng = double.tryParse(location['lng'].toString()) ?? 0;
        final newPosition = LatLng(lat, lng);

        setState(() {
          _currentPosition = newPosition;
          _shipperName = location['shipper_name'];
          _shipperPhone = location['shipper_phone'];
          _hasLocation = true;
          _loading = false;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
      } else {
        setState(() {
          _hasLocation = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theo dõi đơn hàng')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasLocation
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.location_off_outlined, size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có dữ liệu vị trí cho đơn hàng này.\nVị trí shipper sẽ hiển thị khi đơn hàng đang được giao.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 15),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: {
                        Marker(
                          markerId: const MarkerId('shipper'),
                          position: _currentPosition!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                          infoWindow: InfoWindow(title: _shipperName ?? 'Shipper'),
                        ),
                      },
                      myLocationButtonEnabled: false,
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.delivery_dining, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_shipperName ?? 'Đang giao hàng',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (_shipperPhone != null)
                                        Text(_shipperPhone!,
                                            style: const TextStyle(color: AppColors.textGrey)),
                                    ],
                                  ),
                                ),
                                if (_shipperPhone != null)
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: AppColors.success),
                                    onPressed: () {},
                                  ),
                              ],
                            ),
                            if (_destinationAddress != null) ...[
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.flag_outlined, size: 18, color: AppColors.textGrey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Giao đến: $_destinationAddress',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
