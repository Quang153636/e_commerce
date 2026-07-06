<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('customer_lat', 10, 7)->nullable()->after('shipping_phone');
            $table->decimal('customer_lng', 10, 7)->nullable()->after('customer_lat');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['customer_lat', 'customer_lng']);
        });
    }
};