Ini adalah penjelasan detail tentang proyek "absensi_ob" Anda.

### 1. File Konfigurasi (`pubspec.yaml`)

Ini adalah file utama untuk konfigurasi proyek Flutter.

```yaml
name: absensi_ob
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.4 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  intl: ^0.18.1 # Ditambahkan untuk format tanggal dan waktu

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/logo.png # Menambahkan path untuk logo
```

**Penjelasan:**

*   **`intl: ^0.18.1`**: Pustaka (library) ini ditambahkan untuk membantu memformat tanggal dan waktu. Ini sangat berguna agar format tanggal bisa konsisten dan mudah dibaca oleh pengguna (contoh: "12 Februari 2026, 10:30 WIB").
*   **`assets/logo.png`**: Baris ini mendaftarkan file `logo.png` yang ada di dalam folder `assets` agar bisa digunakan di dalam aplikasi, seperti yang ditampilkan di halaman login.

### 2. Struktur Aplikasi (`lib/main.dart`)

Ini adalah titik awal (entry point) dari aplikasi Anda.

```dart
import 'package:absensi_ob/pages/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi OB',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(), // Memulai aplikasi dari LoginPage
    );
  }
}
```

**Penjelasan:**

*   `main()`: Fungsi ini adalah yang pertama kali dijalankan saat aplikasi dibuka. `runApp(const MyApp())` memulai aplikasi Flutter dengan widget `MyApp`.
*   `MyApp`: Ini adalah widget utama aplikasi Anda.
*   `MaterialApp`: Widget ini menyediakan banyak fungsionalitas dasar yang dibutuhkan aplikasi, seperti navigasi (perpindahan antar halaman) dan tema.
*   `home: const LoginPage()`: Ini adalah bagian paling penting. Aplikasi akan pertama kali menampilkan `LoginPage` saat dibuka.

### 3. Halaman Login (`lib/pages/login_page.dart`)

Halaman ini adalah gerbang masuk ke aplikasi.

