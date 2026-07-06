<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::withCount('products')->orderBy('name')->get();
        return view('admin.categories.index', compact('categories'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100|unique:categories,name',
            'icon' => 'nullable|string|max:50',
        ]);
        $data['slug'] = Str::slug($data['name']);
        Category::create($data);
        return back()->with('success', 'Đã thêm danh mục!');
    }

    public function update(Request $request, Category $category)
    {
        $data = $request->validate([
            'name' => 'required|string|max:100|unique:categories,name,'.$category->id,
            'icon' => 'nullable|string|max:50',
        ]);
        $data['slug'] = Str::slug($data['name']);
        $category->update($data);
        return back()->with('success', 'Đã cập nhật danh mục!');
    }

    public function destroy(Category $category)
    {
        $category->delete();
        return back()->with('success', 'Đã xoá danh mục!');
    }
}
