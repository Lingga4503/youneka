# Youneka - Mentor Anti Menunda

Youneka adalah aplikasi Flutter yang membantu anak muda memulai tugas, memecah pekerjaan besar, dan menjaga fokus. Aplikasi ini memadukan beranda mentor, rencana harian, chat bimbingan, progress, dan toolkit visual untuk memetakan langkah.

## Fitur utama

- Beranda mentor dengan rekomendasi fokus cepat dan toolkit rencana.
- Bottom navigation ala chat untuk berpindah Beranda, Goals, dan Mentor.
- Template visual untuk memecah tugas dan merancang sesi fokus.
- Rencana harian tersimpan secara lokal di perangkat (offline).
- Rencana diagram dan progress Pomodoro tersimpan secara lokal.
- Editor kanvas untuk menyusun alur kerja dan langkah kecil.
- Ekspor struktur diagram ke format JSON.
- Mentor Andrew dengan login Google, quota AI, dan fondasi premium bulanan.

## Menjalankan aplikasi

```bash
flutter pub get
flutter run
```

## Setup AI production

- Ikuti langkah di [FIREBASE_AI_SETUP.md](FIREBASE_AI_SETUP.md)
- Deploy `functions/`
- Enable Google Sign-In in Firebase Auth
- Create Firestore database
- Configure monthly subscription `youneka_ai_premium_monthly`

## Pengujian

```bash
flutter test
```

## Struktur penting

- `lib/main.dart` - Bootstrap app dan Firebase.
- `test/widget_test.dart` - Pengujian UI untuk beranda dan template.
- `pubspec.yaml` - Metadata proyek dan dependensi Flutter.
