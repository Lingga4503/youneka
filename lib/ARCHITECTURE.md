# Youneka Structure

Tujuan refactor: mengurangi ketergantungan pada satu file `main.dart` agar lebih aman, cepat dirawat, dan mudah scaling.

## Struktur saat ini

- `lib/core/services/app_locale_service.dart`
  - Load/simpan locale app.
  - Menyediakan `ValueNotifier<Locale>` global untuk UI.

- `lib/core/services/app_data_portability_service.dart`
  - Export data prefs ke file JSON.
  - Import data prefs dari file JSON.

- `lib/core/services/user_profile_service.dart`
  - Load/simpan nama pengguna (SharedPreferences).
  - Menyediakan `ValueNotifier<UserProfileState>` global untuk UI (dipakai saat boot app, account sheet, dan Settings).

- `lib/features/flow/`
  - Satu-satunya fitur utama app: halaman home immersive (timer pomodoro besar, kartu tugas, kontrol musik), detail tugas, notifikasi, dan pengaturan.
  - `domain/models/home_models.dart` — model data (`HomeScheduleItem`, `HomeSettings`, `PomodoroRuntime`, dll).
  - `data/home_state_storage.dart` — persistensi lokal (SharedPreferences) untuk seluruh state home.
  - `presentation/widgets/` — widget-widget layar immersive (`HomeLofiBackground`, `HomeFloatingTimer`, `HomeCompactTaskCard`, `HomeMusicControl`, `HomeSceneTopIcons`, `HomeTaskListSection`).
  - `presentation/pages/` — halaman terpisah (`home_settings_page.dart`, `home_notifications_page.dart`).

## Aturan Refactor Lanjutan

1. `main.dart` hanya bootstrap (`runApp`) + wiring minimum.
2. Satu fitur satu folder (`features/<name>`).
3. UI (presentation) tidak langsung menyimpan data; lewat service/repository.
4. Perubahan besar wajib bertahap + verifikasi `flutter analyze` per tahap.
