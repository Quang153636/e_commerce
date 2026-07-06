<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderLocation;
use App\Models\OrderStatusHistory;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\ProductVariantType;
use App\Models\Review;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class AdminApiController extends Controller
{
    // Middleware kiểm tra admin đã được áp dụng trong routes

    // ─── Dashboard ───────────────────────────────────────────────
    public function stats()
    {
        return response()->json([
            'total_orders'    => Order::count(),
            'total_revenue'   => Order::whereIn('status', ['delivered', 'received'])->sum('total'),
            'total_products'  => Product::count(),
            'total_users'     => User::where('is_admin', false)->count(),
            'pending_orders'  => Order::where('status', 'pending')->count(),
            'shipping_orders' => Order::where('status', 'shipping')->count(),
            'paid_orders'     => Order::where('payment_status', 'paid')->count(),
            'revenue_today'   => Order::whereDate('created_at', today())
                                      ->whereIn('status', ['delivered', 'received'])
                                      ->sum('total'),
            'orders_by_status' => Order::selectRaw('status, COUNT(*) as count')
                                        ->groupBy('status')
                                        ->pluck('count', 'status'),
            'recent_orders'   => Order::with('user')->latest()->take(5)->get(),
            // Thống kê sản phẩm bán chạy
            'top_products'    => $this->getTopProducts(),
            // Thống kê đánh giá sản phẩm
            'product_reviews' => $this->getProductReviews(),
            // Thống kê tổng quan đánh giá
            'review_stats'    => $this->getReviewStats(),
        ]);
    }

    // Thống kê sản phẩm bán chạy (số lượng mua)
    private function getTopProducts()
    {
        $products = OrderItem::select('product_id', DB::raw('SUM(quantity) as total_sold'))
            ->with('product')
            ->groupBy('product_id')
            ->orderByDesc('total_sold')
            ->take(10)
            ->get();

        return $products->map(function ($item) {
            return [
                'id'          => $item->product_id,
                'name'        => $item->product->name ?? 'Sản phẩm không tồn tại',
                'total_sold'  => (int) $item->total_sold,
                'image'       => $item->product->images[0] ?? null,
                'price'       => $item->product->price ?? 0,
            ];
        });
    }

    // Thống kê đánh giá theo từng sản phẩm
    private function getProductReviews()
    {
        $products = Product::withCount('reviews')
            ->withAvg('reviews', 'rating')
            ->with(['reviews' => function ($query) {
                $query->select('product_id', 'rating', DB::raw('COUNT(*) as count'))
                    ->groupBy('product_id', 'rating');
            }])
            ->orderByDesc('reviews_count')
            ->take(20)
            ->get();

        return $products->map(function ($product) {
            $ratings = [5 => 0, 4 => 0, 3 => 0, 2 => 0, 1 => 0];
            foreach ($product->reviews as $review) {
                $ratings[(int) $review->rating] = (int) $review->count;
            }

            return [
                'id'            => $product->id,
                'name'          => $product->name,
                'total_reviews' => (int) $product->reviews_count,
                'avg_rating'    => round($product->reviews_avg_rating ?? 0, 1),
                'ratings'       => $ratings,
                'image'         => $product->images[0] ?? null,
            ];
        });
    }

    // Thống kê tổng quan về đánh giá
    private function getReviewStats()
    {
        $totalReviews = Review::count();
        $avgRating = Review::avg('rating');
        
        $ratingDistribution = Review::select('rating', DB::raw('COUNT(*) as count'))
            ->groupBy('rating')
            ->orderByDesc('rating')
            ->pluck('count', 'rating');

        return [
            'total_reviews'       => $totalReviews,
            'avg_rating'          => round($avgRating ?? 0, 1),
            'rating_distribution' => $ratingDistribution,
            'five_stars'          => $ratingDistribution[5] ?? 0,
            'four_stars'          => $ratingDistribution[4] ?? 0,
            'three_stars'         => $ratingDistribution[3] ?? 0,
            'two_stars'           => $ratingDistribution[2] ?? 0,
            'one_star'            => $ratingDistribution[1] ?? 0,
        ];
    }

    // Thống kê chi tiết theo sản phẩm
    public function productStats(Request $request, $productId = null)
    {
        $query = Product::query();
        
        if ($productId != null) {
            $query->where('id', $productId);
        }
        
        if ($request->filled('q')) {
            $query->where('name', 'like', '%' . $request->q . '%');
        }
        
        $products = $query->with('category')->get();
        
        $stats = $products->map(function ($product) {
            // Tổng số đã bán
            $totalSold = OrderItem::where('product_id', $product->id)
                ->sum('quantity');
            
            // Doanh thu
            $revenue = OrderItem::where('product_id', $product->id)
                ->join('orders', 'orders.id', '=', 'order_items.order_id')
                ->whereIn('orders.status', ['delivered', 'received'])
                ->sum(DB::raw('order_items.price * order_items.quantity'));
            
            // Thống kê đánh giá
            $reviews = Review::where('product_id', $product->id)
                ->select('rating', DB::raw('COUNT(*) as count'))
                ->groupBy('rating')
                ->get()
                ->pluck('count', 'rating');
            
            $totalReviews = $reviews->sum();
            $avgRating = $reviews->isEmpty() ? 0 : round($reviews->keys()->map(function ($rating) use ($reviews) {
                return $rating * $reviews[$rating];
            })->sum() / $totalReviews, 1);
            
            // Đơn hàng gần đây
            $recentOrders = Order::whereHas('items', function ($q) use ($product) {
                $q->where('product_id', $product->id);
            })
            ->with('user')
            ->latest()
            ->take(5)
            ->get();
            
            return [
                'id'            => $product->id,
                'name'          => $product->name,
                'category'      => $product->category->name ?? 'N/A',
                'price'         => $product->price,
                'sale_price'    => $product->sale_price,
                'stock'         => $product->stock,
                'total_sold'    => (int) $totalSold,
                'revenue'       => (float) $revenue,
                'total_reviews' => (int) $totalReviews,
                'avg_rating'    => $avgRating,
                'ratings'       => [
                    '5' => $reviews[5] ?? 0,
                    '4' => $reviews[4] ?? 0,
                    '3' => $reviews[3] ?? 0,
                    '2' => $reviews[2] ?? 0,
                    '1' => $reviews[1] ?? 0,
                ],
                'recent_orders' => $recentOrders->map(fn($o) => [
                    'id' => $o->id,
                    'code' => $o->code,
                    'user_name' => $o->user->name ?? 'Ẩn danh',
                    'total' => $o->total,
                    'status' => $o->status,
                    'created_at' => $o->created_at,
                ]),
            ];
        });
        
        if ($productId != null && $stats->isNotEmpty()) {
            return response()->json($stats->first());
        }
        
        return response()->json($stats);
    }

    // ─── Orders ──────────────────────────────────────────────────
    public function orders(Request $request)
    {
        $query = Order::with(['user', 'items', 'latestLocation'])->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('q')) {
            $q = $request->q;
            $query->where(function ($q2) use ($q) {
                $q2->where('code', 'like', "%$q%")
                   ->orWhereHas('user', fn($u) => $u->where('name', 'like', "%$q%")
                                                     ->orWhere('email', 'like', "%$q%"));
            });
        }

        return response()->json($query->paginate(15));
    }

    public function orderDetail(Order $order)
    {
        $order->load(['user', 'items.product', 'statusHistories', 'locations']);
        return response()->json($order);
    }

    public function updateOrderStatus(Request $request, Order $order)
    {
        $data = $request->validate([
            'status' => 'required|in:' . implode(',', Order::STATUSES),
            'note'   => 'nullable|string|max:255',
        ]);

        $order->update(['status' => $data['status']]);

        OrderStatusHistory::create([
            'order_id'   => $order->id,
            'status'     => $data['status'],
            'note'       => $data['note'] ?? 'Admin cập nhật qua app',
            'created_at' => now(),
        ]);

        return response()->json($order->load('statusHistories'));
    }

    public function updateOrderLocation(Request $request, Order $order)
    {
        $data = $request->validate([
            'lat'           => 'required|numeric',
            'lng'           => 'required|numeric',
            'shipper_name'  => 'nullable|string|max:100',
            'shipper_phone' => 'nullable|string|max:20',
        ]);

        $location = OrderLocation::create(array_merge($data, ['order_id' => $order->id]));
        return response()->json($location);
    }

    // ─── Products ────────────────────────────────────────────────
    public function products(Request $request)
    {
        $query = Product::with(['category', 'variantTypes', 'variants'])->latest();

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }
        if ($request->filled('q')) {
            $query->where('name', 'like', '%' . $request->q . '%');
        }

        return response()->json($query->paginate(15));
    }

    public function createProduct(Request $request)
    {
        DB::beginTransaction();

        try {
            $data = $request->validate([
                'category_id'     => 'required|exists:categories,id',
                'name'            => 'required|string|max:255',
                'description'     => 'nullable|string',
                'price'           => 'required|numeric|min:0',
                'sale_price'      => 'nullable|numeric|min:0',
                'stock'           => 'required|integer|min:0',
                'images'          => 'nullable|array',
                'is_active'       => 'boolean',
                'variant_types'   => 'nullable|array',
                'variant_types.*.name'    => 'required|string|max:100',
                'variant_types.*.options' => 'required|array|min:1',
                'variants'        => 'nullable|array',
                'variants.*.attributes' => 'required|array',
                'variants.*.price'      => 'nullable|numeric|min:0',
                'variants.*.stock'      => 'required|integer|min:0',
                'variants.*.sku'        => 'nullable|string|max:100',
            ]);

            $data['slug']      = Str::slug($data['name']) . '-' . Str::random(5);
            $data['images']    = $data['images'] ?? [];
            $data['is_active'] = $data['is_active'] ?? true;

            $product = Product::create($data);

            // Tạo variant types nếu có
            if (!empty($data['variant_types'])) {
                foreach ($data['variant_types'] as $typeData) {
                    $product->variantTypes()->create([
                        'name'    => $typeData['name'],
                        'options' => $typeData['options'],
                    ]);
                }
            }

            // Tạo variants nếu có
            if (!empty($data['variants'])) {
                foreach ($data['variants'] as $variantData) {
                    $product->variants()->create($variantData);
                }
            }

            // Đồng bộ tổng stock từ variants nếu có
            $product->syncStock();

            DB::commit();
            return response()->json($product->load(['category', 'variantTypes', 'variants']), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function updateProduct(Request $request, Product $product)
    {
        DB::beginTransaction();

        try {
            $data = $request->validate([
                'category_id'     => 'sometimes|exists:categories,id',
                'name'            => 'sometimes|string|max:255',
                'description'     => 'nullable|string',
                'price'           => 'sometimes|numeric|min:0',
                'sale_price'      => 'nullable|numeric|min:0',
                'stock'           => 'sometimes|integer|min:0',
                'images'          => 'nullable|array',
                'is_active'       => 'boolean',
                'variant_types'   => 'nullable|array',
                'variant_types.*.id'      => 'nullable|integer|exists:product_variant_types,id',
                'variant_types.*.name'    => 'required|string|max:100',
                'variant_types.*.options' => 'required|array|min:1',
                'variants'        => 'nullable|array',
                'variants.*.id'           => 'nullable|integer|exists:product_variants,id',
                'variants.*.attributes'   => 'required|array',
                'variants.*.price'        => 'nullable|numeric|min:0',
                'variants.*.stock'        => 'required|integer|min:0',
                'variants.*.sku'          => 'nullable|string|max:100',
            ]);

            $product->update($data);

            // Cập nhật variant types nếu có
            if (isset($data['variant_types'])) {
                // Xóa các variant types không còn trong danh sách
                $keepTypeIds = collect($data['variant_types'])
                    ->filter(fn($t) => isset($t['id']))
                    ->pluck('id')
                    ->toArray();
                
                $product->variantTypes()->whereNotIn('id', $keepTypeIds)->delete();

                // Cập nhật hoặc tạo mới
                foreach ($data['variant_types'] as $typeData) {
                    if (isset($typeData['id'])) {
                        // Cập nhật
                        $type = $product->variantTypes()->find($typeData['id']);
                        if ($type) {
                            $type->update([
                                'name'    => $typeData['name'],
                                'options' => $typeData['options'],
                            ]);
                        }
                    } else {
                        // Tạo mới
                        $product->variantTypes()->create([
                            'name'    => $typeData['name'],
                            'options' => $typeData['options'],
                        ]);
                    }
                }
            }

            // Cập nhật variants nếu có
            if (isset($data['variants'])) {
                // Xóa các variants không còn trong danh sách
                $keepVariantIds = collect($data['variants'])
                    ->filter(fn($v) => isset($v['id']))
                    ->pluck('id')
                    ->toArray();
                
                $product->variants()->whereNotIn('id', $keepVariantIds)->delete();

                // Cập nhật hoặc tạo mới
                foreach ($data['variants'] as $variantData) {
                    if (isset($variantData['id'])) {
                        // Cập nhật
                        $variant = $product->variants()->find($variantData['id']);
                        if ($variant) {
                            $variant->update([
                                'attributes' => $variantData['attributes'],
                                'price'      => $variantData['price'] ?? null,
                                'stock'      => $variantData['stock'],
                                'sku'        => $variantData['sku'] ?? null,
                            ]);
                        }
                    } else {
                        // Tạo mới
                        $product->variants()->create([
                            'attributes' => $variantData['attributes'],
                            'price'      => $variantData['price'] ?? null,
                            'stock'      => $variantData['stock'],
                            'sku'        => $variantData['sku'] ?? null,
                        ]);
                    }
                }
            }

            // Đồng bộ tổng stock từ variants nếu có
            $product->syncStock();

            DB::commit();
            return response()->json($product->load(['category', 'variantTypes', 'variants']));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function deleteProduct(Product $product)
    {
        $product->delete();
        return response()->json(['message' => 'Đã xoá sản phẩm']);
    }

    // ─── Categories ──────────────────────────────────────────────
    public function categories()
    {
        return response()->json(
            Category::withCount('products')->orderBy('name')->get()
        );
    }

    public function createCategory(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100|unique:categories,name',
            'icon' => 'nullable|string|max:50',
        ]);
        $data['slug'] = Str::slug($data['name']);
        $category = Category::create($data);
        return response()->json($category, 201);
    }

    public function updateCategory(Request $request, Category $category)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100|unique:categories,name,' . $category->id,
            'icon' => 'nullable|string|max:50',
        ]);
        $data['slug'] = Str::slug($data['name']);
        $category->update($data);
        return response()->json($category);
    }

    public function deleteCategory(Category $category)
    {
        $category->delete();
        return response()->json(['message' => 'Đã xoá danh mục']);
    }

    // ─── Users ───────────────────────────────────────────────────
    public function users(Request $request)
    {
        $query = User::withCount('orders')->latest();

        if ($request->filled('q')) {
            $q = $request->q;
            $query->where(fn($q2) => $q2->where('name', 'like', "%$q%")
                                        ->orWhere('email', 'like', "%$q%"));
        }

        return response()->json($query->paginate(15));
    }

    public function toggleAdmin(Request $request, User $user)
    {
        if ($user->id === $request->user()->id) {
            return response()->json(['message' => 'Không thể thay đổi quyền của chính mình'], 422);
        }
        $user->update(['is_admin' => !$user->is_admin]);
        return response()->json($user);
    }

    public function deleteUser(Request $request, User $user)
    {
        if ($user->id === $request->user()->id) {
            return response()->json(['message' => 'Không thể xoá tài khoản đang đăng nhập'], 422);
        }
        $user->delete();
        return response()->json(['message' => 'Đã xoá người dùng']);
    }
}