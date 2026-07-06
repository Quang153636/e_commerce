<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatusHistory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    // ===== Cấu hình tài khoản ngân hàng =====
    // Thay thông tin tài khoản của bạn vào đây
    private const BANK_ID      = 'MB';            // MB Bank = MB (hoặc 970422)
    private const ACCOUNT_NO   = '0376786416';    // Số tài khoản MB Bank
    private const ACCOUNT_NAME = 'HOANG QUOC VIET QUANG';

    // Casso webhook secret (lấy từ dashboard casso.vn sau khi đăng ký)
    // Webhook V2: dùng X-Secret-Key header
    // Đang ở chế độ DEV - bypass token check. Đặt 'DISABLED' để bỏ qua kiểm tra.
    // Khi lên PRODUCTION, set CASSO_SECRET = token thật từ Casso
    private const CASSO_SECRET = 'DISABLED';

    // =========================================

    /**
     * GET /api/payment/{order}/qr
     * Trả về URL ảnh QR và thông tin thanh toán
     */
    public function generateQR(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);

        if ($order->payment_status === 'paid') {
            return response()->json([
                'paid'    => true,
                'message' => 'Đơn hàng đã được thanh toán',
            ]);
        }

        // Nội dung chuyển khoản = mã đơn hàng (server dùng để đối soát)
        $description = strtoupper(str_replace('-', '', $order->code));
        $amount      = (int) $order->total;

        // Tạo URL QR theo chuẩn VietQR (hoàn toàn miễn phí, không cần API key)
        $qrUrl = sprintf(
            'https://img.vietqr.io/image/%s-%s-compact2.png?amount=%d&addInfo=%s&accountName=%s',
            self::BANK_ID,
            self::ACCOUNT_NO,
            $amount,
            urlencode($description),
            urlencode(self::ACCOUNT_NAME)
        );

        return response()->json([
            'paid'         => false,
            'qr_url'       => $qrUrl,
            'bank_id'      => self::BANK_ID,
            'account_no'   => self::ACCOUNT_NO,
            'account_name' => self::ACCOUNT_NAME,
            'amount'       => $amount,
            'description'  => $description,
            'order_code'   => $order->code,
        ]);
    }

    /**
     * GET /api/payment/{order}/status
     * Flutter gọi mỗi 3 giây để kiểm tra đã thanh toán chưa
     */
    public function checkStatus(Request $request, Order $order)
    {
        abort_if($order->user_id !== $request->user()->id, 403);

        return response()->json([
            'paid'              => $order->payment_status === 'paid',
            'payment_status'    => $order->payment_status,
            'order_status'      => $order->status,
            'paid_at'           => $order->paid_at?->format('d/m/Y H:i:s'),
            'transaction_id'    => $order->payment_transaction_id,
        ]);
    }

    /**
     * POST /api/payment/webhook/casso
     * Casso/SePay gọi endpoint này khi phát hiện giao dịch ngân hàng mới
     *
     * Để dùng:
     * 1. Đăng ký tại casso.vn (miễn phí)
     * 2. Kết nối tài khoản VietinBank
     * 3. Điền URL webhook: https://yourdomain.com/api/payment/webhook/casso
     * 4. Copy Secure Token vào CASSO_SECRET ở trên
     */
    public function webhookCasso(Request $request)
    {
        Log::info('[Casso Webhook] Nhận webhook', $request->all());

        // Xác thực request từ Casso
        // Webhook V2: header là X-Secret-Key
        // Webhook V1: header là Secure-Token hoặc x-secure-token
        // Nếu CASSO_SECRET = 'DISABLED' thì bỏ qua kiểm tra (chế độ dev)
        if (self::CASSO_SECRET !== 'DISABLED') {
            $token = $request->header('X-Secret-Key') 
                  ?? $request->header('Secure-Token') 
                  ?? $request->header('x-secure-token');
            
            if ($token !== self::CASSO_SECRET) {
                Log::warning('[Casso Webhook] Token không hợp lệ', [
                    'received' => $token,
                    'expected' => '(hidden)'
                ]);
                return response()->json(['error' => 'Unauthorized'], 401);
            }
        }

        // Casso gửi một object "data" chứa thông tin giao dịch
        $data = $request->input('data');
        if (empty($data)) {
            return response()->json(['success' => true]);
        }

        // Nếu data là mảng có key số (nhiều giao dịch)
        if (isset($data[0]) && is_array($data[0])) {
            foreach ($data as $txn) {
                $this->processTransaction($txn);
            }
        } else {
            // Nếu data là object đơn (casso test)
            $this->processTransaction($data);
        }

        return response()->json(['success' => true]);
    }

    /**
     * POST /api/payment/webhook/sepay
     * SePay webhook (cấu trúc khác Casso một chút)
     * Đăng ký tại: sepay.vn
     */
    public function webhookSepay(Request $request)
    {
        Log::info('[SePay Webhook] Nhận webhook', $request->all());

        // SePay gửi từng giao dịch một
        $txn = [
            'description' => $request->input('transferContent') ?? $request->input('content'),
            'amount'      => $request->input('transferAmount') ?? $request->input('amount'),
            'tid'         => $request->input('referenceCode') ?? $request->input('id'),
            'when'        => $request->input('transferDate') ?? now()->toDateTimeString(),
            'type'        => $request->input('transferType') === 'in' ? 'in' : 'in',
        ];

        $this->processTransaction($txn);

        return response()->json(['success' => true]);
    }

    /**
     * POST /api/payment/{order}/manual-confirm  (chỉ dùng khi test / không có webhook)
     * Admin xác nhận thanh toán thủ công
     */
    public function manualConfirm(Request $request, Order $order)
    {
        // Chỉ admin mới được dùng endpoint này
        abort_unless($request->user()->is_admin, 403);

        $this->markOrderAsPaid($order, 'MANUAL-' . time(), 'Xác nhận thủ công bởi admin');

        return response()->json([
            'success' => true,
            'message' => 'Đã xác nhận thanh toán thành công',
        ]);
    }

    // =========================================
    // Private helpers
    // =========================================

    private function processTransaction(array $txn): void
    {
        // Chỉ xử lý giao dịch tiền vào (credit)
        $type   = $txn['type'] ?? $txn['transaction_type'] ?? 'in';
        $amount = (int) ($txn['amount'] ?? 0);
        $desc   = strtoupper($txn['description'] ?? $txn['memo'] ?? '');
        $tid    = $txn['tid'] ?? $txn['reference'] ?? uniqid();

        if ($type !== 'in' || $amount <= 0) {
            return;
        }

        Log::info('[Payment] Xử lý giao dịch', ['amount' => $amount, 'desc' => $desc, 'tid' => $tid]);

        // Tìm đơn hàng theo nội dung chuyển khoản
        // Nội dung chuyển khoản phải chứa mã đơn (vd: ORD1A2B3C4D)
        $orders = Order::where('payment_status', 'unpaid')
            ->whereIn('status', ['pending', 'confirmed'])
            ->get();

        foreach ($orders as $order) {
            $expectedDesc = strtoupper(str_replace('-', '', $order->code));

            // Kiểm tra nội dung CK có chứa mã đơn không
            if (str_contains($desc, $expectedDesc)) {
                // Kiểm tra số tiền (cho phép sai lệch ±1000đ do phí)
                if (abs($amount - (int)$order->total) <= 1000) {
                    Log::info('[Payment] ✅ Khớp đơn hàng', ['order' => $order->code, 'amount' => $amount]);
                    $this->markOrderAsPaid($order, $tid, 'Nhận qua chuyển khoản');
                } else {
                    Log::warning('[Payment] ⚠️ Khớp mã nhưng sai số tiền', [
                        'order'    => $order->code,
                        'expected' => $order->total,
                        'received' => $amount,
                    ]);
                }
                break;
            }
        }
    }

    private function markOrderAsPaid(Order $order, string $transactionId, string $note): void
    {
        $order->update([
            'payment_status'         => 'paid',
            'payment_transaction_id' => $transactionId,
            'paid_at'                => now(),
            'status'                 => $order->status === 'pending' ? 'confirmed' : $order->status,
        ]);

        OrderStatusHistory::create([
            'order_id'   => $order->id,
            'status'     => $order->status,
            'note'       => "💰 Thanh toán thành công. $note. Mã GD: $transactionId",
            'created_at' => now(),
        ]);

        Log::info('[Payment] ✅ Đã cập nhật thanh toán', ['order' => $order->code]);
    }
}
