<?php

use App\Http\Controllers\Api\AddressController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CartController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ProductController;
use Illuminate\Support\Facades\Route;

// ===== Auth =====
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// ===== Public (không cần đăng nhập) =====
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{product}', [ProductController::class, 'show']);

// Shipper / hệ thống giao hàng gửi vị trí (có thể bảo vệ riêng bằng API key trong thực tế)
Route::post('/orders/{order}/location', [OrderController::class, 'updateLocation']);

// VietinBank Webhook (giả lập) - endpoint public giống như webhook thật từ ngân hàng
Route::post('/vietinbank/webhook', [OrderController::class, 'vietinbankWebhook']);

// ===== Webhook Casso/SePay (public - không cần auth) =====
Route::post('/payment/webhook/casso', [PaymentController::class, 'webhookCasso']);
Route::post('/payment/webhook/sepay', [PaymentController::class, 'webhookSepay']);

// ===== Cần đăng nhập (Sanctum token) =====
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me', [AuthController::class, 'updateProfile']);

    // Yêu thích
    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites', [FavoriteController::class, 'store']);
    Route::delete('/favorites/{product}', [FavoriteController::class, 'destroy']);

    // Giỏ hàng
    Route::get('/cart', [CartController::class, 'index']);
    Route::post('/cart', [CartController::class, 'store']);
    Route::put('/cart/{cartItem}', [CartController::class, 'update']);
    Route::delete('/cart/{cartItem}', [CartController::class, 'destroy']);
    Route::delete('/cart', [CartController::class, 'clear']);

    // Đặt hàng / Mua hàng / Theo dõi đơn hàng
    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders/{order}', [OrderController::class, 'show']);
    Route::put('/orders/{order}/status', [OrderController::class, 'updateStatus']);
    Route::post('/orders/{order}/confirm-received', [OrderController::class, 'confirmReceived']);
    Route::post('/orders/{order}/confirm-vietinbank-payment', [OrderController::class, 'confirmVietinbankPayment']);
    Route::post('/orders/{order}/cancel', [OrderController::class, 'cancel']);
    Route::get('/orders/{order}/track', [OrderController::class, 'track']);
    Route::post('/orders/{order}/reviews', [OrderController::class, 'storeReview']);
    Route::get('/orders/{order}/reviews', [OrderController::class, 'getOrderReviews']);

    // Quản lý địa chỉ giao hàng
    Route::get('/addresses', [AddressController::class, 'index']);
    Route::get('/addresses/default', [AddressController::class, 'default']);
    Route::post('/addresses', [AddressController::class, 'store']);
    Route::get('/addresses/{address}', [AddressController::class, 'show']);
    Route::put('/addresses/{address}', [AddressController::class, 'update']);
    Route::delete('/addresses/{address}', [AddressController::class, 'destroy']);

    // Payment QR
    Route::get('/payment/{order}/qr', [PaymentController::class, 'generateQR']);
    Route::get('/payment/{order}/status', [PaymentController::class, 'checkStatus']);
    Route::post('/payment/{order}/manual-confirm', [PaymentController::class, 'manualConfirm']);
});

// ===== Admin routes (yêu cầu đăng nhập + quyền admin) =====
Route::middleware(['auth:sanctum', \App\Http\Middleware\AdminApiMiddleware::class])->prefix('admin')->group(function () {
    Route::get('/stats', [\App\Http\Controllers\Api\AdminApiController::class, 'stats']);
    Route::get('/orders', [\App\Http\Controllers\Api\AdminApiController::class, 'orders']);
    Route::get('/orders/{order}', [\App\Http\Controllers\Api\AdminApiController::class, 'orderDetail']);
    Route::post('/orders/{order}/status', [\App\Http\Controllers\Api\AdminApiController::class, 'updateOrderStatus']);
    Route::post('/orders/{order}/location', [\App\Http\Controllers\Api\AdminApiController::class, 'updateOrderLocation']);
    Route::get('/products', [\App\Http\Controllers\Api\AdminApiController::class, 'products']);
    Route::post('/products', [\App\Http\Controllers\Api\AdminApiController::class, 'createProduct']);
    Route::put('/products/{product}', [\App\Http\Controllers\Api\AdminApiController::class, 'updateProduct']);
    Route::delete('/products/{product}', [\App\Http\Controllers\Api\AdminApiController::class, 'deleteProduct']);
    Route::get('/stats/products', [\App\Http\Controllers\Api\AdminApiController::class, 'productStats']);
    Route::get('/stats/products/{productId}', [\App\Http\Controllers\Api\AdminApiController::class, 'productStats']);
    Route::get('/categories', [\App\Http\Controllers\Api\AdminApiController::class, 'categories']);
    Route::post('/categories', [\App\Http\Controllers\Api\AdminApiController::class, 'createCategory']);
    Route::put('/categories/{category}', [\App\Http\Controllers\Api\AdminApiController::class, 'updateCategory']);
    Route::delete('/categories/{category}', [\App\Http\Controllers\Api\AdminApiController::class, 'deleteCategory']);
    Route::get('/users', [\App\Http\Controllers\Api\AdminApiController::class, 'users']);
    Route::post('/users/{user}/toggle-admin', [\App\Http\Controllers\Api\AdminApiController::class, 'toggleAdmin']);
    Route::delete('/users/{user}', [\App\Http\Controllers\Api\AdminApiController::class, 'deleteUser']);
});
