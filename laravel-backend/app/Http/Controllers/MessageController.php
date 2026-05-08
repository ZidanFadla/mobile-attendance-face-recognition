<?php

namespace App\Http\Controllers;

use App\Models\Message;
use App\Models\Employee;
use Illuminate\Http\Request;
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

        // Tentukan type otomatis
        $type = 'text';
        if ($request->hasFile('image') && $request->hasFile('attachment')) {
            $type = 'mixed';
        } elseif ($request->hasFile('image')) {
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

        Message::create($data);

        return redirect()->route('admin.messages.index')
            ->with('success', 'Pesan berhasil dikirim!');
    }
    public function destroy(Message $message)
    {
        if ($message->file_path) {
            Storage::disk('public')->delete($message->file_path);
        }
        if ($message->image_path) {
            Storage::disk('public')->delete($message->image_path);
        }
        $message->delete();

        return redirect()->back()->with('success', 'Pesan berhasil dihapus.');
    }
}
