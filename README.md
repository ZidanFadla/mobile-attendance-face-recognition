# Mobile Attendance Face Recognition

Monorepo sistem absensi OB berbasis Flutter, Laravel API, dan Python face recognition service. Project ini digunakan untuk presensi mobile dengan autentikasi karyawan, verifikasi wajah, lokasi, riwayat absensi, pesan admin, dan panel admin berbasis web.

## Struktur Project

```text
.
├── absensi_ob/             # Flutter mobile app
├── laravel-backend/        # Laravel API dan admin panel
├── python-face-server/     # Service verifikasi/embedding wajah
└── .gitignore              # Ignore file monorepo
```

## Komponen Utama

### Flutter App

Folder: `absensi_ob/`

Fitur utama:

- Login dan registrasi karyawan
- Presensi masuk/pulang
- Deteksi lokasi
- Registrasi dan verifikasi wajah
- Riwayat absensi
- Pesan dari admin
- Penyimpanan token menggunakan secure storage

Jalankan:

```bash
cd absensi_ob
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_BACKEND_URL/api --dart-define=FACE_SERVER_URL=http://YOUR_FACE_SERVER_URL
```

### Laravel Backend

Folder: `laravel-backend/`

Fitur utama:

- REST API untuk aplikasi mobile
- Autentikasi menggunakan Laravel Sanctum
- Manajemen karyawan
- Manajemen absensi
- Manajemen pesan admin
- Laporan absensi
- Integrasi dengan Python face recognition service

Setup:

```bash
cd laravel-backend
composer install
npm install
cp .env.example .env
php artisan key:generate
php artisan migrate
npm run dev
php artisan serve
```

Sesuaikan konfigurasi `.env`, terutama:

```env
APP_URL=http://localhost:8000
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password
FACE_RECOGNITION_URL=http://localhost:5001
```

### Python Face Server

Folder: `python-face-server/`

Fitur utama:

- Generate face embedding
- Registrasi beberapa foto wajah
- Verifikasi wajah berdasarkan cosine similarity
- Preprocessing gambar sederhana untuk pencahayaan

Setup:

```bash
cd python-face-server
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python face_recognition_server.py
```

Default service berjalan di:

```text
http://localhost:5001
```

## Environment dan File Rahasia

File berikut tidak disimpan ke repository:

- `.env`
- `.env.*`
- `vendor/`
- `node_modules/`
- `.venv/`
- `build/`
- `.dart_tool/`
- `android/local.properties`
- file signing seperti `*.jks`, `*.keystore`, `*.pem`, `*.key`
- database lokal seperti `database.sqlite`
- log dan cache

Gunakan `.env.example` sebagai template konfigurasi Laravel.

## Alur Development

1. Jalankan Python face server di port `5001`.
2. Jalankan Laravel backend di port `8000`.
3. Jalankan Flutter app dengan `--dart-define` agar URL backend dan face server sesuai environment lokal.

Contoh:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api --dart-define=FACE_SERVER_URL=http://192.168.1.10:5001
```

Gunakan IP komputer lokal saat menjalankan aplikasi di device fisik.

## Catatan Backup

Repository ini ditujukan sebagai backup source code. Dependency dan file generated tidak ikut disimpan karena bisa dibuat ulang dari file konfigurasi seperti `pubspec.yaml`, `composer.json`, `package.json`, dan `requirements.txt`.
