<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    public const STATUSES = [
        'pending',    // đã đặt hàng
        'confirmed',  // đã xác nhận
        'shipping',   // đang giao
        'delivered',  // đã giao hàng
        'received',   // đã nhận hàng
        'cancelled',  // đã huỷ
    ];

    protected $fillable = [
        'code', 'user_id', 'total', 'shipping_address', 'shipping_phone',
        'payment_method', 'payment_status', 'status', 'customer_lat', 'customer_lng',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function statusHistories()
    {
        return $this->hasMany(OrderStatusHistory::class)->orderBy('created_at');
    }

    public function locations()
    {
        return $this->hasMany(OrderLocation::class)->orderByDesc('created_at');
    }

    public function latestLocation()
    {
        return $this->hasOne(OrderLocation::class)->latestOfMany();
    }
}
