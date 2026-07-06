<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Lưu các loại biến thể của sản phẩm: 'ram', 'color', 'size', 'storage',...
        Schema::create('product_variant_types', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('name'); // Tên loại biến thể: 'RAM', 'Màu sắc', 'Kích cỡ',...
            $table->json('options'); // Các tùy chọn: ["256GB", "128GB"] hoặc ["Đỏ", "Xanh"]
            $table->timestamps();
        });

        // Lưu các biến thể cụ thể của sản phẩm với giá và tồn kho riêng
        Schema::create('product_variants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->json('attributes'); // {"RAM": "256GB", "Màu sắc": "Đỏ"}
            $table->double('price')->nullable(); // Giá riêng nếu khác với sản phẩm gốc
            $table->integer('stock')->default(0);
            $table->string('sku')->nullable(); // Mã SKU
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_variants');
        Schema::dropIfExists('product_variant_types');
    }
};