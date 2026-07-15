<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;

class FaceRecognitionController extends Controller
{
    /**
     * Register face — menerima embeddings dari Flutter (on-device MobileFaceNet).
     *
     * Request:
     *   { "embeddings": [[...192 floats...], [...], [...]] }
     *
     * Embeddings sudah di-extract on-device oleh MobileFaceNet TFLite.
     * Server hanya menyimpan — tidak perlu Python server lagi.
     */
    public function registerFace(Request $request)
    {
        $request->validate([
            'embeddings' => 'required|array|min:1',
            'embeddings.*' => 'required|array',
        ]);

        $employee = $request->user();

        // Simpan embeddings langsung ke database
        $employee->face_embedding = json_encode($request->embeddings);
        $employee->save();

        return response()->json([
            'success' => true,
            'message' => 'Wajah berhasil didaftarkan',
        ]);
    }

    /**
     * Get stored embeddings — Flutter mengambil embeddings untuk di-cache di HP.
     * Digunakan untuk offline face matching.
     */
    public function getEmbeddings(Request $request)
    {
        $employee = $request->user();

        if (!$employee || !$employee->face_embedding) {
            return response()->json([
                'embeddings' => null,
            ]);
        }

        return response()->json([
            'embeddings' => json_decode($employee->face_embedding, true),
        ]);
    }

    /**
     * Check apakah user sudah register face.
     */
    public function checkFace(Request $request)
    {
        $registered = !empty($request->user()->face_embedding);
        return response()->json(['registered' => $registered]);
    }
}
