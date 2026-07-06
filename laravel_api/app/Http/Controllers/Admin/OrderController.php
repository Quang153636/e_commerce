<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatusHistory;
use App\Models\OrderLocation;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $query = Order::with('user')->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('q')) {
            $query->where('code', 'like', '%'.$request->q.'%')
                  ->orWhereHas('user', fn($q) => $q->where('name', 'like', '%'.$request->q.'%'));
        }

        $orders = $query->paginate(15)->withQueryString();
        $statuses = Order::STATUSES;

        return view('admin.orders.index', compact('orders', 'statuses'));
    }

    public function show(Order $order)
    {
        $order->load(['user', 'items.product', 'statusHistories', 'locations']);
        $statuses = Order::STATUSES;
        return view('admin.orders.show', compact('order', 'statuses'));
    }

    public function updateStatus(Request $request, Order $order)
    {
        $data = $request->validate([
            'status' => 'required|in:'.implode(',', Order::STATUSES),
            'note'   => 'nullable|string|max:255',
        ]);

        $order->update(['status' => $data['status']]);

        OrderStatusHistory::create([
            'order_id'   => $order->id,
            'status'     => $data['status'],
            'note'       => $data['note'] ?? 'Admin cập nhật trạng thái',
            'created_at' => now(),
        ]);

        return back()->with('success', 'Đã cập nhật trạng thái đơn hàng thành công!');
    }

    public function updateLocation(Request $request, Order $order)
    {
        $data = $request->validate([
            'lat'           => 'required|numeric',
            'lng'           => 'required|numeric',
            'shipper_name'  => 'nullable|string|max:100',
            'shipper_phone' => 'nullable|string|max:20',
        ]);

        OrderLocation::create(array_merge($data, ['order_id' => $order->id]));

        return back()->with('success', 'Đã cập nhật vị trí shipper!');
    }
}
