<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class FaceRecognitionController extends Controller
{
    private function pythonUrl(): string
    {
        return rtrim(config('services.face_recognition.url'), '/');
    }

    public function registerFace(Request $request)
    {
        $request->validate([
            'image_base64' => 'required|string',
        ]);

        $employee = $request->user();
        $response = Http::timeout(60)->post("{$this->pythonUrl()}/extract-embedding", [
            'image_base64' => $request->image_base64,
        ]);

        if (!$response['success']) {
            return response()->json(['success' => false, 'message' => $response['message']], 400);
        }

        $employee->face_embedding = json_encode($response['embedding']);
        $employee->save();

        return response()->json(['success' => true, 'message' => 'Wajah berhasil didaftarkan']);
    }

    public function registerFaceMultiple(Request $request)
    {
        $request->validate([
            'images_base64' => 'required|array|min:3',
        ]);

        $employee = $request->user();
        $response = Http::timeout(60)->post("{$this->pythonUrl()}/register-multiple", [
            'images_base64' => $request->images_base64,
        ]);

        if (!$response['success']) {
            return response()->json(['success' => false, 'message' => $response['message']], 400);
        }

        $employee->face_embedding = json_encode($response['embedding']);
        $employee->save();

        return response()->json(['success' => true, 'message' => 'Wajah berhasil didaftarkan dengan 3 foto!']);
    }

    public function verifyFace(Request $request)
    {
        $request->validate([
            'image_base64' => 'required|string',
        ]);

        $employee = $request->user();
        if (!$employee || !$employee->face_embedding) {
            return response()->json([
                'success' => false,
                'match' => false,
                'message' => 'Wajah belum didaftarkan',
            ], 404);
        }

        $response = Http::timeout(60)->post("{$this->pythonUrl()}/verify-face", [
            'current_image_base64' => $request->image_base64,
            'stored_embedding' => json_decode($employee->face_embedding, true),
        ]);

        return response()->json($response->json());
    }

    public function checkFace(Request $request)
    {
        $registered = !empty($request->user()->face_embedding);
        return response()->json(['registered' => $registered]);
    }
}
