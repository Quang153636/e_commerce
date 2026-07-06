<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('label')->nullable(); // Nhãn: "Nhà", "Văn phòng", etc.
            $table->string('recipient_name'); // Tên người nhận
            $table->string('phone'); // Số điện thoại
            $table->text('address'); // Địa chỉ đầy đủ
            $table->text('address_detail')->nullable(); // Chi tiết địa chỉ (số nhà, tầng, etc.)
            $table->boolean('is_default')->default(false); // Địa chỉ mặc định
            $table->timestamps();

            $table->index(['user_id', 'is_default']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('addresses');
    }
};