```dart
import 'package:absensi_ob/pages/home_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan Logo
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'Selamat Datang',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // Tombol Login
            ElevatedButton(
              onPressed: () {
                // Navigasi ke HomePage saat tombol ditekan
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Penjelasan:**

*   `Scaffold`: Menyediakan struktur dasar untuk halaman (seperti latar belakang putih).
*   `Center` dan `Column`: Digunakan untuk menata widget-widget agar berada di tengah layar dan tersusun secara vertikal.
*   `Image.asset('assets/logo.png', ...)`: Menampilkan gambar logo yang sudah didaftarkan di `pubspec.yaml`.
*   `ElevatedButton`: Membuat tombol yang bisa ditekan.
*   `onPressed`: Fungsi yang akan dijalankan saat tombol ditekan.
*   `Navigator.pushReplacement(...)`: Perintah ini digunakan untuk berpindah ke `HomePage`. Disebut `pushReplacement` agar pengguna tidak bisa kembali ke halaman login setelah berhasil masuk.

### 4. Halaman Utama (`lib/pages/home_page.dart`)

Ini adalah halaman utama setelah pengguna login, tempat melakukan absensi.

```dart
import 'package:absensi_ob/models/attendance_record.dart';
import 'package:absensi_ob/pages/history_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<AttendanceRecord> _attendanceRecords = [];
  bool _hasCheckedIn = false;

  void _checkIn() {
    setState(() {
      final now = DateTime.now();
      _attendanceRecords.add(AttendanceRecord(
        checkInTime: now,
        date: now,
      ));
      _hasCheckedIn = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil Check-In')),
    );
  }

  void _checkOut() {
    setState(() {
      _attendanceRecords.last.checkOutTime = DateTime.now();
      _hasCheckedIn = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil Check-Out')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Utama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryPage(records: _attendanceRecords),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(fontSize: 18),
            ),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return Text(
                  DateFormat('HH:mm:ss').format(DateTime.now()),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 40),
            if (!_hasCheckedIn)
              ElevatedButton(
                onPressed: _checkIn,
                child: const Text('Check-In'),
              )
            else
              ElevatedButton(
                onPressed: _checkOut,
                child: const Text('Check-Out'),
              ),
          ],
        ),
      ),
    );
  }
}
```

**Penjelasan:**

*   `StatefulWidget`: Halaman ini bisa berubah (misalnya, tombol berubah dari Check-In ke Check-Out).
*   `_attendanceRecords`: Sebuah list (daftar) untuk menyimpan data absensi.
*   `_hasCheckedIn`: Variabel boolean untuk melacak apakah pengguna sudah check-in atau belum.
*   `_checkIn()`: Fungsi yang dipanggil saat tombol "Check-In" ditekan. Fungsi ini membuat data absensi baru, menyimpannya ke list, dan mengubah status `_hasCheckedIn` menjadi `true`.
*   `_checkOut()`: Fungsi untuk "Check-Out". Fungsi ini mencari data absensi terakhir, mengisi waktu `checkOutTime`, dan mengembalikan status `_hasCheckedIn` menjadi `false`.
*   `DateFormat`: Digunakan untuk menampilkan tanggal dan jam saat ini dengan format yang mudah dibaca.
*   `StreamBuilder`: Widget canggih yang digunakan untuk membuat jam digital. Ia "mendengarkan" aliran data setiap detik dan memperbarui tampilan jam secara real-time tanpa perlu me-refresh seluruh halaman.
*   `if (!_hasCheckedIn) ... else ...`: Logika ini digunakan untuk menampilkan tombol yang berbeda. Jika belum check-in, tampilkan tombol "Check-In". Jika sudah, tampilkan tombol "Check-Out".
*   `AppBar` & `IconButton`: Menampilkan bar di bagian atas dengan tombol riwayat (`Icons.history`) yang akan membawa pengguna ke `HistoryPage` sambil mengirimkan data `_attendanceRecords`.

### 5. Halaman Riwayat (`lib/pages/history_page.dart`)

Halaman untuk menampilkan semua riwayat absensi yang telah dicatat.

```dart
import 'package:absensi_ob/models/attendance_record.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  final List<AttendanceRecord> records;

  const HistoryPage({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
      ),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(DateFormat('EEEE, d MMMM yyyy').format(record.date)),
              subtitle: Text(
                  'Check-In: ${DateFormat('HH:mm').format(record.checkInTime)}\n'
                  'Check-Out: ${record.checkOutTime != null ? DateFormat('HH:mm').format(record.checkOutTime!) : 'Belum Check-Out'}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
```

**Penjelasan:**

*   `final List<AttendanceRecord> records`: Halaman ini menerima data riwayat absensi dari halaman sebelumnya (`HomePage`).
*   `ListView.builder`: Ini adalah cara paling efisien untuk menampilkan daftar yang panjang. Widget ini hanya akan merender item yang terlihat di layar, sehingga sangat hemat memori.
*   `itemCount: records.length`: Memberi tahu `ListView` berapa banyak item yang harus ditampilkan.
*   `itemBuilder`: Fungsi yang dipanggil untuk setiap item dalam daftar. Ia membuat widget `Card` untuk setiap `record` absensi.
*   `ListTile`: Widget yang ideal untuk menampilkan baris dalam daftar, biasanya berisi judul (`title`) dan subjudul (`subtitle`).
*   `record.checkOutTime != null ? ... : ...`: Ini adalah "ternary operator". Sebuah cara singkat untuk menulis `if-else`. Jika `checkOutTime` tidak kosong (artinya sudah check-out), tampilkan waktunya. Jika kosong, tampilkan teks "Belum Check-Out".

### 6. Model Data (`lib/models/attendance_record.dart`)

Ini adalah cetak biru (blueprint) untuk objek data absensi.

```dart
class AttendanceRecord {
  final DateTime date;
  final DateTime checkInTime;
  DateTime? checkOutTime; // Bisa null jika belum check-out

  AttendanceRecord({
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
  });
}
```

**Penjelasan:**

*   `class AttendanceRecord`: Mendefinisikan sebuah struktur data. Setiap kali kita membuat catatan absensi, objeknya akan memiliki properti ini.
*   `final DateTime date`: Menyimpan tanggal absensi. `final` berarti nilainya tidak bisa diubah setelah diatur.
*   `final DateTime checkInTime`: Menyimpan waktu check-in.
*   `DateTime? checkOutTime`: Menyimpan waktu check-out. Tanda tanya `?` menunjukkan bahwa nilai ini boleh kosong (`null`), karena saat pengguna baru check-in, waktu check-outnya belum ada.

### Ringkasan Alur Kerja Aplikasi:

1.  **Buka Aplikasi**: `main.dart` menjalankan aplikasi dan menampilkan `LoginPage`.
2.  **Login**: Pengguna menekan tombol "Login" di `LoginPage`, yang akan mengarahkannya ke `HomePage`.
3.  **Check-In**: Di `HomePage`, pengguna melihat jam digital dan menekan "Check-In". Sebuah `AttendanceRecord` baru dibuat dan disimpan dalam daftar. Tombol berubah menjadi "Check-Out".
4.  **Lihat Riwayat**: Pengguna bisa menekan ikon riwayat di pojok kanan atas `HomePage` untuk pindah ke `HistoryPage` dan melihat daftar absensinya.
5.  **Check-Out**: Pengguna kembali ke `HomePage` dan menekan "Check-Out". Waktu check-out akan dicatat di data absensi terakhir. Tombol kembali berubah menjadi "Check-In" untuk hari berikutnya.
