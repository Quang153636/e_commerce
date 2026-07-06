<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id', 'name', 'slug', 'description', 'price',
        'sale_price', 'stock', 'images', 'rating', 'is_active',
    ];

    protected $casts = [
        'images' => 'array',
        'is_active' => 'boolean',
        'price' => 'float',
        'sale_price' => 'float',
        'rating' => 'float',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function favoritedBy()
    {
        return $this->hasMany(Favorite::class);
    }

    public function variantTypes()
    {
        return $this->hasMany(ProductVariantType::class);
    }

    public function variants()
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    /**
     * Đồng bộ tồn kho: tính tổng stock từ tất cả variants và cập nhật vào cột stock của sản phẩm.
     * Nếu sản phẩm không có variants, giữ nguyên stock hiện tại.
     */
    public function syncStock(): void
    {
        if ($this->variants()->count() > 0) {
            $totalStock = $this->variants()->sum('stock');
            $this->update(['stock' => $totalStock]);
        }
    }
}