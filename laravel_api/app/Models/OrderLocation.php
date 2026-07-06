<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderLocation extends Model
{
    protected $fillable = ['order_id', 'lat', 'lng', 'shipper_name', 'shipper_phone'];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
