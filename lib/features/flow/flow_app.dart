import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/firebase/firebase_bootstrap.dart';
import '../../core/services/app_data_portability_service.dart';
import '../../core/services/app_locale_service.dart';
import 'data/home_state_storage.dart';
import 'domain/models/home_models.dart';
import 'presentation/pages/home_notifications_page.dart';
import 'presentation/pages/home_settings_page.dart';
import 'presentation/widgets/home_focus_top_section.dart';
import 'presentation/widgets/home_schedule_timeline_section.dart';
import '../mentor/data/mentor_access_service.dart';
import '../mentor/presentation/mentor_chat_popup_dialog.dart';
import '../shell/presentation/youneka_home_shell.dart';

// â”€â”€ Color palette â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const Color _andrewTeal = Color(0xFF2B67D9);
const Color _andrewInk = Color(0xFF16233A);
const Color _andrewCream = Color(0xFFF4F6FB);
const Color _andrewSoftTeal = Color(0xFFDDE8F6);
const Color _andrewMuted = Color(0xFF7B90AF);
const Color _andrewCard = Color(0xFFEAF0FA);

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

    if (!AppFirebaseBootstrap.isInitialized) {
      return _AppBootErrorPage(
        message:
            AppFirebaseBootstrap.statusMessage ??
            'App belum siap dijalankan di build ini.',
      );
    }

    return ValueListenableBuilder<MentorAccessState>(
      valueListenable: MentorAccessService.instance.state,
      builder: (context, state, _) {
        if (state.loading) {
          return const _AppSplashPage(showLoading: true);
        }
        if (!state.isSignedIn) {
          return const _AppLoginPage();
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

class _AppLoginPage extends StatelessWidget {
  const _AppLoginPage();

  @override
  Widget build(BuildContext context) {
    final service = MentorAccessService.instance;

    return Scaffold(
      backgroundColor: _andrewCream,
      body: SafeArea(
        child: ValueListenableBuilder<MentorAccessState>(
          valueListenable: service.state,
          builder: (context, state, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 106,
                        height: 106,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x160F172A),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset('assets/andrew_logo.svg'),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Selamat datang di Youneka',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _andrewInk,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Masuk dengan Google untuk menyimpan progres belajar, kuota AI, dan ritme fokusmu di satu akun.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: _andrewMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _LoginBenefitRow(
                        icon: Icons.track_changes_rounded,
                        title: 'Profil dan progres tetap tersimpan',
                        subtitle:
                            'Nama pengguna, level, XP, dan riwayat belajarmu tetap ikut ke akunmu.',
                      ),
                      const SizedBox(height: 12),
                      _LoginBenefitRow(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Mentor Andrew siap dipakai',
                        subtitle:
                            'Dapat 10 chat gratis per hari dan premium kalau nanti kamu butuh.',
                      ),
                      const SizedBox(height: 12),
                      _LoginBenefitRow(
                        icon: Icons.devices_rounded,
                        title: 'Lebih aman untuk lanjut kapan saja',
                        subtitle:
                            'Saat ganti perangkat, akunmu tetap bisa dipakai lagi.',
                      ),
                      if (state.notice != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4DB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF6C66B)),
                          ),
                          child: Text(
                            state.notice!,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF7C4A03),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: state.loading
                              ? null
                              : service.signInWithGoogle,
                          icon: state.loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(
                            state.loading
                                ? 'Menghubungkan akun...'
                                : 'Masuk dengan Google',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginBenefitRow extends StatelessWidget {
  const _LoginBenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _andrewSoftTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _andrewTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: _andrewInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: _andrewMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBootErrorPage extends StatelessWidget {
  const _AppBootErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _andrewCream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD8E3F5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 42,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'App belum siap dijalankan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: _andrewInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: _andrewMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
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
  final _tabRequestNotifier = ValueNotifier<int?>(null);
  final _planPageKey = GlobalKey<_AndrewPlanPageState>();

  Future<void> _handleSidebarAction(String action) async {
    switch (action) {
      case 'import':
        await _importAppData();
        break;
      case 'export':
        await _exportAppData();
        break;
      case 'language':
        await _showLanguagePicker();
        break;
      case 'settings':
        _tabRequestNotifier.value = 0;
        await _planPageKey.currentState?._openSettings();
        break;
    }
  }

  Future<void> _exportAppData() async {
    final path = await AppDataPortabilityService.exportToJsonFile();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export berhasil: $path')));
  }

  Future<void> _importAppData() async {
    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import data'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tempel path file backup .json',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (path == null || path.isEmpty) return;
    final ok = await AppDataPortabilityService.importFromJsonFile(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Import berhasil. Silakan restart app.' : 'File tidak valid.',
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('ðŸ‡®ðŸ‡©', style: TextStyle(fontSize: 20)),
              title: const Text('Indonesia'),
              onTap: () => Navigator.pop(ctx, 'id'),
            ),
            ListTile(
              leading: const Text('ðŸ‡¬ðŸ‡§', style: TextStyle(fontSize: 20)),
              title: const Text('English'),
              onTap: () => Navigator.pop(ctx, 'en'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await AppLocaleService.setLocale(selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bahasa diubah ke ${selected == 'id' ? 'Indonesia' : 'English'}',
        ),
      ),
    );
  }

  Future<void> _openMentorChatPopup() async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'mentor-chat',
      barrierDismissible: true,
      barrierColor: const Color(0x990B1220),
      pageBuilder: (context, _, __) => const MentorChatPopupDialog(),
    );
  }

  @override
  void dispose() {
    _tabRequestNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _AndrewPlanPage(key: _planPageKey),
      const _AndrewAchievementPage(),
    ];

    return YounekaHomeShell(
      pages: pages,
      initialIndex: 0,
      tabRequestNotifier: _tabRequestNotifier,
      onSidebarAction: _handleSidebarAction,
      onMentorTap: _openMentorChatPopup,
    );
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
  });

  final PomodoroPhase phase;
  final String timerLabel;
  final String phaseLabel;
  final IconData playIcon;
  final String playTooltip;
  final IconData actionIcon;
  final String actionTooltip;
  final List<double> sessionProgresses;
}

// â”€â”€ Plan Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AndrewPlanPage extends StatefulWidget {
  const _AndrewPlanPage({super.key});

  @override
  State<_AndrewPlanPage> createState() => _AndrewPlanPageState();
}

class _AndrewPlanPageState extends State<_AndrewPlanPage> {
  // Pomodoro state
  PomodoroRuntime _pomodoro = PomodoroRuntime.initial(HomeSettings.defaults);
  HomeSettings _settings = HomeSettings.defaults;
  Timer? _pomodoroTimer;
  late ValueNotifier<_PomodoroUiSnapshot> _pomodoroUi;

  // Schedule state
  late DateTime _selectedDate;
  List<HomeScheduleItem> _schedules = [];
  List<HomeScheduleItem> _selectedDaySchedules = [];
  ScheduleViewMode _scheduleViewMode = ScheduleViewMode.timeline;

  // Quick-create state
  DateTime? _quickCreateStartAt;
  late TextEditingController _quickCreateTitleController;
  late FocusNode _quickCreateTitleFocusNode;

  // XP / level
  int _currentLevel = 1;
  int _currentXp = 0;
  int _targetXp = 500;

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
    _quickCreateTitleController = TextEditingController();
    _quickCreateTitleFocusNode = FocusNode();
    _loadHomeState();
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _persistTimer?.cancel();
    _pomodoroUi.dispose();
    _quickCreateTitleController.dispose();
    _quickCreateTitleFocusNode.dispose();
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
        _currentLevel = snapshot.currentLevel;
        _currentXp = snapshot.currentXp;
        _targetXp = snapshot.targetXp;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
    _refreshSelectedDaySchedules();
    _pomodoroUi.value = _buildPomodoroUi();
    if (_pomodoro.phase == PomodoroPhase.running) {
      _startPomodoroTimer();
    }
  }

  String _headerDisplayName(MentorAccessState accessState) {
    return accessState.effectiveDisplayName;
  }

  String _headerLevelLabel() {
    return 'Lv. $_currentLevel';
  }

  Future<void> _openProfileEditor() async {
    final service = MentorAccessService.instance;
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
        currentLevel: _currentLevel,
        currentXp: _currentXp,
        targetXp: _targetXp,
      ),
    );
  }

  // â”€â”€ Date navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _selectDate(DateTime date) {
    setState(() => _selectedDate = DateUtils.dateOnly(date));
    _refreshSelectedDaySchedules();
  }

  void _shiftWeek(int delta) {
    final next = _selectedDate.add(Duration(days: delta * 7));
    setState(() => _selectedDate = DateUtils.dateOnly(next));
    _refreshSelectedDaySchedules();
  }

  void _refreshSelectedDaySchedules() {
    setState(() {
      _selectedDaySchedules =
          _schedules
              .where((s) => DateUtils.isSameDay(s.startAt, _selectedDate))
              .toList()
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
    });
  }

  // â”€â”€ Quick create â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _openQuickCreateComposer(DateTime startAt) {
    setState(() {
      _quickCreateStartAt = startAt;
      _quickCreateTitleController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quickCreateTitleFocusNode.requestFocus();
    });
  }

  void _dismissQuickCreateComposer() {
    setState(() => _quickCreateStartAt = null);
    _quickCreateTitleFocusNode.unfocus();
  }

  void _saveQuickCreateComposer() {
    final title = _quickCreateTitleController.text.trim();
    final start = _quickCreateStartAt;
    if (title.isEmpty || start == null) {
      _dismissQuickCreateComposer();
      return;
    }
    final end = start.add(const Duration(hours: 1));
    final item = HomeScheduleItem(
      id: 'sch_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      title: title,
      description: '',
      startAt: start,
      endAt: end,
      priority: SchedulePriority.medium,
      isCompleted: false,
      rewardedXp: false,
    );
    setState(() {
      _schedules = [..._schedules, item];
      _quickCreateStartAt = null;
    });
    _quickCreateTitleFocusNode.unfocus();
    _refreshSelectedDaySchedules();
    _queuePersist();
  }

  // â”€â”€ Schedule CRUD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _openScheduleDetail(HomeScheduleItem item) async {
    final result = await Navigator.of(context).push<HomeScheduleItem>(
      MaterialPageRoute(builder: (_) => _ScheduleDetailPage(item: item)),
    );
    if (result == null || !mounted) return;
    setState(() {
      final idx = _schedules.indexWhere((s) => s.id == result.id);
      if (idx >= 0) {
        _schedules = [..._schedules]..[idx] = result;
      }
    });
    _refreshSelectedDaySchedules();
    _queuePersist();

    // Award XP if completed
    if (result.isCompleted && !item.isCompleted && !result.rewardedXp) {
      final xp = 50 + (result.priority == SchedulePriority.high ? 50 : 0);
      _addXp(xp);
      final rewarded = result.copyWith(rewardedXp: true);
      setState(() {
        final idx2 = _schedules.indexWhere((s) => s.id == rewarded.id);
        if (idx2 >= 0) _schedules = [..._schedules]..[idx2] = rewarded;
      });
      _refreshSelectedDaySchedules();
      _appendNotification(
        title: 'Tugas selesai!',
        body: '${result.title} â€” +$xp XP',
      );
    }
  }

  Future<void> _openAddPlanSheet({
    DateTime? initialDate,
    TimeOfDay? initialStart,
    String? initialTitle,
    int? initialDurationMinutes,
  }) async {
    final result = await showModalBottomSheet<HomeScheduleItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPlanSheet(
        initialDate: initialDate ?? _selectedDate,
        initialStart: initialStart,
        initialTitle: initialTitle,
        initialDurationMinutes: initialDurationMinutes,
        idCounter: _idCounter++,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _schedules = [..._schedules, result];
    });
    _selectedDate = DateUtils.dateOnly(result.startAt);
    _refreshSelectedDaySchedules();
    _queuePersist();
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
        _resetPomodoro();
    }
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

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _pomodoro = PomodoroRuntime.initial(_settings);
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
    final xp = _settings.xpPerPomodoro;

    if (completed >= total) {
      setState(() {
        _pomodoro = _pomodoro.copyWith(
          phase: PomodoroPhase.completed,
          completedSessions: total,
          remainingSeconds: 0,
        );
      });
      _addXp(xp * total);
      _appendNotification(
        title: 'Ronde selesai! ðŸŽ‰',
        body: 'Kamu menyelesaikan $total sesi pomodoro. +${xp * total} XP',
      );
    } else {
      setState(() {
        _pomodoro = _pomodoro.copyWith(
          completedSessions: completed,
          remainingSeconds: _settings.pomodoroMinutes * 60,
          lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
        );
      });
      _addXp(xp);
      _appendNotification(
        title: 'Sesi $completed selesai',
        body: '+$xp XP. Istirahat sebentar ya!',
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

  void _addXp(int xp) {
    int cur = _currentXp + xp;
    int level = _currentLevel;
    int target = _targetXp;
    while (cur >= target) {
      cur -= target;
      level++;
      target = (target * 1.2).round();
    }
    setState(() {
      _currentXp = cur;
      _currentLevel = level;
      _targetXp = target;
    });
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
    final result = await Navigator.of(context).push<List<HomeNotificationItem>>(
      MaterialPageRoute(
        builder: (_) => HomeNotificationsPage(initialItems: _notifications),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _notifications = result);
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
    _pomodoroTimer?.cancel();
    setState(() {
      _settings = result;
      _pomodoro = PomodoroRuntime.initial(result);
    });
    _pomodoroUi.value = _buildPomodoroUi();
    _queuePersist();
  }

  String _settingsSummary() {
    return '${_settings.pomodoroMinutes}m Â· ${_settings.sessionsPerRound} sesi Â· ${_settings.xpPerPomodoro} XP';
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double progress = _targetXp > 0 ? _currentXp / _targetXp : 0.0;

    return Scaffold(
      backgroundColor: _andrewCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // â”€â”€ Top: focus / pomodoro section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: ValueListenableBuilder<_PomodoroUiSnapshot>(
                valueListenable: _pomodoroUi,
                builder: (context, snap, _) {
                  return ValueListenableBuilder<MentorAccessState>(
                    valueListenable: MentorAccessService.instance.state,
                    builder: (context, accessState, _) {
                      return HomeFocusTopSection(
                        title: _headerDisplayName(accessState),
                        subtitle: _headerLevelLabel(),
                        onProfileTap: _openProfileEditor,
                        currentXp: _currentXp,
                        targetXp: _targetXp,
                        progress: progress,
                        timerLabel: snap.timerLabel,
                        currentSession: _pomodoro.completedSessions,
                        totalSession: _pomodoro.totalSessions,
                        phaseLabel: snap.phaseLabel,
                        sessionProgresses: snap.sessionProgresses,
                        onNotificationTap: _openNotifications,
                        onSettingsTap: _openSettings,
                        onToggleAutoStartTap: () {
                          setState(() {
                            _settings = _settings.copyWith(
                              autoStartNextSession:
                                  !_settings.autoStartNextSession,
                            );
                          });
                          _queuePersist();
                        },
                        onResetPomodoroTap: _resetPomodoro,
                        settingsSummary: _settingsSummary(),
                        autoStartEnabled: _settings.autoStartNextSession,
                        onPlayTap: _onPomodoroPlay,
                        onPlayLongPress: _resetPomodoro,
                        playIcon: snap.playIcon,
                        playTooltip: snap.playTooltip,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: const Color(0xFFE4E9F1)),
            const SizedBox(height: 18),
            // â”€â”€ Bottom: schedule section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: HomeScheduleTimelineSection(
                selectedDate: _selectedDate,
                schedules: _selectedDaySchedules,
                quickCreateStartAt: _quickCreateStartAt,
                quickCreateTitleController: _quickCreateTitleController,
                quickCreateTitleFocusNode: _quickCreateTitleFocusNode,
                onSelectDate: _selectDate,
                onShiftWeek: _shiftWeek,
                onCreateScheduleAt: _openQuickCreateComposer,
                onScheduleTap: (item) => unawaited(_openScheduleDetail(item)),
                onQuickCreateDismiss: _dismissQuickCreateComposer,
                onQuickCreateSave: _saveQuickCreateComposer,
                viewMode: _scheduleViewMode,
                onViewModeChanged: (mode) =>
                    setState(() => _scheduleViewMode = mode),
                bottomPadding: 82 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddPlanSheet(initialDate: _selectedDate),
        backgroundColor: _andrewTeal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// â”€â”€ Add Plan Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AddPlanSheet extends StatefulWidget {
  const _AddPlanSheet({
    required this.initialDate,
    this.initialStart,
    this.initialTitle,
    this.initialDurationMinutes,
    required this.idCounter,
  });

  final DateTime initialDate;
  final TimeOfDay? initialStart;
  final String? initialTitle;
  final int? initialDurationMinutes;
  final int idCounter;

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  SchedulePriority _priority = SchedulePriority.medium;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descController = TextEditingController();
    _date = widget.initialDate;
    _start = widget.initialStart ?? TimeOfDay.now();
    final dur = widget.initialDurationMinutes ?? 60;
    final endMin = (_start.hour * 60 + _start.minute + dur) % (24 * 60);
    _end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (t == null) return;
    setState(() {
      if (isStart) {
        _start = t;
      } else {
        _end = t;
      }
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final startAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _start.hour,
      _start.minute,
    );
    var endAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _end.hour,
      _end.minute,
    );
    if (!endAt.isAfter(startAt)) {
      endAt = startAt.add(const Duration(hours: 1));
    }

    final item = HomeScheduleItem(
      id: 'sch_${DateTime.now().microsecondsSinceEpoch}_${widget.idCounter}',
      title: title,
      description: _descController.text.trim(),
      startAt: startAt,
      endAt: endAt,
      priority: _priority,
      isCompleted: false,
      rewardedXp: false,
    );
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: mq.viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE8F6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tambah Jadwal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _andrewInk,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Judul jadwal',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Deskripsi (opsional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SheetChip(
                    icon: Icons.calendar_today_rounded,
                    label: '${_date.day}/${_date.month}/${_date.year}',
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SheetChip(
                    icon: Icons.access_time_rounded,
                    label: _start.format(context),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SheetChip(
                    icon: Icons.access_time_filled_rounded,
                    label: _end.format(context),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: SchedulePriority.values.map((p) {
                final selected = _priority == p;
                final colors = {
                  SchedulePriority.low: const Color(0xFF16A34A),
                  SchedulePriority.medium: const Color(0xFFD97706),
                  SchedulePriority.high: const Color(0xFFDC2626),
                };
                final labels = {
                  SchedulePriority.low: 'Rendah',
                  SchedulePriority.medium: 'Sedang',
                  SchedulePriority.high: 'Tinggi',
                };
                final c = colors[p]!;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? c.withValues(alpha: 0.12)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? c : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            labels[p]!,
                            style: TextStyle(
                              color: selected ? c : const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _andrewCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD2DDEF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _andrewMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: _andrewInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Schedule Detail Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ScheduleDetailPage extends StatefulWidget {
  const _ScheduleDetailPage({required this.item});

  final HomeScheduleItem item;

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
    setState(() => _item = _item.copyWith(isCompleted: !_item.isCompleted));
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
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: _formatTime(_item.startAt),
          ),
          _DetailRow(
            icon: Icons.access_time_filled_rounded,
            label: _formatTime(_item.endAt),
          ),
          _DetailRow(
            icon: Icons.flag_rounded,
            label: 'Prioritas ${priorityLabels[_item.priority]}',
            color: pColor,
          ),
          if (_item.location != null)
            _DetailRow(icon: Icons.location_on_rounded, label: _item.location!),
          const SizedBox(height: 24),
          FilledButton.icon(
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

// â”€â”€ Achievement Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AndrewAchievementPage extends StatelessWidget {
  const _AndrewAchievementPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _andrewCream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prestasi',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _andrewInk,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pencapaian yang sudah kamu raih',
                      style: TextStyle(color: _andrewMuted),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  _AchievementCard(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Streak Pertama',
                    desc: '3 hari berturut-turut',
                    color: const Color(0xFFF97316),
                    unlocked: true,
                  ),
                  _AchievementCard(
                    icon: Icons.timer_rounded,
                    title: 'Fokus Pemula',
                    desc: '5 sesi pomodoro selesai',
                    color: _andrewTeal,
                    unlocked: true,
                  ),
                  _AchievementCard(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Pejuang Jadwal',
                    desc: '10 jadwal selesai',
                    color: const Color(0xFF8B5CF6),
                    unlocked: false,
                  ),
                  _AchievementCard(
                    icon: Icons.bolt_rounded,
                    title: 'Konsisten',
                    desc: '7 hari belajar',
                    color: const Color(0xFFEAB308),
                    unlocked: false,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.unlocked,
  });

  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFEEF0F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked ? color.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: unlocked
                    ? color.withValues(alpha: 0.15)
                    : const Color(0xFFDDE2EA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: unlocked ? color : _andrewMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _andrewInk,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(color: _andrewMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
void unawaited(Future<void> future) {}
