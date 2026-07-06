<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete(); // Đánh giá cho đơn hàng nào
            $table->foreignId('order_item_id')->constrained()->cascadeOnDelete(); // Đánh giá cho sản phẩm nào trong đơn
            $table->tinyInteger('rating'); // Số sao 1-5
            $table->text('comment')->nullable(); // Bình luận đánh giá
            $table->timestamps();

            // Một user chỉ đánh giá 1 lần cho 1 order_item
            $table->unique(['user_id', 'order_item_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};