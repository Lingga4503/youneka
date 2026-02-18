# Youneka Structure (Phase 1)

Tujuan refactor: mengurangi ketergantungan pada satu file `main.dart` agar lebih aman, cepat dirawat, dan mudah scaling.

## Sudah Dipisah

- `lib/core/services/app_locale_service.dart`
  - Load/simpan locale app.
  - Menyediakan `ValueNotifier<Locale>` global untuk UI.

- `lib/core/services/app_data_portability_service.dart`
  - Export data prefs ke file JSON.
  - Import data prefs dari file JSON.

- `lib/features/shell/presentation/youneka_home_shell.dart`
  - Shell utama (konten + sidebar kanan mission).
  - Navigasi tab utama dan aksi menu sidebar.

- `lib/features/mentor/presentation/mentor_chat_popup_dialog.dart`
  - Popup chat mentor AI.
  - Overlay blur + gate unduh model Qwen offline.

## Target Struktur Best Practice (Phase 2)

```text
lib/
  app/
    app.dart
    theme/
    router/
  core/
    services/
    utils/
    constants/
  features/
    home/
      presentation/
      domain/
      data/
    plan/
      presentation/
      domain/
      data/
    mentor/
      presentation/
      domain/
      data/
    mission/
      presentation/
      domain/
      data/
    pomodoro/
      presentation/
      domain/
      data/
```

## Aturan Refactor Lanjutan

1. `main.dart` hanya bootstrap (`runApp`) + wiring minimum.
2. Satu fitur satu folder (`features/<name>`).
3. UI (presentation) tidak langsung menyimpan data; lewat service/repository.
4. Perubahan besar wajib bertahap + verifikasi `flutter analyze` per tahap.
