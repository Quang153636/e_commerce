<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class AdminMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!Auth::check() || !Auth::user()->is_admin) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Không có quyền truy cập'], 403);
            }
            return redirect()->route('admin.login')->with('error', 'Vui lòng đăng nhập với tài khoản admin');
        }

        return $next($request);
    }
}
