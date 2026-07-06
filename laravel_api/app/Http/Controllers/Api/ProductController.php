<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    // GET /api/products?category_id=&q=&page=
    public function index(Request $request)
    {
        $query = Product::query()->where('is_active', true)->with('category');

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->filled('q')) {
            $query->where('name', 'like', '%'.$request->q.'%');
        }

        $products = $query->latest()->paginate($request->get('per_page', 12));

        return response()->json($products);
    }

    // GET /api/products/{product}
    public function show(Product $product)
    {
        $product->load(['category', 'variantTypes', 'variants', 'reviews.user']);

        return response()->json($product);
    }
}
