<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderLocation;
use App\Models\OrderStatusHistory;
use App\Models\Product;
use App\Models\Review;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OrderController extends Controller
{
    // GET /api/orders  - lịch sử đơn hàng của user
    public function index(Request $request)
    {
        $orders = $request->user()->orders()
            ->with(['items', 'statusHistories', 'latestLocation'])
            ->latest()
            ->paginate(10);

        return response()->json($orders);
    }

    // GET /api/orders/{order} - chi tiết đơn hàng + theo dõi
    // Khi Flutter poll API này, nếu đơn hàng VietinBank đã tồn tại >30s,
    // hệ thống sẽ tự động xác nhận thanh toán (mô phỏng webhook từ ngân hàng)
    public function show(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);

        $order->load(['items.product', 'statusHistories', 'locations']);

        // Đánh dấu các sản phẩm đã được đánh giá
        $reviews = Review::where('order_id', $order->id)
            ->where('user_id', $request->user()->id)
            ->get(['order_item_id']);
        $reviewedItemIds = $reviews->pluck('order_item_id')->toArray();

        $order->items->each(function ($item) use ($reviewedItemIds) {
            $item->has_review = in_array($item->id, $reviewedItemIds);
        });

        // Auto-confirm: Nếu đơn hàng VietinBank chưa thanh toán và đã quá 30 giây
        // (Mô phỏng ngân hàng gửi webhook xác nhận sau khi user chuyển tiền)
        if ($order->payment_method === 'vietinbank' 
            && $order->payment_status === 'unpaid'
            && $order->created_at !== null
            && $order->created_at->diffInSeconds(now()) >= 30) {
            
            // Ngân hàng xác nhận giao dịch thành công
            $order->update(['payment_status' => 'paid']);
            OrderStatusHistory::create([
                'order_id' => $order->id,
                'status' => 'pending',
                'note' => 'Ngân hàng xác nhận: Đã nhận được thanh toán VietinBank - ' . number_format($order->total) . 'đ',
                'created_at' => now(),
            ]);
        }

        return response()->json($order);
    }

    // POST /api/orders  { shipping_address, shipping_phone, payment_method, items?:[{product_id,quantity}] }
    // Nếu không truyền items, hệ thống sẽ lấy từ giỏ hàng hiện tại của user (luồng "mua hàng" / "đặt hàng")
    public function store(Request $request)
    {
        $data = $request->validate([
            'shipping_address' => 'required|string|max:255',
            'shipping_phone' => 'required|string|max:20',
            'payment_method' => 'sometimes|in:cod,vietinbank,vnpay,card',
            'items' => 'sometimes|array',
            'items.*.product_id' => 'required_with:items|exists:products,id',
            'items.*.quantity' => 'required_with:items|integer|min:1',
            'items.*.variant_info' => 'nullable|array',
            'items.*.variant_id' => 'nullable|integer|exists:product_variants,id',
            'customer_lat' => 'nullable|numeric|between:-90,90',
            'customer_lng' => 'nullable|numeric|between:-180,180',
        ]);

        $user = $request->user();

        return DB::transaction(function () use ($data, $user, $request) {
            if (! empty($data['items'])) {
                $lines = collect($data['items'])->map(function ($line) {
                    $product = Product::findOrFail($line['product_id']);
                    return ['product' => $product, 'quantity' => $line['quantity']];
                });
            } else {
                $cartItems = $user->cartItems()->with(['product', 'variant'])->get();
                abort_if($cartItems->isEmpty(), 422, 'Giỏ hàng trống');
                $lines = $cartItems->map(fn ($ci) => [
                    'product' => $ci->product,
                    'quantity' => $ci->quantity,
                    'variant_id' => $ci->variant_id,
                    'variant_info' => $ci->variant ? $ci->variant->attributes : null,
                ]);
            }

            $total = $lines->sum(fn ($l) => ($l['product']->sale_price ?? $l['product']->price) * $l['quantity']);

            $order = Order::create([
                'code' => 'ORD-'.Str::upper(Str::random(8)),
                'user_id' => $user->id,
                'total' => $total,
                'shipping_address' => $data['shipping_address'],
                'shipping_phone' => $data['shipping_phone'],
                'payment_method' => $data['payment_method'] ?? 'cod',
                'payment_status' => 'unpaid',
                'status' => 'pending',
                'customer_lat' => $data['customer_lat'] ?? null,
                'customer_lng' => $data['customer_lng'] ?? null,
            ]);

            foreach ($lines as $index => $line) {
                // Lấy variant_info và variant_id từ line (đã được map từ cart items)
                // hoặc từ request data items (nếu là mua ngay)
                $variantInfo = $line['variant_info'] ?? null;
                $variantId = $line['variant_id'] ?? null;

                // Nếu mua trực tiếp (có data['items']), lấy từ request
                if (! empty($data['items']) && isset($data['items'][$index])) {
                    if (isset($data['items'][$index]['variant_info'])) {
                        $variantInfo = $data['items'][$index]['variant_info'];
                    }
                    if (isset($data['items'][$index]['variant_id'])) {
                        $variantId = $data['items'][$index]['variant_id'];
                    }
                }

                // Nếu có variant_info nhưng chưa có variant_id, tìm từ attributes
                if (empty($variantId) && ! empty($variantInfo)) {
                    $matchingVariant = $line['product']->variants()
                        ->where('attributes', json_encode($variantInfo))
                        ->first();
                    if ($matchingVariant) {
                        $variantId = $matchingVariant->id;
                    }
                }
                
                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $line['product']->id,
                    'product_name' => $line['product']->name,
                    'price' => $line['product']->sale_price ?? $line['product']->price,
                    'quantity' => $line['quantity'],
                    'variant_info' => $variantInfo,
                    'variant_id' => $variantId,
                ]);
                
                // Giảm stock của variant cụ thể (nếu có)
                if ($variantId) {
                    $variant = \App\Models\ProductVariant::find($variantId);
                    if ($variant) {
                        $variant->decrement('stock', $line['quantity']);
                        // Đồng bộ tổng stock của sản phẩm từ các variants
                        $line['product']->syncStock();
                    }
                } else {
                    // Nếu không có variant, giảm stock trực tiếp trên sản phẩm
                    $line['product']->decrement('stock', $line['quantity']);
                }
            }

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'status' => 'pending',
                'note' => 'Khách hàng đã đặt hàng',
                'created_at' => now(),
            ]);

            // Nếu đặt hàng từ giỏ hàng thì xoá giỏ hàng sau khi tạo đơn
            if (empty($data['items'])) {
                $user->cartItems()->delete();
            }

            // Mô phỏng webhook từ ngân hàng VietinBank
            //
            // Luồng thực tế:
            //   1. User quét QR bằng app ngân hàng, chuyển tiền thành công
            //   2. Ngân hàng gọi webhook đến server: POST /api/vietinbank/webhook
            //   3. Server kiểm tra mã đơn hàng, số tiền -> cập nhật payment_status = 'paid'
            //   4. Flutter poll phát hiện payment_status = 'paid' -> thông báo thành công
            //
            // Mô phỏng (không cần queue worker):
            //   - Khi Flutter poll API GET /api/orders/{id} (mỗi 10 giây),
            //     nếu đơn hàng đã tồn tại >30s, server tự động xác nhận
            //   - Giống hệt: user chuyển tiền -> ngân hàng xử lý 30s -> webhook -> cập nhật
            if (($data['payment_method'] ?? 'cod') === 'vietinbank') {
                OrderStatusHistory::create([
                    'order_id' => $order->id,
                    'status' => 'pending',
                    'note' => 'Đã tạo đơn hàng. Vui lòng quét mã QR để thanh toán qua VietinBank',
                    'created_at' => now(),
                ]);
            }

            return response()->json($order->load(['items', 'statusHistories']), 201);
        });
    }

    // PUT /api/orders/{order}/status  { status, note }  (dùng cho shipper/admin cập nhật trạng thái)
    public function updateStatus(Request $request, Order $order)
    {
        $data = $request->validate([
            'status' => 'required|in:'.implode(',', Order::STATUSES),
            'note' => 'nullable|string|max:255',
        ]);

        $order->update(['status' => $data['status']]);

        OrderStatusHistory::create([
            'order_id' => $order->id,
            'status' => $data['status'],
            'note' => $data['note'] ?? null,
            'created_at' => now(),
        ]);

        return response()->json($order->load('statusHistories'));
    }

    // POST /api/orders/{order}/confirm-received  - khách xác nhận đã nhận hàng
    public function confirmReceived(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);

        $order->update(['status' => 'received']);
        OrderStatusHistory::create([
            'order_id' => $order->id,
            'status' => 'received',
            'note' => 'Khách hàng đã xác nhận nhận hàng',
            'created_at' => now(),
        ]);

        return response()->json($order->load('statusHistories'));
    }

    // POST /api/vietinbank/webhook - Webhook giả lập từ ngân hàng VietinBank
    // Trong thực tế, ngân hàng sẽ gọi endpoint này khi có giao dịch thành công
    // Endpoint này không yêu cầu auth, giống như webhook thật
    public function vietinbankWebhook(Request $request)
    {
        $data = $request->validate([
            'order_code' => 'required|string',
            'amount' => 'required|numeric',
            'status' => 'sometimes|string',
        ]);

        // Tìm đơn hàng theo mã code
        $order = Order::where('code', $data['order_code'])->first();

        if (!$order || $order->payment_method !== 'vietinbank') {
            return response()->json(['message' => 'Đơn hàng không hợp lệ'], 404);
        }

        if ($order->payment_status === 'paid') {
            return response()->json(['message' => 'Đơn hàng đã được thanh toán trước đó'], 200);
        }

        // Cập nhật trạng thái thanh toán
        $order->update(['payment_status' => 'paid']);
        OrderStatusHistory::create([
            'order_id' => $order->id,
            'status' => $order->status,
            'note' => 'Ngân hàng xác nhận: Đã nhận được thanh toán VietinBank - ' . number_format($data['amount']) . 'đ',
            'created_at' => now(),
        ]);

        return response()->json([
            'message' => 'Cập nhật thanh toán thành công',
            'payment_status' => 'paid',
            'order' => $order->load('statusHistories'),
        ]);
    }

    // POST /api/orders/{order}/confirm-vietinbank-payment - khách xác nhận đã thanh toán qua VietinBank QR
    public function confirmVietinbankPayment(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);
        abort_if($order->payment_method !== 'vietinbank', 422, 'Phương thức thanh toán không phải VietinBank');
        abort_if($order->payment_status === 'paid', 422, 'Đơn hàng đã được thanh toán');

        $order->update(['payment_status' => 'paid']);
        OrderStatusHistory::create([
            'order_id' => $order->id,
            'status' => $order->status,
            'note' => 'Khách hàng đã thanh toán qua VietinBank',
            'created_at' => now(),
        ]);

        return response()->json($order->load('statusHistories'));
    }

    // POST /api/orders/{order}/cancel - khách hủy đơn (chỉ khi còn đang pending/confirmed)
    public function cancel(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);
        abort_unless(in_array($order->status, ['pending', 'confirmed']), 422, 'Không thể hủy đơn ở trạng thái hiện tại');

        DB::transaction(function () use ($order) {
            $order->update(['status' => 'cancelled']);
            
            // Hoàn lại tồn kho cho các sản phẩm trong đơn hàng
            $items = $order->items()->get();
            foreach ($items as $item) {
                if ($item->variant_id) {
                    $variant = \App\Models\ProductVariant::find($item->variant_id);
                    if ($variant) {
                        $variant->increment('stock', $item->quantity);
                        // Đồng bộ tổng stock của sản phẩm từ các variants
                        $product = $variant->product;
                        if ($product) {
                            $product->syncStock();
                        }
                    }
                } else {
                    // Nếu không có variant, hoàn stock trực tiếp trên sản phẩm
                    $product = \App\Models\Product::find($item->product_id);
                    if ($product) {
                        $product->increment('stock', $item->quantity);
                    }
                }
            }

            OrderStatusHistory::create([
                'order_id' => $order->id,
                'status' => 'cancelled',
                'note' => 'Khách hàng đã hủy đơn - Đã hoàn lại tồn kho',
                'created_at' => now(),
            ]);
        });

        return response()->json($order->load('statusHistories'));
    }

    // GET /api/orders/{order}/track - lấy vị trí mới nhất + lịch sử di chuyển để hiển thị trên map
    public function track(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);

        return response()->json([
            'order' => $order->only(['id', 'code', 'status']),
            'current_location' => $order->latestLocation,
            'path' => $order->locations()->orderBy('created_at')->get(),
            'destination' => $order->shipping_address,
        ]);
    }

    // POST /api/orders/{order}/location  { lat, lng, shipper_name?, shipper_phone? }
    // Dùng cho shipper/app giao hàng gửi vị trí GPS định kỳ
    public function updateLocation(Request $request, Order $order)
    {
        $data = $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
            'shipper_name' => 'nullable|string|max:100',
            'shipper_phone' => 'nullable|string|max:20',
        ]);

        $location = OrderLocation::create(array_merge($data, ['order_id' => $order->id]));

        return response()->json($location, 201);
    }

    // POST /api/orders/{order}/reviews  { order_item_id, rating, comment? }
    // Khách hàng đánh giá sản phẩm trong đơn hàng sau khi nhận hàng
    public function storeReview(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);
        abort_if($order->status !== 'received', 422, 'Chỉ có thể đánh giá đơn hàng đã nhận');

        $data = $request->validate([
            'order_item_id' => 'required|exists:order_items,id',
            'rating' => 'required|integer|between:1,5',
            'comment' => 'nullable|string|max:1000',
        ]);

        // Kiểm tra order_item thuộc đơn hàng này
        $orderItem = OrderItem::where('id', $data['order_item_id'])
            ->where('order_id', $order->id)
            ->firstOrFail();

        // Kiểm tra đã đánh giá chưa
        $existingReview = Review::where('user_id', $request->user()->id)
            ->where('order_item_id', $data['order_item_id'])
            ->first();

        if ($existingReview) {
            return response()->json(['message' => 'Bạn đã đánh giá sản phẩm này'], 422);
        }

        $review = Review::create([
            'user_id' => $request->user()->id,
            'product_id' => $orderItem->product_id,
            'order_id' => $order->id,
            'order_item_id' => $data['order_item_id'],
            'rating' => $data['rating'],
            'comment' => $data['comment'] ?? null,
        ]);

        // Cập nhật rating trung bình của sản phẩm
        $this->updateProductRating($orderItem->product_id);

        return response()->json($review->load('user'), 201);
    }

    // GET /api/orders/{order}/reviews  - lấy danh sách đánh giá của đơn hàng
    public function getOrderReviews(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);

        $reviews = Review::where('order_id', $order->id)
            ->with('product')
            ->get();

        return response()->json($reviews);
    }

    // Cập nhật rating trung bình cho sản phẩm
    private function updateProductRating(int $productId): void
    {
        $avgRating = Review::where('product_id', $productId)->avg('rating');
        Product::where('id', $productId)->update(['rating' => round($avgRating, 1)]);
    }
}
