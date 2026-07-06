<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CartItem;
use Illuminate\Http\Request;

class CartController extends Controller
{
    // GET /api/cart
    public function index(Request $request)
    {
        $items = $request->user()->cartItems()->with(['product.category', 'variant'])->get();
        $total = $items->sum(function ($item) {
            $price = $item->product->sale_price ?? $item->product->price;
            return $price * $item->quantity;
        });

        return response()->json(['items' => $items, 'total' => $total]);
    }

    // POST /api/cart  { product_id, quantity, variant_id? }
    public function store(Request $request)
    {
        $data = $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity' => 'sometimes|integer|min:1',
            'variant_id' => 'nullable|integer|exists:product_variants,id',
        ]);

        // Tìm cart item có cùng user_id + product_id + variant_id (nếu có)
        $query = CartItem::where('user_id', $request->user()->id)
            ->where('product_id', $data['product_id']);

        if (!empty($data['variant_id'])) {
            $query->where('variant_id', $data['variant_id']);
        } else {
            $query->whereNull('variant_id');
        }

        $item = $query->first();

        if ($item) {
            // Đã có trong giỏ -> tăng số lượng
            $item->quantity += $data['quantity'] ?? 1;
            $item->save();
        } else {
            // Chưa có -> tạo mới
            $item = CartItem::create([
                'user_id' => $request->user()->id,
                'product_id' => $data['product_id'],
                'variant_id' => $data['variant_id'] ?? null,
                'quantity' => $data['quantity'] ?? 1,
            ]);
        }

        return response()->json($item->load(['product', 'variant']), 201);
    }

    // PUT /api/cart/{cartItem}  { quantity }
    public function update(Request $request, CartItem $cartItem)
    {
        abort_if($cartItem->user_id !== $request->user()->id, 403);

        $data = $request->validate(['quantity' => 'required|integer|min:1']);
        $cartItem->update($data);

        return response()->json($cartItem->load(['product', 'variant']));
    }

    // DELETE /api/cart/{cartItem}
    public function destroy(Request $request, CartItem $cartItem)
    {
        abort_if($cartItem->user_id !== $request->user()->id, 403);
        $cartItem->delete();

        return response()->json(['message' => 'Đã xoá sản phẩm khỏi giỏ hàng']);
    }

    // DELETE /api/cart  (clear)
    public function clear(Request $request)
    {
        $request->user()->cartItems()->delete();

        return response()->json(['message' => 'Đã xoá toàn bộ giỏ hàng']);
    }
}