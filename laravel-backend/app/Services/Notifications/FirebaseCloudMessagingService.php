<?php

namespace App\Services\Notifications;

use App\Models\EmployeeDeviceToken;
use App\Models\Message;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use RuntimeException;

class FirebaseCloudMessagingService
{
    private const TOKEN_URI = 'https://oauth2.googleapis.com/token';
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    public function sendMessageNotification(Message $message): void
    {
        if (!Schema::hasTable('employee_device_tokens')) {
            Log::warning('FCM notification skipped: employee_device_tokens table belum ada. Jalankan php artisan migrate.');
            return;
        }

        $query = EmployeeDeviceToken::query();

        if ($message->employee_id !== null) {
            $query->where('employee_id', $message->employee_id);
        }

        $tokens = $query->pluck('token')->filter()->unique()->values();
        if ($tokens->isEmpty()) {
            return;
        }

        foreach ($tokens as $token) {
            $this->sendToToken($token, [
                'title' => 'Pesan baru dari admin',
                'body' => $this->notificationBody($message),
                'data' => [
                    'type' => 'admin_message',
                    'message_id' => (string) $message->id,
                ],
            ]);
        }
    }

    public function sendToToken(string $token, array $payload): void
    {
        try {
            $projectId = config('firebase.project_id');
            if (!$projectId) {
                throw new RuntimeException('FIREBASE_PROJECT_ID belum diatur.');
            }

            $response = Http::withToken($this->accessToken())
                ->acceptJson()
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                    'message' => [
                        'token' => $token,
                        'notification' => [
                            'title' => $payload['title'],
                            'body' => $payload['body'],
                        ],
                        'data' => $payload['data'] ?? [],
                        'android' => [
                            'priority' => 'HIGH',
                            'notification' => [
                                'channel_id' => 'admin_messages',
                                'sound' => 'default',
                            ],
                        ],
                    ],
                ]);

            if ($response->failed()) {
                Log::warning('FCM send failed', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
            }
        } catch (\Throwable $e) {
            Log::warning('FCM notification skipped: ' . $e->getMessage());
        }
    }

    private function notificationBody(Message $message): string
    {
        if ($message->content) {
            return str($message->content)->limit(120)->toString();
        }

        return match ($message->type) {
            'image' => 'Admin mengirim gambar.',
            'file' => 'Admin mengirim file.',
            'mixed' => 'Admin mengirim pesan dengan lampiran.',
            default => 'Ada pesan baru untuk kamu.',
        };
    }

    private function accessToken(): string
    {
        $credentials = $this->credentials();
        $now = time();

        $header = $this->base64UrlEncode(json_encode([
            'alg' => 'RS256',
            'typ' => 'JWT',
        ], JSON_THROW_ON_ERROR));

        $claim = $this->base64UrlEncode(json_encode([
            'iss' => $credentials['client_email'],
            'scope' => self::SCOPE,
            'aud' => self::TOKEN_URI,
            'iat' => $now,
            'exp' => $now + 3600,
        ], JSON_THROW_ON_ERROR));

        $signatureInput = $header . '.' . $claim;
        openssl_sign($signatureInput, $signature, $credentials['private_key'], 'sha256WithRSAEncryption');
        $jwt = $signatureInput . '.' . $this->base64UrlEncode($signature);

        $response = Http::asForm()->post(self::TOKEN_URI, [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        if ($response->failed()) {
            throw new RuntimeException('Gagal mengambil Firebase access token: ' . $response->body());
        }

        return $response->json('access_token');
    }

    private function credentials(): array
    {
        $json = config('firebase.credentials_json');
        if (!$json && config('firebase.credentials')) {
            $path = base_path(config('firebase.credentials'));
            if (is_file($path)) {
                $json = file_get_contents($path);
            }
        }

        if (!$json) {
            throw new RuntimeException('Firebase credentials belum diatur.');
        }

        $credentials = json_decode($json, true, 512, JSON_THROW_ON_ERROR);

        foreach (['client_email', 'private_key'] as $key) {
            if (empty($credentials[$key])) {
                throw new RuntimeException("Firebase credentials tidak memiliki {$key}.");
            }
        }

        return $credentials;
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}