# 📱 Mobile Attendance — Face Recognition

> Sistem absensi karyawan berbasis mobile dengan verifikasi wajah **on-device**, lokasi GPS, dan panel admin berbasis web.

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=flat-square&logo=flutter&logoColor=white)
![Laravel](https://img.shields.io/badge/Laravel-12.x-FF2D20?style=flat-square&logo=laravel&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Supabase-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![TFLite](https://img.shields.io/badge/TFLite-MobileFaceNet-FF6F00?style=flat-square&logo=tensorflow&logoColor=white)
![License](https://img.shields.io/badge/License-Private-gray?style=flat-square)

---

## ✨ Highlights

- 🔐 **Face recognition on-device** — MobileFaceNet TFLite, tidak perlu server AI terpisah
- 👁️ **Liveness detection** — Eye-blink challenge via Google ML Kit
- 📍 **GPS geolocation** — Mencatat koordinat & alamat saat absen
- 🖥️ **Admin panel** — Dashboard, manajemen karyawan, rekap laporan, pesan broadcast
- 📊 **Export laporan** — Excel & PDF

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter Mobile App                │
│                                                     │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ ML Kit   │  │ MobileFaceNet│  │   Camera +    │  │
│  │ Face     │──│ TFLite       │──│   Liveness    │  │
│  │ Detector │  │ (192-dim)    │  │   (Blink)     │  │
│  └──────────┘  └──────────────┘  └───────────────┘  │
│         │              │                             │
│         ▼              ▼                             │
│  ┌─────────────────────────────────────────────┐     │
│  │  On-device face matching (Euclidean dist.)  │     │
│  └─────────────────────────────────────────────┘     │
│                        │                             │
│              Embeddings & Attendance data             │
└────────────────────────┼────────────────────────────┘
                         │ REST API
                         ▼
┌─────────────────────────────────────────────────────┐
│              Laravel Backend (API + Admin)           │
│                                                     │
│  ┌────────────┐  ┌────────────┐  ┌───────────────┐  │
│  │ Sanctum    │  │ Attendance │  │  Admin Panel  │  │
│  │ Auth       │  │ API        │  │  (Blade)      │  │
│  └────────────┘  └────────────┘  └───────────────┘  │
│                        │                             │
└────────────────────────┼────────────────────────────┘
                         │
                         ▼
                 ┌───────────────┐
                 │  PostgreSQL   │
                 │  (Supabase)   │
                 └───────────────┘
```

---

## 🔐 Face Recognition — On-Device

Seluruh proses face recognition berjalan **di perangkat pengguna**, tanpa server AI tambahan.

| Tahap | Teknologi | Detail |
|-------|-----------|--------|
| Deteksi wajah | Google ML Kit | Real-time face detection dari camera stream |
| Liveness | ML Kit Classification | Eye-blink challenge (open → close → open) |
| Embedding | MobileFaceNet TFLite | 192-dimensional face vector, input 112×112 RGB |
| Matching | Euclidean Distance | Threshold: 0.72 (strict), 0.82 (relaxed) |
| Caching | Secure Storage | Embeddings di-cache untuk on-device matching |

**Alur registrasi:**
1. User foto 3x (depan, kiri, kanan) → ML Kit validasi wajah tunggal
2. MobileFaceNet extract embedding per foto → cek konsistensi antar embedding
3. Embeddings dikirim ke Laravel → disimpan di database
4. Embeddings di-cache di device untuk verifikasi lokal

**Alur verifikasi (absen):**
1. Liveness check (kedipkan mata) → capture foto
2. MobileFaceNet extract embedding → compare dengan cached embeddings on-device
3. Jika match → kirim data absensi ke server

---

## 📋 Features

### Mobile App (Flutter)

| Feature | Description |
|---------|-------------|
| Authentication | Login & registrasi karyawan via Sanctum token |
| Face Registration | 3-foto registrasi dengan consistency check |
| Face Verification | On-device matching sebelum setiap absen |
| Liveness Detection | Anti-spoofing via eye-blink detection |
| Clock In / Out | Absen masuk & pulang dengan foto + lokasi |
| GPS Location | Auto-detect koordinat & reverse geocoding alamat |
| Attendance History | Riwayat absensi dengan kalender |
| Leave Requests | Pengajuan cuti dengan attachment |
| Cash Advance | Pengajuan kasbon |
| Admin Messages | Terima pesan/broadcast dari admin |
| Dark Mode | Support tema gelap/terang |

### Admin Panel (Laravel Blade)

| Feature | Description |
|---------|-------------|
| Dashboard | Ringkasan statistik absensi hari ini |
| Employee Management | CRUD data karyawan |
| Attendance Records | Lihat & edit data absensi |
| Reports | Rekap laporan absensi (filter periode/karyawan) |
| Export | Download laporan ke Excel & PDF |
| Messages | Kirim pesan/pengumuman ke karyawan |
| Leave Approval | Persetujuan pengajuan cuti |
| Cash Advance Approval | Persetujuan & tracking kasbon |

---

## 📁 Project Structure

```
.
├── absensi_ob/                   # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart             # App entry point
│   │   ├── core/                 # Theme, constants, decorations
│   │   ├── controllers/          # Business logic (attendance)
│   │   ├── models/               # Data models
│   │   ├── pages/                # UI screens
│   │   ├── services/             # API, face recognition, location
│   │   └── widgets/              # Reusable UI components
│   ├── assets/
│   │   └── mobilefacenet.tflite  # Face recognition model
│   └── pubspec.yaml
│
├── laravel-backend/              # Laravel API + Admin panel
│   ├── app/
│   │   ├── Http/Controllers/     # API & web controllers
│   │   ├── Models/               # Eloquent models
│   │   └── Services/             # Business logic services
│   ├── database/migrations/      # Database schema
│   ├── resources/views/          # Blade templates (admin panel)
│   ├── routes/
│   │   ├── api.php               # Mobile API routes
│   │   └── web.php               # Admin panel routes
│   └── config/
│
├── docs/                         # Documentation & assets
└── .gitignore
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter** SDK 3.10+
- **PHP** 8.2+
- **Composer** 2.x
- **Node.js** 18+ & npm
- **PostgreSQL** (atau Supabase)

### 1. Clone Repository

```bash
git clone https://github.com/your-username/mobile-attendance-face-recognition.git
cd mobile-attendance-face-recognition
```

### 2. Setup Laravel Backend

```bash
cd laravel-backend

# Install dependencies
composer install
npm install

# Environment
cp .env.example .env
php artisan key:generate

# Configure .env (database, app URL, etc.)

# Run migrations
php artisan migrate

# Build frontend assets
npm run dev

# Start server
php artisan serve
```

### 3. Setup Flutter App

```bash
cd absensi_ob

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:8000/api
```

> 💡 Gunakan IP komputer lokal (bukan `localhost`) saat menjalankan di device fisik.

---

## 🔌 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Registrasi karyawan baru |
| `POST` | `/api/auth/login` | Login & dapatkan token |

### Face Recognition
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/face/register` | Simpan face embeddings |
| `GET` | `/api/face/check` | Cek status registrasi wajah |
| `GET` | `/api/face/embeddings` | Ambil embeddings untuk cache |

### Attendance
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/attendance` | Riwayat absensi |
| `POST` | `/api/attendance` | Kirim data absensi |

### Profile
| Method | Endpoint | Description |
|--------|----------|-------------|
| `PUT` | `/api/profile` | Update profil |
| `POST` | `/api/profile/photo` | Upload foto profil |
| `PUT` | `/api/profile/password` | Ganti password |

### Messages
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/messages` | Daftar pesan |
| `POST` | `/api/messages/{id}/read` | Tandai pesan dibaca |

### Leave & Cash Advance
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/leave-balance` | Sisa kuota cuti |
| `POST` | `/api/leave-requests` | Ajukan cuti |
| `POST` | `/api/cash-advance-requests` | Ajukan kasbon |
| `DELETE` | `/api/requests/{type}/{id}` | Batalkan pengajuan |

> Semua endpoint (kecuali auth) memerlukan header `Authorization: Bearer {token}`.

---

## ⚙️ Configuration

### Flutter (`--dart-define`)

| Variable | Description | Default |
|----------|-------------|---------|
| `API_BASE_URL` | URL backend API | `http://192.168.100.17:8000/api` |
| `DEV_ATTENDANCE_BYPASS` | Skip face verification (dev only) | `false` |

### Laravel (`.env`)

| Variable | Description |
|----------|-------------|
| `DB_CONNECTION` | Database driver (`pgsql`) |
| `DB_HOST` | Database host (Supabase pooler URL) |
| `DB_PORT` | Database port |
| `DB_DATABASE` | Database name |
| `DB_USERNAME` | Database username |
| `DB_PASSWORD` | Database password |
| `ATTENDANCE_JAM_MASUK` | Jam masuk kerja |
| `ATTENDANCE_TOLERANSI_MENIT` | Toleransi keterlambatan (menit) |
| `ATTENDANCE_JAM_PULANG` | Jam pulang kerja |
| `ATTENDANCE_BIAYA_LEMBUR` | Biaya lembur per hari |

---

## 🛡️ Security

- **Authentication**: Laravel Sanctum (token-based)
- **Token Storage**: Flutter Secure Storage (encrypted)
- **Face Data**: Embeddings only (no raw photos stored on server)
- **Liveness**: Eye-blink anti-spoofing prevents photo/video attacks
- **Local Embedding Cache**: Face embeddings cached in device secure storage

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.10+, Dart |
| Face Detection | Google ML Kit Face Detection |
| Face Recognition | MobileFaceNet (TFLite) |
| Backend | Laravel 12.x, PHP 8.2+ |
| Database | PostgreSQL (Supabase) |
| Auth | Laravel Sanctum |
| Admin UI | Blade + Tailwind CSS |
| Frontend Build | Vite |
