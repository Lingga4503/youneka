import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/app_locale_service.dart';
import 'data/home_state_storage.dart';
import 'domain/models/home_models.dart';
import 'presentation/pages/home_notifications_page.dart';
import 'presentation/pages/home_settings_page.dart';
import 'presentation/widgets/home_floating_timer.dart';
import 'presentation/widgets/home_lofi_background.dart';
import 'presentation/widgets/home_music_control.dart';
import 'presentation/widgets/home_scene_top_icons.dart';
import 'presentation/widgets/home_task_board_card.dart';
import '../../core/services/user_profile_service.dart';

// â”€â”€ Color palette â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const Color _andrewTeal = Color(0xFF2B67D9);
const Color _andrewInk = Color(0xFF16233A);
const Color _andrewCream = Color(0xFFF4F6FB);
const Color _andrewSoftTeal = Color(0xFFDDE8F6);
const Color _andrewMuted = Color(0xFF7B90AF);

// â”€â”€ Root widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class AndrewApp extends StatefulWidget {
  const AndrewApp({super.key});

  @override
  State<AndrewApp> createState() => _AndrewAppState();
}

class _AndrewAppState extends State<AndrewApp> {
  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    await AppLocaleService.loadSavedLocale();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _andrewTeal,
      brightness: Brightness.light,
    );
    final TextTheme textTheme = GoogleFonts.plusJakartaSansTextTheme();
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocaleService.localeNotifier,
      builder: (context, locale, _) => MaterialApp(
        title: 'Youneka',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: colorScheme,
          textTheme: textTheme,
          scaffoldBackgroundColor: _andrewCream,
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: _andrewInk,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIconColor: const Color(0xFF94A3B8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _andrewTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: _andrewSoftTeal,
            height: 72,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final base =
                  textTheme.labelSmall ?? const TextStyle(fontSize: 12);
              final color = states.contains(WidgetState.selected)
                  ? _andrewTeal
                  : const Color(0xFF94A3B8);
              return base.copyWith(fontWeight: FontWeight.w600, color: color);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final color = states.contains(WidgetState.selected)
                  ? _andrewTeal
                  : const Color(0xFF94A3B8);
              return IconThemeData(color: color, size: 24);
            }),
          ),
        ),
        home: const _AppEntryGate(),
      ),
    );
  }
}

class _AppEntryGate extends StatefulWidget {
  const _AppEntryGate();

  @override
  State<_AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<_AppEntryGate> {
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const _AppSplashPage();
    }

    return ValueListenableBuilder<UserProfileState>(
      valueListenable: UserProfileService.instance.state,
      builder: (context, state, _) {
        if (state.loading) {
          return const _AppSplashPage(showLoading: true);
        }
        return const AppRoot();
      },
    );
  }
}

class _AppSplashPage extends StatelessWidget {
  const _AppSplashPage({this.showLoading = false});

  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _andrewCream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 122,
                height: 122,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 26,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: SvgPicture.asset('assets/andrew_logo.svg'),
              ),
              const SizedBox(height: 22),
              Text(
                'Youneka',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _andrewInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tempat belajar yang lebih fokus, rapi, dan konsisten.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _andrewMuted,
                  height: 1.5,
                ),
              ),
              if (showLoading) ...[
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ App shell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  Widget build(BuildContext context) {
    return const _AndrewPlanPage();
  }
}

// â”€â”€ Pomodoro UI snapshot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PomodoroUiSnapshot {
  const _PomodoroUiSnapshot({
    required this.phase,
    required this.timerLabel,
    required this.phaseLabel,
    required this.playIcon,
    required this.playTooltip,
    required this.actionIcon,
    required this.actionTooltip,
    required this.sessionProgresses,
    required this.completedSessions,
    required this.totalSessions,
  });

  final PomodoroPhase phase;
  final String timerLabel;
  final String phaseLabel;
  final IconData playIcon;
  final String playTooltip;
  final IconData actionIcon;
  final String actionTooltip;
  final List<double> sessionProgresses;
  final int completedSessions;
  final int totalSessions;
}

// â”€â”€ Plan Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AndrewPlanPage extends StatefulWidget {
  const _AndrewPlanPage({super.key});

  @override
  State<_AndrewPlanPage> createState() => AndrewPlanPageState();
}

class AndrewPlanPageState extends State<_AndrewPlanPage> {
  // Pomodoro state
  PomodoroRuntime _pomodoro = PomodoroRuntime.initial(HomeSettings.defaults);
  HomeSettings _settings = HomeSettings.defaults;
  Timer? _pomodoroTimer;
  late ValueNotifier<_PomodoroUiSnapshot> _pomodoroUi;

