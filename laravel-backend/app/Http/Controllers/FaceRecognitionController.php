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

    /**
     * Register face — menerima format dari Flutter:
     * { "images": ["base64_1", "base64_2", "base64_3"] }
     */
    public function registerFace(Request $request)
    {
        $request->validate([
            'images' => 'required|array|min:1',
            'images.*' => 'required|string',
        ]);

        $employee = $request->user();

        // Forward ke Python server
        try {
            $response = Http::timeout(60)
                ->withHeaders(['ngrok-skip-browser-warning' => 'true'])
                ->post("{$this->pythonUrl()}/face/register", [
                    'images' => $request->images,
                ]);

            if ($response->failed()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Python Server Error: ' . $response->status() . ' - ' . substr($response->body(), 0, 150),
                ], 400);
            }

            $result = $response->json();
            if (!$result) {
                return response()->json([
                    'success' => false,
                    'message' => 'Python Server returned empty/invalid response: ' . substr($response->body(), 0, 150),
                ], 400);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal terhubung ke Python Server: ' . $e->getMessage(),
            ], 500);
        }

        if (!($result['success'] ?? false)) {
            return response()->json([
                'success' => false,
                'message' => $result['message'] ?? 'Gagal mendaftarkan wajah',
            ], 400);
        }

        // Simpan embedding ke database
        $embeddings = $result['data']['embeddings'] ?? $result['embedding'] ?? null;
        if ($embeddings) {
            $employee->face_embedding = json_encode($embeddings);
            $employee->save();
        }

        return response()->json([
            'success' => true,
            'message' => $result['message'] ?? 'Wajah berhasil didaftarkan',
        ]);
    }

    /**
     * Register face multiple (backward compatibility)
     * { "images_base64": ["base64_1", "base64_2", "base64_3"] }
     */
    public function registerFaceMultiple(Request $request)
    {
        $request->validate([
            'images_base64' => 'required|array|min:3',
        ]);

        $employee = $request->user();
        try {
            $response = Http::timeout(60)
                ->withHeaders(['ngrok-skip-browser-warning' => 'true'])
                ->post("{$this->pythonUrl()}/face/register", [
                    'images' => $request->images_base64,
                ]);

            if ($response->failed()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Python Server Error: ' . $response->status() . ' - ' . substr($response->body(), 0, 150),
                ], 400);
            }

            $result = $response->json();
            if (!$result) {
                return response()->json([
                    'success' => false,
                    'message' => 'Python Server returned empty/invalid response: ' . substr($response->body(), 0, 150),
                ], 400);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal terhubung ke Python Server: ' . $e->getMessage(),
            ], 500);
        }

        if (!($result['success'] ?? false)) {
            return response()->json([
                'success' => false,
                'message' => $result['message'] ?? 'Gagal mendaftarkan wajah',
            ], 400);
        }

        $embeddings = $result['data']['embeddings'] ?? $result['embedding'] ?? null;
        if ($embeddings) {
            $employee->face_embedding = json_encode($embeddings);
            $employee->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Wajah berhasil didaftarkan dengan 3 foto!',
        ]);
    }

    /**
     * Verify face — menerima format dari Flutter:
     * { "image": "base64_image", "type": "image" }
     */
    public function verifyFace(Request $request)
    {
        // Terima 'image' (Flutter) atau 'image_base64' (legacy)
        $imageBase64 = $request->image ?? $request->image_base64;

        if (!$imageBase64) {
            return response()->json([
                'success' => false,
                'match' => false,
                'message' => 'Field image diperlukan',
            ], 400);
        }

        $employee = $request->user();
        if (!$employee || !$employee->face_embedding) {
            return response()->json([
                'success' => false,
                'match' => false,
                'message' => 'Wajah belum didaftarkan',
            ], 404);
        }

        $storedEmbeddings = json_decode($employee->face_embedding, true);

        try {
            $response = Http::timeout(60)
                ->withHeaders(['ngrok-skip-browser-warning' => 'true'])
                ->post("{$this->pythonUrl()}/face/verify", [
                    'image' => $imageBase64,
                    'type' => $request->type ?? 'image',
                    'stored_embeddings' => $storedEmbeddings,
                ]);

            if ($response->failed()) {
                return response()->json([
                    'success' => false,
                    'match' => false,
                    'message' => 'Python Server Error: ' . $response->status() . ' - ' . substr($response->body(), 0, 150),
                ], 400);
            }

            $result = $response->json();
            if (!$result) {
                return response()->json([
                    'success' => false,
                    'match' => false,
                    'message' => 'Python Server returned empty/invalid response: ' . substr($response->body(), 0, 150),
                ], 400);
            }

            return response()->json($result);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'match' => false,
                'message' => 'Gagal terhubung ke Python Server: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function checkFace(Request $request)
    {
        $registered = !empty($request->user()->face_embedding);
        return response()->json(['registered' => $registered]);
    }
}
