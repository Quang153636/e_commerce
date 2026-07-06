<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('cart_items', 'variant_id')) {
            // Bỏ foreign key cũ, unique key, thêm variant_id, thêm lại foreign key
            DB::statement('ALTER TABLE cart_items DROP FOREIGN KEY cart_items_user_id_foreign');
            DB::statement('ALTER TABLE cart_items DROP FOREIGN KEY cart_items_product_id_foreign');
            DB::statement('ALTER TABLE cart_items DROP INDEX cart_items_user_id_product_id_unique');
            DB::statement('ALTER TABLE cart_items ADD COLUMN variant_id BIGINT UNSIGNED NULL AFTER product_id, ADD CONSTRAINT cart_items_variant_id_foreign FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE');
            DB::statement('ALTER TABLE cart_items ADD CONSTRAINT cart_items_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE');
            DB::statement('ALTER TABLE cart_items ADD CONSTRAINT cart_items_product_id_foreign FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE');
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('cart_items', 'variant_id')) {
            DB::statement('ALTER TABLE cart_items DROP FOREIGN KEY cart_items_variant_id_foreign');
            DB::statement('ALTER TABLE cart_items DROP COLUMN variant_id');
        }
        try {
            DB::statement('ALTER TABLE cart_items ADD UNIQUE INDEX cart_items_user_id_product_id_unique (user_id, product_id)');
        } catch (\Exception $e) {
            // bỏ qua
        }
    }
};