@extends('layouts.admin')
@section('title', 'Pesan')
@section('page-title', 'Pesan ke Karyawan')
@section('page-desc', 'Kirim pesan, foto, atau file ke karyawan')

@section('content')
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    {{-- Form Kirim Pesan --}}
    <div class="lg:col-span-1">
        <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-6 sticky top-24">
            <h3 class="text-base font-bold text-gray-900 mb-5">Kirim Pesan Baru</h3>

            <form method="POST" action="{{ route('admin.messages.store') }}" enctype="multipart/form-data" id="messageForm">
                @csrf
                <input type="hidden" name="type" value="mixed">
                <div class="space-y-4">
                    {{-- Penerima --}}
                    <div>
                        <label class="block text-xs font-semibold text-gray-500 mb-1.5">Penerima</label>
                        <select name="employee_id" class="input-field">
                            <option value="">🔊 Broadcast (Semua Karyawan)</option>
                            @foreach($employees as $emp)
                            <option value="{{ $emp->id }}">{{ $emp->name }} — {{ $emp->jabatan }}</option>
                            @endforeach
                        </select>
                    </div>

                    {{-- Tipe --}}
                    <div>
                        <label class="block text-xs font-semibold text-gray-500 mb-1.5">Pesan</label>
                        <textarea name="content" rows="4" class="input-field resize-none" placeholder="Tulis pesan disini...">{{ old('content') }}</textarea>
                    </div>

                    {{-- Upload Foto --}}
                    <div>
                        <label class="block text-xs font-semibold text-gray-500 mb-1.5">Foto <span class="font-normal text-gray-400">(opsional)</span></label>
                        <div class="border-2 border-dashed border-gray-200 rounded-2xl p-4 text-center hover:border-emerald-400 transition-colors cursor-pointer" onclick="document.getElementById('imageAttachment').click()">
                            <div id="imagePreview" class="hidden mb-2">
                                <img id="imagePreviewImg" src="" class="max-h-40 mx-auto rounded-xl object-contain" alt="Preview">
                            </div>
                            <div id="imageUploadPrompt">
                                <svg class="w-7 h-7 mx-auto text-gray-400 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                                </svg>
                                <p class="text-xs text-gray-500">Klik untuk upload foto</p>
                                <p class="text-xs text-gray-400 mt-0.5">JPG, PNG, GIF • Maks 10MB</p>
                            </div>
                        </div>
                        <input type="file" name="image" id="imageAttachment" class="hidden" accept="image/*"
                            onchange="previewImage(this)">
                        <p class="text-xs text-gray-400 mt-1" id="imageFileName"></p>
                    </div>

                    {{-- Upload File --}}
                    <div>
                        <label class="block text-xs font-semibold text-gray-500 mb-1.5">File <span class="font-normal text-gray-400">(opsional)</span></label>
                        <div class="border-2 border-dashed border-gray-200 rounded-2xl p-4 text-center hover:border-emerald-400 transition-colors cursor-pointer" onclick="document.getElementById('fileAttachment').click()">
                            <svg class="w-7 h-7 mx-auto text-gray-400 mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
                            </svg>
                            <p class="text-xs text-gray-500">Klik untuk upload file</p>
                            <p class="text-xs text-gray-400 mt-0.5">PDF, DOC, XLS, dll • Maks 10MB</p>
                        </div>
                        <input type="file" name="attachment" id="fileAttachment" class="hidden" accept="*/*"
                            onchange="document.getElementById('fileFileName').textContent = this.files[0]?.name ?? ''">
                        <p class="text-xs text-gray-400 mt-1" id="fileFileName"></p>
                    </div>

                    <button type="submit" class="btn-primary w-full flex items-center justify-center gap-2">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
                        </svg>
                        Kirim Pesan
                    </button>
                </div>
            </form>
        </div>
    </div>

    {{-- Daftar Pesan --}}
    <div class="lg:col-span-2">
        <div class="space-y-4">
            <h3 class="text-base font-bold text-gray-900">Riwayat Pesan</h3>

            @forelse($messages as $msg)
            <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-5 hover:shadow-md transition-shadow">
                <div class="flex items-start justify-between">
                    <div class="flex items-start gap-3 flex-1 min-w-0">
                        <div class="w-10 h-10 bg-gradient-to-br from-emerald-400 to-teal-500 rounded-xl flex items-center justify-center flex-shrink-0">
                            @if($msg->type === 'text')
                            <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"></path>
                                <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"></path>
                            </svg>
                            @elseif($msg->type === 'image' || $msg->type === 'mixed')
                            <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd" d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z" clip-rule="evenodd"></path>
                            </svg>
                            @else
                            <svg class="w-5 h-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                                <path fill-rule="evenodd" d="M8 4a3 3 0 00-3 3v4a5 5 0 0010 0V7a1 1 0 112 0v4a7 7 0 11-14 0V7a5 5 0 0110 0v4a3 3 0 11-6 0V7a1 1 0 012 0v4a1 1 0 102 0V7a3 3 0 00-3-3z" clip-rule="evenodd"></path>
                            </svg>
                            @endif
                        </div>
                        <div class="flex-1 min-w-0">
                            <div class="flex items-center gap-2 mb-1">
                                <span class="text-sm font-semibold text-gray-900">
                                    Ke: {{ $msg->employee ? $msg->employee->name : '🔊 Semua Karyawan' }}
                                </span>
                                <span class="inline-flex px-2 py-0.5 rounded-lg text-xs font-semibold
                                        {{ $msg->type === 'text' ? 'bg-blue-100 text-blue-700' : (in_array($msg->type, ['image', 'mixed']) ? 'bg-amber-100 text-amber-700' : 'bg-gray-100 text-gray-700') }}">
                                    {{ ucfirst($msg->type) }}
                                </span>
                                @if(!$msg->is_read)
                                <span class="w-2 h-2 bg-emerald-500 rounded-full"></span>
                                @endif
                            </div>
                            @if($msg->content)
                            <p class="text-sm text-gray-600 line-clamp-2">{{ $msg->content }}</p>
                            @endif
                            @if($msg->image_path)
                            <button type="button" onclick="openMessageDetail('message-detail-{{ $msg->id }}')" class="mt-3 block text-left">
                                <img src="{{ asset('storage/' . $msg->image_path) }}" alt="{{ $msg->image_name ?? 'Foto pesan' }}" class="h-28 w-44 rounded-xl object-cover border border-gray-100">
                            </button>
                            @endif
                            @if($msg->file_path)
                            <a href="{{ asset('storage/' . $msg->file_path) }}" target="_blank" class="inline-flex items-center gap-1 text-xs text-emerald-600 font-medium mt-1 hover:underline">
                                <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                    <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd"></path>
                                </svg>
                                {{ $msg->file_name }}
                            </a>
                            @endif
                            <div class="mt-3">
                                <button type="button" onclick="openMessageDetail('message-detail-{{ $msg->id }}')" class="inline-flex items-center gap-1 text-xs font-semibold text-gray-700 hover:text-emerald-600">
                                    Lihat detail
                                </button>
                            </div>
                            <p class="text-xs text-gray-400 mt-2">{{ $msg->created_at->diffForHumans() }} · {{ $msg->sender->name ?? 'Admin' }}</p>
                        </div>
                    </div>
                    <form method="POST" action="{{ route('admin.messages.destroy', $msg) }}" onsubmit="return confirm('Hapus pesan ini?')">
                        @csrf @method('DELETE')
                        <button type="submit" class="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                        </button>
                    </form>
                </div>
            </div>
            <div id="message-detail-{{ $msg->id }}" class="fixed inset-0 z-50 hidden items-center justify-center bg-gray-900/60 p-4">
                <div class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white shadow-2xl">
                    <div class="flex items-start justify-between border-b border-gray-100 px-6 py-4">
                        <div>
                            <h4 class="text-base font-bold text-gray-900">Detail Pesan</h4>
                            <p class="mt-1 text-xs text-gray-500">
                                Ke: {{ $msg->employee ? $msg->employee->name : 'Semua Karyawan' }} · {{ $msg->created_at->format('d M Y, H:i') }}
                            </p>
                        </div>
                        <button type="button" onclick="closeMessageDetail('message-detail-{{ $msg->id }}')" class="rounded-lg p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-700">
                            <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                            </svg>
                        </button>
                    </div>
                    <div class="space-y-5 px-6 py-5">
                        <div class="flex flex-wrap items-center gap-2 text-xs">
                            <span class="rounded-lg bg-gray-100 px-2.5 py-1 font-semibold text-gray-700">{{ ucfirst($msg->type) }}</span>
                            <span class="text-gray-500">Dikirim oleh {{ $msg->sender->name ?? 'Admin' }}</span>
                        </div>

                        @if($msg->content)
                        <div>
                            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">Isi Pesan</p>
                            <div class="whitespace-pre-line rounded-xl bg-gray-50 p-4 text-sm leading-6 text-gray-700">{{ $msg->content }}</div>
                        </div>
                        @endif

                        @if($msg->image_path)
                        <div>
                            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">Foto</p>
                            <a href="{{ asset('storage/' . $msg->image_path) }}" target="_blank" class="block">
                                <img src="{{ asset('storage/' . $msg->image_path) }}" alt="{{ $msg->image_name ?? 'Foto pesan' }}" class="max-h-[460px] w-full rounded-xl border border-gray-100 object-contain bg-gray-50">
                            </a>
                            <p class="mt-2 text-xs text-gray-500">{{ $msg->image_name }}</p>
                        </div>
                        @endif

                        @if($msg->file_path)
                        <div>
                            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">File</p>
                            <a href="{{ asset('storage/' . $msg->file_path) }}" target="_blank" class="flex items-center justify-between rounded-xl border border-gray-100 bg-gray-50 p-4 text-sm font-semibold text-emerald-700 hover:bg-emerald-50">
                                <span class="truncate">{{ $msg->file_name }}</span>
                                <span class="ml-3 text-xs">Buka</span>
                            </a>
                        </div>
                        @endif
                    </div>
                </div>
            </div>
            @empty
            <div class="bg-white rounded-2xl border border-gray-100 shadow-sm p-12 text-center">
                <svg class="w-16 h-16 mx-auto text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                </svg>
                <p class="text-gray-500 font-medium">Belum ada pesan</p>
                <p class="text-gray-400 text-sm mt-1">Kirim pesan pertama ke karyawan</p>
            </div>
            @endforelse

            @if($messages->hasPages())
            <div class="pt-2">{{ $messages->links() }}</div>
            @endif
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script>
    function openMessageDetail(id) {
        const modal = document.getElementById(id);
        if (!modal) return;
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }

    function closeMessageDetail(id) {
        const modal = document.getElementById(id);
        if (!modal) return;
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }

    // Toggle content/file input based on type
    document.querySelectorAll('input[name="type"]').forEach(radio => {
        radio.addEventListener('change', function() {
            const textInput = document.getElementById('textInput');
            const fileInput = document.getElementById('fileInput');
            if (this.value === 'text') {
                textInput.classList.remove('hidden');
                fileInput.classList.add('hidden');
            } else {
                textInput.classList.add('hidden');
                fileInput.classList.remove('hidden');
            }
        });
    });

    // Show file name
    document.getElementById('attachment')?.addEventListener('change', function() {
        const name = this.files[0]?.name || '';
        document.getElementById('fileName').textContent = name ? '📎 ' + name : '';
    });

    function previewImage(input) {
        const preview = document.getElementById('imagePreview');
        const previewImg = document.getElementById('imagePreviewImg');
        const prompt = document.getElementById('imageUploadPrompt');
        const fileName = document.getElementById('imageFileName');

        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = e => {
                previewImg.src = e.target.result;
                preview.classList.remove('hidden');
                prompt.classList.add('hidden');
            };
            reader.readAsDataURL(input.files[0]);
            fileName.textContent = input.files[0].name;
        }
    }
</script>
@endpush
