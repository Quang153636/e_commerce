<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->decimal('total', 12, 2);
            $table->string('shipping_address');
            $table->string('shipping_phone');
            $table->string('payment_method')->default('cod'); // cod, momo, vnpay, card
            $table->string('payment_status')->default('unpaid'); // unpaid, paid
            // pending(đã đặt hàng) -> confirmed -> shipping -> delivered(đã giao hàng) -> received(đã nhận hàng) -> cancelled
            $table->string('status')->default('pending');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
