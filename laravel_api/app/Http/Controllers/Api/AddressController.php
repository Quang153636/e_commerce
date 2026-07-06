<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AddressController extends Controller
{
    // GET /api/addresses
    public function index(Request $request)
    {
        $addresses = Address::byUser($request->user()->id)
            ->orderByDesc('is_default')
            ->orderByDesc('created_at')
            ->get();

        return response()->json($addresses);
    }

    // GET /api/addresses/default
    public function default(Request $request)
    {
        $address = Address::byUser($request->user()->id)
            ->default()
            ->first();

        return response()->json($address);
    }

    // POST /api/addresses
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'label' => 'nullable|string|max:50',
            'recipient_name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'address' => 'required|string|max:500',
            'address_detail' => 'nullable|string|max:500',
            'is_default' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Dữ liệu không hợp lệ', 'errors' => $validator->errors()], 422);
        }

        $data = $validator->validated();
        $data['user_id'] = $request->user()->id;

        // Nếu đánh dấu là mặc định, bỏ mặc định của các địa chỉ khác
        if ($data['is_default'] ?? false) {
            Address::byUser($request->user()->id)
                ->where('is_default', true)
                ->update(['is_default' => false]);
        }

        // Nếu đây là địa chỉ đầu tiên, tự động đặt làm mặc định
        if (!Address::byUser($request->user()->id)->exists()) {
            $data['is_default'] = true;
        }

        $address = Address::create($data);

        return response()->json($address, 201);
    }

    // GET /api/addresses/{address}
    public function show(Request $request, Address $address)
    {
        if ($address->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Không có quyền truy cập'], 403);
        }

        return response()->json($address);
    }

    // PUT /api/addresses/{address}
    public function update(Request $request, Address $address)
    {
        if ($address->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Không có quyền truy cập'], 403);
        }

        $validator = Validator::make($request->all(), [
            'label' => 'nullable|string|max:50',
            'recipient_name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
            'address' => 'sometimes|string|max:500',
            'address_detail' => 'nullable|string|max:500',
            'is_default' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Dữ liệu không hợp lệ', 'errors' => $validator->errors()], 422);
        }

        $data = $validator->validated();

        // Nếu đánh dấu là mặc định, bỏ mặc định của các địa chỉ khác
        if ($data['is_default'] ?? false) {
            Address::byUser($request->user()->id)
                ->where('id', '!=', $address->id)
                ->where('is_default', true)
                ->update(['is_default' => false]);
        }

        $address->update($data);

        return response()->json($address);
    }

    // DELETE /api/addresses/{address}
    public function destroy(Request $request, Address $address)
    {
        if ($address->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Không có quyền truy cập'], 403);
        }

        $address->delete();

        return response()->json(['message' => 'Xóa địa chỉ thành công']);
    }
}