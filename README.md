# Andrew - Mentor Anti Menunda

Andrew adalah aplikasi Flutter yang membantu anak muda memulai tugas, memecah pekerjaan besar, dan menjaga fokus. Aplikasi ini memadukan beranda mentor, rencana harian, chat bimbingan, progress, dan toolkit visual untuk memetakan langkah.

## Fitur utama

- Beranda mentor dengan rekomendasi fokus cepat dan toolkit rencana.
- Bottom navigation ala chat untuk berpindah Beranda, Rencana, Mentor, dan Progress.
- Template visual untuk memecah tugas dan merancang sesi fokus.
- Rencana harian tersimpan secara lokal di perangkat (offline).
- Rencana diagram dan progress Pomodoro tersimpan secara lokal.
- Editor kanvas untuk menyusun alur kerja dan langkah kecil.
- Ekspor struktur diagram ke format JSON.

## Menjalankan aplikasi

```bash
flutter pub get
flutter run
```

## Pengujian

```bash
flutter test
```

## Struktur penting

- `lib/main.dart` - Beranda Andrew + editor flowchart (kanvas, simpul, koneksi, sidebar).
- `test/widget_test.dart` - Pengujian UI untuk beranda dan template.
- `pubspec.yaml` - Metadata proyek dan dependensi Flutter.
