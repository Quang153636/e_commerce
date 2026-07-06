<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        User::firstOrCreate(
            ['email' => 'admin@shop.test'],
            [
                'name' => 'Quản trị viên',
                'phone' => '0912345678',
                'address' => 'Văn phòng công ty, Quận 1, TP.HCM',
                'password' => Hash::make('admin123'),
                'is_admin' => true,
            ]
        );
    }
}