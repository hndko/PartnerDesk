# Panduan Menjalankan & Build PartnerDesk

Panduan ini berisi instruksi lengkap untuk menjalankan aplikasi **PartnerDesk** di environment lokal Anda (Windows) serta cara melakukan *build* ke format APK untuk perangkat Android.

---

## 💻 1. Menjalankan PartnerDesk di Windows (Mode Development)

Karena aplikasi ini menggunakan jembatan (*bridge*) antara Rust dan Flutter, pastikan Anda telah memiliki:
- Flutter SDK (telah di-install)
- Rust Toolchain (telah di-install via `rustup`)

### Langkah-langkah:
1. Buka Terminal / PowerShell.
2. Pindah ke direktori proyek utama Flutter:
   ```powershell
   cd partner_desk
   ```
3. (Opsional namun direkomendasikan) Pastikan dependensi Flutter sudah mutakhir:
   ```powershell
   flutter pub get
   ```
4. Jalankan aplikasi pada desktop Windows:
   ```powershell
   flutter run -d windows
   ```
   *Catatan: Saat pertama kali dijalankan, proses kompilasi kode Rust (di latar belakang) mungkin memakan waktu beberapa menit. Harap bersabar.*

---

## 📱 2. Panduan Build APK untuk Android

Aplikasi PartnerDesk dapat di-build menjadi file instalasi APK (Android Package) sehingga bisa di-install langsung di HP Android Anda.

### Syarat Build Android:
- Anda sudah menginstal **Android Studio** atau **Android SDK Build-Tools**.
- Anda telah menerima lisensi Android (`flutter doctor --android-licenses`).

### Langkah-langkah Build:
1. Buka Terminal / PowerShell dan pastikan berada di folder proyek:
   ```powershell
   cd partner_desk
   ```
2. Jalankan perintah build APK:
   ```powershell
   flutter build apk --release
   ```
3. Tunggu hingga proses kompilasi selesai. Proses ini akan mengompilasi kode Rust untuk target arsitektur Android (ARM64, ARMv7, x86_64) menggunakan NDK, lalu membungkusnya bersama Flutter UI ke dalam format `.apk`.
4. Jika berhasil, file APK akan tersimpan di dalam folder berikut:
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```
5. Salin file `app-release.apk` tersebut ke HP Android Anda dan instal secara manual.

---

## ⚠️ Peringatan Penting (MVP Stage)

- **Fungsi Host di Android**: Saat ini arsitektur mengambil tangkapan layar (Screen Capture) menggunakan `xcap` yang mendukung platform desktop (Windows, macOS, Linux). Menjalankan **Start Host** di Android mungkin akan mengalami *error* karena keterbatasan izin *screen recording* OS Android. Namun, aplikasi di Android bisa digunakan dengan baik sebagai **Viewer** (klien yang meremote perangkat Windows).
- **Pengaturan Jaringan**: Pastikan HP Android dan PC Windows Anda terhubung ke jaringan WiFi/LAN yang sama saat pengujian, atau gunakan pengaturan Firewall untuk mengizinkan aplikasi berjalan di port `9090` dan `9091`.