  // Task state
  late DateTime _selectedDate;
  List<HomeScheduleItem> _schedules = [];

  // Notifications
  List<HomeNotificationItem> _notifications = [];

  bool _isLoading = true;
  int _idCounter = 0;

  // Persist debounce
  Timer? _persistTimer;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _pomodoroUi = ValueNotifier<_PomodoroUiSnapshot>(_buildPomodoroUi());
    _loadHomeState();
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _persistTimer?.cancel();
    _pomodoroUi.dispose();
    super.dispose();
  }

  // â”€â”€ Persistence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _loadHomeState() async {
    final snapshot = await HomeStateStorage.load();
    if (!mounted) return;
    if (snapshot != null) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(snapshot.selectedDate);
        _settings = snapshot.settings;
        _pomodoro = snapshot.pomodoro;
        _notifications = snapshot.notifications;
        _schedules = snapshot.schedules;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
    _pomodoroUi.value = _buildPomodoroUi();
    if (_pomodoro.phase == PomodoroPhase.running) {
      _startPomodoroTimer();
    }
  }

  String _currentLanguageLabel() {
    return AppLocaleService.localeNotifier.value.languageCode == 'id'
        ? 'Indonesia'
        : 'English';
  }

  String _accountSummary(UserProfileState accessState) {
    return 'Kelola profil pengguna';
  }

  Future<void> _openProfileEditor() async {
    final service = UserProfileService.instance;
    final currentName = service.state.value.effectiveDisplayName;
    final controller = TextEditingController(text: currentName);
    String? errorText;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FB),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFBFD0EA),
                              ),
                            ),
                            child: const Icon(
                              Icons.account_circle_rounded,
                              color: _andrewTeal,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ubah nama pengguna',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _andrewInk,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nama ini akan tampil di header home dan akunmu.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: _andrewMuted,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: controller,
                        enabled: !saving,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nama pengguna',
                          hintText: 'Masukkan nama kamu',
                          errorText: errorText,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final navigator = Navigator.of(sheetContext);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final nextName = controller.text.trim();
                                  if (nextName.isEmpty) {
                                    setSheetState(() {
                                      errorText =
                                          'Nama pengguna tidak boleh kosong.';
                                    });
                                    return;
                                  }
                                  if (nextName.length > 40) {
                                    setSheetState(() {
                                      errorText =
                                          'Nama pengguna maksimal 40 karakter.';
                                    });
                                    return;
                                  }

                                  setSheetState(() {
                                    saving = true;
                                    errorText = null;
                                  });
                                  final ok = await service.saveDisplayName(
                                    nextName,
                                  );
                                  if (!mounted) return;
                                  if (ok) {
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Nama pengguna berhasil diperbarui.',
                                        ),
                                      ),
                                    );
                                  } else {
                                    setSheetState(() => saving = false);
                                    final message =
                                        service.state.value.notice ??
                                        'Nama pengguna gagal disimpan.';
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                },
                          child: Text(saving ? 'Menyimpan...' : 'Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  void _queuePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 2), _persist);
  }

  Future<void> _persist() async {
    await HomeStateStorage.save(
      HomeStateSnapshot(
        selectedDate: _selectedDate,
        settings: _settings,
        pomodoro: _pomodoro,
        notifications: _notifications,
        schedules: _schedules,
      ),
    );
  }

  List<HomeScheduleItem> _replaceItemById(
    List<HomeScheduleItem> items,
    HomeScheduleItem next,
  ) {
    final idx = items.indexWhere((item) => item.id == next.id);
    if (idx < 0) return items;
    return [...items]..[idx] = next;
  }

  // -- Task CRUD ------------------------------------------------------------
  Future<void> _openScheduleDetail(HomeScheduleItem item) async {
    final result = await Navigator.of(context).push<HomeScheduleItem>(
      MaterialPageRoute(
        builder: (_) => _ScheduleDetailPage(
          item: item,
          onStartFocus: startFocusForTask,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _schedules = _replaceItemById(_schedules, result);
    });
    _queuePersist();

    if (result.isCompleted && !item.isCompleted) {
      _appendNotification(title: 'Tugas selesai!', body: result.title);
    }
  }

  /// Membuat task dari aksi AI. Return null (bukan throw) kalau state
  /// belum siap (masih loading dari storage) - caller (chat panel) harus
  /// menampilkan pesan "coba lagi sebentar" pada kasus ini.
  HomeScheduleItem? addScheduleFromAssistant({
    required String title,
    DateTime? startAt,
    String description = '',
  }) {
    if (_isLoading) return null;

    final item = HomeScheduleItem(
      id: 'sch_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      title: title,
      description: description,
      startAt: startAt,
      priority: SchedulePriority.medium,
      isCompleted: false,
      pomodorosCompleted: 0,
    );
    setState(() => _schedules = [..._schedules, item]);
    _queuePersist();
    return item;
  }

  /// Membuat task secara manual lewat form tombol "+".
  HomeScheduleItem addScheduleManually({
    required String title,
    DateTime? startAt,
    String description = '',
    SchedulePriority priority = SchedulePriority.medium,
  }) {
    final item = HomeScheduleItem(
      id: 'sch_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      title: title,
      description: description,
      startAt: startAt,
      priority: priority,
      isCompleted: false,
      pomodorosCompleted: 0,
    );
    setState(() => _schedules = [..._schedules, item]);
    _queuePersist();
    return item;
  }

  // â”€â”€ Pomodoro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  _PomodoroUiSnapshot _buildPomodoroUi() {
    final p = _pomodoro;
    final rem = p.remainingSeconds;
    final mm = (rem ~/ 60).toString().padLeft(2, '0');
    final ss = (rem % 60).toString().padLeft(2, '0');
    final timerLabel = '$mm:$ss';

    String phaseLabel;
    IconData playIcon;
    String playTooltip;
    IconData actionIcon;
    String actionTooltip;

    switch (p.phase) {
      case PomodoroPhase.idle:
        phaseLabel = 'Siap untuk mulai';
        playIcon = Icons.play_arrow_rounded;
        playTooltip = 'Mulai sesi';
        actionIcon = Icons.play_circle_outline_rounded;
        actionTooltip = 'Mulai sesi';
      case PomodoroPhase.running:
        phaseLabel = 'Sesi ${p.completedSessions + 1} dari ${p.totalSessions}';
        playIcon = Icons.pause_rounded;
        playTooltip = 'Pause';
        actionIcon = Icons.pause_circle_outline_rounded;
        actionTooltip = 'Pause';
      case PomodoroPhase.paused:
        phaseLabel = 'Dijeda';
        playIcon = Icons.play_arrow_rounded;
        playTooltip = 'Lanjutkan';
        actionIcon = Icons.play_circle_outline_rounded;
        actionTooltip = 'Lanjutkan';
      case PomodoroPhase.completed:
        phaseLabel = 'Ronde selesai! ðŸŽ‰';
        playIcon = Icons.refresh_rounded;
        playTooltip = 'Reset & mulai lagi';
        actionIcon = Icons.refresh_rounded;
        actionTooltip = 'Reset';
    }

    final segProgresses = List<double>.generate(p.totalSessions, (i) {
      if (i < p.completedSessions) return 1.0;
      if (i == p.completedSessions && p.phase == PomodoroPhase.running) {
        return 1.0 - (p.remainingSeconds / p.totalSeconds).clamp(0.0, 1.0);
      }
      return 0.0;
    });

    return _PomodoroUiSnapshot(
      phase: p.phase,
      timerLabel: timerLabel,
      phaseLabel: phaseLabel,
      playIcon: playIcon,
      playTooltip: playTooltip,
      actionIcon: actionIcon,
      actionTooltip: actionTooltip,
      sessionProgresses: segProgresses,
      completedSessions: p.completedSessions,
      totalSessions: p.totalSessions,
    );
  }

  void _onPomodoroPlay() {
    switch (_pomodoro.phase) {
      case PomodoroPhase.idle:
      case PomodoroPhase.paused:
        _resumePomodoro();
      case PomodoroPhase.running:
        _pausePomodoro();
      case PomodoroPhase.completed:
        _restartPomodoro();
    }
  }

  ValueListenable<_PomodoroUiSnapshot> get pomodoroUiListenable => _pomodoroUi;

  /// Mulai sesi fokus untuk [task] langsung di halaman utama (timer besar
  /// yang selalu tampil), tanpa membuka halaman terpisah.
  void startFocusForTask(HomeScheduleItem task) {
    if (_pomodoro.phase == PomodoroPhase.idle ||
        _pomodoro.activeTaskId != task.id) {
      _pomodoroTimer?.cancel();
      setState(() {
        _pomodoro = PomodoroRuntime.initial(_settings).copyWith(
          phase: PomodoroPhase.running,
          activeTaskId: task.id,
          lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
        );
      });
      _pomodoroUi.value = _buildPomodoroUi();
      _startPomodoroTimer();
      _queuePersist();
    }
  }

  void _restartPomodoro() {
    _pomodoroTimer?.cancel();
    final activeTaskId = _pomodoro.activeTaskId;
    setState(() {
      _pomodoro = PomodoroRuntime.initial(_settings).copyWith(
        phase: PomodoroPhase.running,
        activeTaskId: activeTaskId,
        lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
      );
    });
    _pomodoroUi.value = _buildPomodoroUi();
    _startPomodoroTimer();
    _queuePersist();
  }

  void _resumePomodoro() {
    setState(() {
      _pomodoro = _pomodoro.copyWith(
        phase: PomodoroPhase.running,
        lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
      );
    });
    _pomodoroUi.value = _buildPomodoroUi();
    _startPomodoroTimer();
    _queuePersist();
  }

  void _pausePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _pomodoro = _pomodoro.copyWith(phase: PomodoroPhase.paused);
    });
    _pomodoroUi.value = _buildPomodoroUi();
    _queuePersist();
  }

  void _startPomodoroTimer() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = ((now - _pomodoro.lastUpdatedMs) / 1000).round().clamp(
        0,
        9999,
      );
      final newRemaining = (_pomodoro.remainingSeconds - elapsed).clamp(
        0,
        99999,
      );
      _pomodoro = _pomodoro.copyWith(
        remainingSeconds: newRemaining,
        lastUpdatedMs: now,
      );
      if (newRemaining <= 0) {
        _onSessionComplete();
      } else {
        _pomodoroUi.value = _buildPomodoroUi();
      }
    });
  }

  void _onSessionComplete() {
    _pomodoroTimer?.cancel();
    final completed = _pomodoro.completedSessions + 1;
    final total = _pomodoro.totalSessions;
    final taskId = _pomodoro.activeTaskId;

    if (taskId != null) {
      setState(() {
        final idx = _schedules.indexWhere((t) => t.id == taskId);
        if (idx >= 0) {
          _schedules = [..._schedules]
            ..[idx] = _schedules[idx].copyWith(
              pomodorosCompleted: _schedules[idx].pomodorosCompleted + 1,
            );
        }
      });
    }

    if (completed >= total) {
      setState(() {
        _pomodoro = _pomodoro.copyWith(
          phase: PomodoroPhase.completed,
          completedSessions: total,
          remainingSeconds: 0,
        );
      });
      _appendNotification(
        title: 'Ronde selesai! ðŸŽ‰',
        body: 'Kamu menyelesaikan $total sesi pomodoro.',
      );
    } else {
      setState(() {
        _pomodoro = _pomodoro.copyWith(
          completedSessions: completed,
          remainingSeconds: _settings.pomodoroMinutes * 60,
          lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
        );
      });
      _appendNotification(
        title: 'Sesi $completed selesai',
        body: 'Istirahat sebentar ya!',
      );
      if (_settings.autoStartNextSession) {
        _startPomodoroTimer();
      } else {
        setState(() {
          _pomodoro = _pomodoro.copyWith(phase: PomodoroPhase.paused);
        });
      }
    }
    _pomodoroUi.value = _buildPomodoroUi();
    _queuePersist();
  }

  // â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _appendNotification({required String title, required String body}) {
    final item = HomeNotificationItem(
      id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
    );
    setState(() {
      _notifications = [item, ..._notifications];
    });
  }

  // â”€â”€ Open notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _openNotifications() async {
    final navigator = Navigator.of(context);
    final result = await navigator.push<List<HomeNotificationItem>>(
      MaterialPageRoute(
        builder: (_) => HomeNotificationsPage(initialItems: _notifications),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _notifications = result);
    _queuePersist();
  }

  HomeSettings get currentSettings => _settings;

  void applySettings(HomeSettings result) {
    if (!mounted) return;
    _pomodoroTimer?.cancel();
    setState(() {
      _settings = result;
      _pomodoro = PomodoroRuntime.initial(result);
    });
    _pomodoroUi.value = _buildPomodoroUi();
    _queuePersist();
  }

  // â”€â”€ Open settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<HomeSettings>(
      MaterialPageRoute(
        builder: (_) => HomeSettingsPage(initialSettings: _settings),
      ),
    );
    if (result == null || !mounted) return;
    applySettings(result);
  }

  Future<void> _showLanguagePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final currentCode = AppLocaleService.localeNotifier.value.languageCode;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4DCE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pilih Bahasa',
                  style: TextStyle(
                    color: Color(0xFF1A2B47),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bahasa aplikasi akan langsung berubah.',
                  style: TextStyle(
                    color: Color(0xFF7389AB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                _InlineLanguageOptionTile(
                  title: 'Bahasa Indonesia',
                  subtitle: 'Gunakan tampilan bahasa Indonesia',
                  selected: currentCode == 'id',
                  onTap: () => Navigator.of(sheetContext).pop('id'),
                ),
                _InlineLanguageOptionTile(
                  title: 'English',
                  subtitle: 'Use the app in English',
                  selected: currentCode == 'en',
                  onTap: () => Navigator.of(sheetContext).pop('en'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    await AppLocaleService.setLocale(selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected == 'id'
              ? 'Bahasa diubah ke Indonesia'
              : 'Language changed to English',
        ),
      ),
    );
  }

  Future<void> _openAccountSheet(UserProfileState accessState) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4DCE8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.account_circle_rounded,
                          color: _andrewTeal,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              accessState.effectiveDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _andrewInk,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_rounded, color: _andrewTeal),
                    title: const Text(
                      'Ubah nama pengguna',
                      style: TextStyle(
                        color: _andrewInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Perbarui nama yang tampil di aplikasi',
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _openProfileEditor();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHelpSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Center(child: _SheetGrabber()),
                  SizedBox(height: 18),
                  Text(
                    'Bantuan cepat',
                    style: TextStyle(
                      color: _andrewInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  _HelpPoint(
                    title: 'Timer Pomodoro',
                    body:
                        'Tap tombol play di tengah layar untuk mulai atau jeda sesi fokus.',
                  ),
                  _HelpPoint(
                    title: 'Tugas',
                    body:
                        'Tap kartu tugas di pojok kiri bawah untuk lihat semua tugas, atau tap "+" untuk menambah tugas baru.',
                  ),
                  _HelpPoint(
                    title: 'Musik',
                    body:
                        'Tap ikon musik di pojok kanan bawah untuk memutar atau menjeda musik ambient.',
                  ),
                  _HelpPoint(
                    title: 'Pengaturan lengkap',
                    body:
                        'Kelola bahasa, preferensi fokus, dan opsi aplikasi lainnya.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  String _settingsSummary() {
    return '${_settings.pomodoroMinutes}m Â· ${_settings.sessionsPerRound} sesi';
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _toggleTaskCompleted(HomeScheduleItem item) {
    final updated = item.copyWith(isCompleted: !item.isCompleted);
    setState(() {
      _schedules = _replaceItemById(_schedules, updated);
    });
    _queuePersist();
  }

  Future<void> _openAddTaskSheet(BuildContext context) async {
    final titleController = TextEditingController();
    DateTime? selectedStartAt;
    var selectedPriority = SchedulePriority.medium;
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tugas Baru',
                        style: GoogleFonts.plusJakartaSans(
                          color: _andrewInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Judul tugas',
                          hintText: 'Misalnya: Belajar matematika',
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedStartAt ?? now,
                            firstDate: now.subtract(const Duration(days: 1)),
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (date == null || !context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              selectedStartAt ?? now,
                            ),
                          );
                          if (time == null) return;
                          setSheetState(() {
                            selectedStartAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text(
                          selectedStartAt == null
                              ? 'Atur waktu (opsional)'
                              : '${selectedStartAt!.day.toString().padLeft(2, '0')}/${selectedStartAt!.month.toString().padLeft(2, '0')} ${selectedStartAt!.hour.toString().padLeft(2, '0')}:${selectedStartAt!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<SchedulePriority>(
                        segments: const [
                          ButtonSegment(
                            value: SchedulePriority.low,
                            label: Text('Rendah'),
                          ),
                          ButtonSegment(
                            value: SchedulePriority.medium,
                            label: Text('Sedang'),
                          ),
                          ButtonSegment(
                            value: SchedulePriority.high,
                            label: Text('Tinggi'),
                          ),
                        ],
                        selected: {selectedPriority},
                        onSelectionChanged: (value) {
                          setSheetState(() => selectedPriority = value.first);
                        },
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              setSheetState(() {
                                errorText = 'Judul tugas wajib diisi.';
                              });
                              return;
                            }
                            addScheduleManually(
                              title: title,
                              startAt: selectedStartAt,
                              priority: selectedPriority,
                            );
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tambah Tugas'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const HomeLofiBackground(),
          const HomeSceneScrim(),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: ValueListenableBuilder<UserProfileState>(
                    valueListenable: UserProfileService.instance.state,
                    builder: (context, accessState, _) {
                      return HomeSceneTopIcons(
                        onNotificationTap: _openNotifications,
                        onAccountTap: () => _openAccountSheet(accessState),
                        onLanguageTap: _showLanguagePicker,
                        onHelpTap: _showHelpSheet,
                        onFullSettingsTap: _openSettings,
                        languageSummary: _currentLanguageLabel(),
                        accountSummary: _accountSummary(accessState),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 64,
                  right: 8,
                  child: ValueListenableBuilder<_PomodoroUiSnapshot>(
                    valueListenable: _pomodoroUi,
                    builder: (context, snap, _) {
                      return HomeFloatingTimer(
                        timerLabel: snap.timerLabel,
                        phaseLabel: snap.phaseLabel,
                        completedSessions: snap.completedSessions,
                        totalSessions: snap.totalSessions,
                        sessionProgresses: snap.sessionProgresses,
                        playIcon: snap.playIcon,
                        playTooltip: snap.playTooltip,
                        onPlayTap: _onPomodoroPlay,
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 84,
                  child: HomeTaskBoardCard(
                    tasks: _schedules,
                    onTaskTap: (item) => unawaited(_openScheduleDetail(item)),
                    onAddTap: () => unawaited(_openAddTaskSheet(context)),
                    onToggleComplete: _toggleTaskCompleted,
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(child: HomeMusicControl()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Schedule Detail Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ScheduleDetailPage extends StatefulWidget {
  const _ScheduleDetailPage({required this.item, required this.onStartFocus});

  final HomeScheduleItem item;
  final ValueChanged<HomeScheduleItem> onStartFocus;

  @override
  State<_ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<_ScheduleDetailPage> {
  late HomeScheduleItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  void _toggleComplete() {
    final nextCompleted = !_item.isCompleted;
    setState(() => _item = _item.copyWith(isCompleted: nextCompleted));
  }

  @override
  Widget build(BuildContext context) {
    final priorityColors = {
      SchedulePriority.low: const Color(0xFF16A34A),
      SchedulePriority.medium: const Color(0xFFD97706),
      SchedulePriority.high: const Color(0xFFDC2626),
    };
    final priorityLabels = {
      SchedulePriority.low: 'Rendah',
      SchedulePriority.medium: 'Sedang',
      SchedulePriority.high: 'Tinggi',
    };
    final pColor = priorityColors[_item.priority]!;

    return Scaffold(
      backgroundColor: _andrewCream,
      appBar: AppBar(
        title: const Text('Detail Jadwal'),
        actions: [
          IconButton(
            tooltip: 'Selesai',
            icon: Icon(
              _item.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
            ),
            color: _item.isCompleted ? const Color(0xFF16A34A) : _andrewMuted,
            onPressed: _toggleComplete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _item.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _andrewInk,
              decoration: _item.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 12),
          if (_item.description.isNotEmpty) ...[
            Text(
              _item.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: _andrewMuted, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
          if (_item.startAt != null)
            _DetailRow(
              icon: Icons.access_time_rounded,
              label: _formatTime(_item.startAt!),
            ),
          _DetailRow(
            icon: Icons.flag_rounded,
            label: 'Prioritas ${priorityLabels[_item.priority]}',
            color: pColor,
          ),
          if (_item.pomodorosCompleted > 0)
            _DetailRow(
              icon: Icons.local_fire_department_rounded,
              label: 'Pomodoro selesai: ${_item.pomodorosCompleted}',
            ),
          const SizedBox(height: 24),
          if (!_item.isCompleted) ...[
            FilledButton.icon(
              onPressed: () {
                widget.onStartFocus(_item);
                Navigator.of(context).pop(_item);
              },
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('Mulai Fokus'),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(_item),
            icon: const Icon(Icons.save_rounded),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year}  $h:$m';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? _andrewMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color ?? _andrewInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD4DCE8),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _HelpPoint extends StatelessWidget {
  const _HelpPoint({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: _andrewTeal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _andrewInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(color: _andrewMuted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLanguageOptionTile extends StatelessWidget {
  const _InlineLanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6EEFF) : const Color(0xFFF4F7FC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.language_rounded,
          color: selected ? _andrewTeal : _andrewMuted,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _andrewInk,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF7389AB), fontSize: 12),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: _andrewTeal)
          : null,
    );
  }
}

// ignore: unused_element
void unawaited(Future<void> future) {}
