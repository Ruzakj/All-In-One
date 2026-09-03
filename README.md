# Ric All-In-One

Satu APK Android yang menggabungkan empat proyek:

- **ISO / CSO Tools** — kompresi ISO/CSO dan pengelolaan cutscene native.
- **Emu Hub** — library dan runtime emulator internal.
- **Speedometer** — GPS speedometer, telemetry, ride history, dan replay.
- **Ric Space / VibeTube** — PWA dan toolbox yang dibundel di dalam APK.

Semua fitur dibuka dari dashboard utama dan berjalan di package yang sama (`com.ric.allinone`). Hanya dashboard yang memiliki launcher intent, sehingga hasil instalasi tampil sebagai satu aplikasi.

## Build

GitHub Actions menyiapkan Android SDK/NDK, mengunduh engine emulator yang diperlukan, membangun APK debug, memverifikasi isi APK, lalu mengunggah artifact `Ric-All-In-One-debug`.

Jalankan manual melalui **Actions → Build All-In-One APK → Run workflow**, atau push ke branch `main`.
