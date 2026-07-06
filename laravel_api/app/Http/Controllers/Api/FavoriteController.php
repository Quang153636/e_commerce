<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Favorite;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    // GET /api/favorites
    public function index(Request $request)
    {
        $favorites = $request->user()->favorites()->with('product.category')->latest()->get();

        return response()->json($favorites);
    }

    // POST /api/favorites  { product_id }
    public function store(Request $request)
    {
        $request->validate(['product_id' => 'required|exists:products,id']);

        $favorite = Favorite::firstOrCreate([
            'user_id' => $request->user()->id,
            'product_id' => $request->product_id,
        ]);

        return response()->json($favorite->load('product'), 201);
    }

    // DELETE /api/favorites/{product}
    public function destroy(Request $request, $productId)
    {
        Favorite::where('user_id', $request->user()->id)
            ->where('product_id', $productId)
            ->delete();

        return response()->json(['message' => 'Đã bỏ yêu thích']);
    }
}
