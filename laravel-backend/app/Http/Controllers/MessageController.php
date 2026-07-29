<?php

namespace App\Http\Controllers;

use App\Models\Message;
use App\Models\Employee;
use Illuminate\Http\Request;
use App\Services\Notifications\FirebaseCloudMessagingService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class MessageController extends Controller
{
    public function index(Request $request)
    {
        $messages = Message::with(['sender:id,name', 'employee:id,name'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        $employees = Employee::orderBy('name')->get(['id', 'name', 'jabatan']);

        return view('admin.messages.index', compact('messages', 'employees'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'employee_id' => 'nullable|exists:employees,id',
            'content'     => 'nullable|string|max:2000',
            'attachment'  => 'nullable|file|max:10240',
            'image'       => 'nullable|image|max:10240',
        ]);

        // Pakai nilai yang valid di constraint database: text, image, atau file.
        // Jika ada gambar + file, type tetap image; file tetap disimpan lewat file_path.
        $type = 'text';
        if ($request->hasFile('image')) {
            $type = 'image';
        } elseif ($request->hasFile('attachment')) {
            $type = 'file';
        }

        $data = [
            'sender_id'   => auth()->id(),
            'employee_id' => $request->employee_id,
            'type'        => $type,
            'content'     => $request->content,
        ];

        // Handle upload file biasa
        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $data['file_path'] = $file->store('messages', 'public');
            $data['file_name'] = $file->getClientOriginalName();
        }

        // Handle upload foto
        if ($request->hasFile('image')) {
            $image = $request->file('image');
            $data['image_path'] = $image->store('messages/images', 'public');
            $data['image_name'] = $image->getClientOriginalName();
        }

        $message = Message::create($data);

        app(FirebaseCloudMessagingService::class)->sendMessageNotification($message);

        return redirect()->route('admin.messages.index')
            ->with('success', 'Pesan berhasil dikirim!');
    }
    public function destroy(int $id)
    {
        $message = Message::find($id);

        if (!$message) {
            return redirect()->route('admin.messages.index')
                ->with('success', 'Pesan sudah tidak tersedia.');
        }

        DB::transaction(function () use ($message) {
            DB::table('message_reads')->where('message_id', $message->id)->delete();

            $filePath = $message->file_path;
            $imagePath = $message->image_path;

            $message->delete();

            foreach ([$filePath, $imagePath] as $path) {
                if ($path) {
                    Storage::disk('public')->delete($path);
                }
            }
        });

        return redirect()->route('admin.messages.index')
            ->with('success', 'Pesan berhasil dihapus.');
    }
}
