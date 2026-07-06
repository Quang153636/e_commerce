<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use App\Models\Category;

class DashboardController extends Controller
{
    public function index()
    {
        $stats = [
            'total_orders'    => Order::count(),
            'total_revenue'   => Order::whereIn('status', ['delivered', 'received'])->sum('total'),
            'total_products'  => Product::count(),
            'total_users'     => User::where('is_admin', false)->count(),
            'pending_orders'  => Order::where('status', 'pending')->count(),
            'shipping_orders' => Order::where('status', 'shipping')->count(),
        ];

        $recentOrders = Order::with('user')
            ->latest()
            ->take(8)
            ->get();

        $topProducts = Product::withCount('favoritedBy')
            ->orderByDesc('favorited_by_count')
            ->take(5)
            ->get();

        $ordersByStatus = Order::selectRaw('status, COUNT(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');

        return view('admin.dashboard', compact('stats', 'recentOrders', 'topProducts', 'ordersByStatus'));
    }
}
