<?php

namespace App\Http\Controllers;

use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MessageApiController extends Controller
{
    /**
     * Ambil pesan untuk karyawan (polling setiap 10 detik)
     * Mengembalikan pesan yang ditujukan ke karyawan ini + broadcast (employee_id = null)
     */
    public function index(Request $request)
    {
        $employee = $request->user();

        $readMessageIds = DB::table('message_reads')
            ->where('employee_id', $employee->id)
            ->pluck('message_id')
            ->all();

        $messages = Message::with('sender:id,name')
            ->where(function ($q) use ($employee) {
                $q->where('employee_id', $employee->id)
                  ->orWhereNull('employee_id'); // broadcast
            })
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get()
            ->map(function ($msg) use ($readMessageIds) {
                return [
                    'id'         => $msg->id,
                    'sender'     => $msg->sender->name ?? 'Admin',
                    'type'       => $msg->type,
                    'content'    => $msg->content,
                    'image_url'   => $msg->image_path ? asset('storage/' . $msg->image_path) : null,
                    'image_name'  => $msg->image_name,
                    'file_url'   => $msg->file_path ? asset('storage/' . $msg->file_path) : null,
                    'file_name'  => $msg->file_name,
                    'is_read'    => in_array($msg->id, $readMessageIds),
                    'created_at' => $msg->created_at->format('Y-m-d H:i:s'),
                    'time_ago'   => $msg->created_at->diffForHumans(),
                ];
            });

        $messageIds = $messages->pluck('id')->all();

        return response()->json([
            'success' => true,
            'data'    => $messages,
            'unread'  => count(array_diff($messageIds, $readMessageIds)),
        ]);
    }

    /**
     * Tandai pesan sebagai sudah dibaca
     */
    public function markRead(Request $request)
    {
        $employee = $request->user();

        $messageIds = Message::where(function ($q) use ($employee) {
            $q->where('employee_id', $employee->id)
              ->orWhereNull('employee_id');
        })->pluck('id');

        foreach ($messageIds as $messageId) {
            DB::table('message_reads')->updateOrInsert(
                [
                    'message_id' => $messageId,
                    'employee_id' => $employee->id,
                ],
                ['read_at' => now()]
            );
        }

        return response()->json(['success' => true]);
    }

    /**
     * Tandai satu pesan sebagai sudah dibaca oleh karyawan login.
     */
    public function markOneRead(Request $request, Message $message)
    {
        $employee = $request->user();

        abort_unless(
            $message->employee_id === null || $message->employee_id === $employee->id,
            403
        );

        DB::table('message_reads')->updateOrInsert(
            [
                'message_id' => $message->id,
                'employee_id' => $employee->id,
            ],
            ['read_at' => now()]
        );

        return response()->json(['success' => true]);
    }
}
