<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'message' => 'Ecommerce API đang hoạt động. Xem các endpoint tại /api/*',
    ]);
});

// Admin web interface
Route::get('/admin', function () {
    return redirect('/admin/index.html');
});

Route::get('/admin/{any}', function ($any) {
    // Serve static files for admin subpaths
    // This allows SPA routing if needed
    $path = public_path("admin/$any");
    if (file_exists($path) && !is_dir($path)) {
        $extension = pathinfo($path, PATHINFO_EXTENSION);
        $mimeTypes = [
            'css' => 'text/css',
            'js' => 'application/javascript',
            'html' => 'text/html',
            'png' => 'image/png',
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'gif' => 'image/gif',
            'svg' => 'image/svg+xml',
            'ico' => 'image/x-icon',
            'woff' => 'font/woff',
            'woff2' => 'font/woff2',
        ];
        $mime = $mimeTypes[$extension] ?? 'application/octet-stream';
        return response()->file($path, ['Content-Type' => $mime]);
    }
    return redirect('/admin/index.html');
})->where('any', '.*');