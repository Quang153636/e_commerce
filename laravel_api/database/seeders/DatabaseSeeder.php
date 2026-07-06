<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::firstOrCreate(
            ['email' => 'demo@shop.test'],
            [
                'name' => 'Khách demo',
                'phone' => '0900000000',
                'address' => '123 Đường ABC, Quận 1, TP.HCM',
                'password' => Hash::make('password'),
            ]
        );

        $categories = [
            ['name' => 'Điện thoại', 'icon' => 'phone'],
            ['name' => 'Thời trang', 'icon' => 'shirt'],
            ['name' => 'Đồ gia dụng', 'icon' => 'home'],
            ['name' => 'Sách', 'icon' => 'book'],
            ['name' => 'Mỹ phẩm', 'icon' => 'spa'],
        ];

        foreach ($categories as $cat) {
            $category = Category::firstOrCreate(
                ['slug' => Str::slug($cat['name'])],
                [
                    'name' => $cat['name'],
                    'icon' => $cat['icon'],
                ]
            );

            $existingProducts = Product::where('category_id', $category->id)->count();
            for ($i = $existingProducts + 1; $i <= 6; $i++) {
                $name = $cat['name'].' sản phẩm '.$i;
                Product::create([
                    'category_id' => $category->id,
                    'name' => $name,
                    'slug' => Str::slug($name).'-'.Str::random(5),
                    'description' => 'Mô tả chi tiết cho '.$name.'. Sản phẩm chất lượng cao, giá tốt.',
                    'price' => rand(100, 5000) * 1000,
                    'sale_price' => rand(0, 1) ? rand(80, 4500) * 1000 : null,
                    'stock' => rand(10, 100),
                    'images' => [
                        'https://picsum.photos/seed/'.Str::slug($name).'1/600/600',
                        'https://picsum.photos/seed/'.Str::slug($name).'2/600/600',
                    ],
                    'rating' => round(rand(30, 50) / 10, 1),
                    'is_active' => true,
                ]);
            }
        }

        $this->call(AdminSeeder::class);

        $this->command->info('Tài khoản demo: demo@shop.test / password');
        $this->command->info('Tài khoản admin: admin@shop.test / admin123');
    }
}