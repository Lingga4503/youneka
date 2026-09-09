import 'package:flutter/material.dart';

import '../../../../core/services/app_locale_service.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../domain/models/home_models.dart';

class HomeSettingsPage extends StatefulWidget {
  const HomeSettingsPage({super.key, required this.initialSettings});

  final HomeSettings initialSettings;

  @override
  State<HomeSettingsPage> createState() => _HomeSettingsPageState();
}

class _HomeSettingsPageState extends State<HomeSettingsPage> {
  late int _pomodoroMinutes;
  late int _sessionsPerRound;
  late bool _autoStartNextSession;

  @override
  void initState() {
    super.initState();
    _pomodoroMinutes = widget.initialSettings.pomodoroMinutes;
    _sessionsPerRound = widget.initialSettings.sessionsPerRound;
    _autoStartNextSession = widget.initialSettings.autoStartNextSession;
  }

  void _save() {
    Navigator.of(context).pop(
      HomeSettings(
        pomodoroMinutes: _pomodoroMinutes,
        sessionsPerRound: _sessionsPerRound,
        autoStartNextSession: _autoStartNextSession,
      ),
    );
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
                _LanguageOptionTile(
                  title: 'Bahasa Indonesia',
                  subtitle: 'Gunakan tampilan bahasa Indonesia',
                  languageCode: 'id',
                  selected: currentCode == 'id',
                  onTap: () => Navigator.of(sheetContext).pop('id'),
                ),
                _LanguageOptionTile(
                  title: 'English',
                  subtitle: 'Use the app in English',
                  languageCode: 'en',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Pengaturan Home')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _AiMembershipCard(),
          ValueListenableBuilder<Locale>(
            valueListenable: AppLocaleService.localeNotifier,
            builder: (context, locale, _) {
              final isIndonesian = locale.languageCode == 'id';
              return _ActionSettingCard(
                title: 'Bahasa',
                subtitle: 'Ganti bahasa aplikasi.',
                trailingLabel: isIndonesian ? 'Indonesia' : 'English',
                icon: Icons.language_rounded,
                onTap: _showLanguagePicker,
              );
            },
          ),
          _SettingCard(
            title: 'Durasi Pomodoro',
            subtitle: 'Durasi per sesi fokus.',
            trailing: Text(
              '$_pomodoroMinutes menit',
              style: const TextStyle(
                color: Color(0xFF2B67D9),
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Slider(
              min: 15,
              max: 60,
              divisions: 9,
              value: _pomodoroMinutes.toDouble(),
              onChanged: (value) {
                setState(() => _pomodoroMinutes = value.round());
              },
            ),
          ),
          _SettingCard(
            title: 'Target Sesi',
            subtitle: 'Jumlah sesi dalam satu ronde.',
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _sessionsPerRound,
                items: List.generate(
                  7,
                  (index) => DropdownMenuItem<int>(
                    value: index + 2,
                    child: Text('${index + 2} sesi'),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sessionsPerRound = value);
                },
              ),
            ),
          ),
          SwitchListTile.adaptive(
            value: _autoStartNextSession,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: const Text(
              'Auto-start sesi berikutnya',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Jika aktif, timer langsung jalan saat sesi selesai.',
            ),
            onChanged: (value) {
              setState(() => _autoStartNextSession = value);
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Simpan Pengaturan'),
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.languageCode,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String languageCode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF0FA) : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2B67D9) : const Color(0xFFD6E0EE),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2B67D9)
                    : const Color(0xFFEAF0FA),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                languageCode.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF2B67D9),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1A2B47),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF7389AB),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected
                  ? const Color(0xFF2B67D9)
                  : const Color(0xFF8BA0BE),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiMembershipCard extends StatelessWidget {
  const _AiMembershipCard();

  Future<void> _openRenameSheet(BuildContext context) async {
    final service = UserProfileService.instance;
    final controller = TextEditingController(
      text: service.state.value.effectiveDisplayName,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ubah nama pengguna',
                    style: TextStyle(
                      color: Color(0xFF1A2B47),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: controller, autofocus: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final navigator = Navigator.of(sheetContext);
                        final ok = await service.saveDisplayName(
                          controller.text,
                        );
                        if (ok) navigator.pop();
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = UserProfileService.instance;
    return ValueListenableBuilder<UserProfileState>(
      valueListenable: service.state,
      builder: (context, state, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF16233A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_circle_rounded,
                    color: Color(0xFFFFD77B),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Akun',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                state.effectiveDisplayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (state.notice != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.notice!,
                  style: const TextStyle(
                    color: Color(0xFFFFD2A8),
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openRenameSheet(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF8FA6C8)),
                ),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Ubah nama'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.child,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2DDEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1A2B47),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7389AB),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          if (child != null) ...[const SizedBox(height: 2), child!],
        ],
      ),
    );
  }
}

class _ActionSettingCard extends StatelessWidget {
  const _ActionSettingCard({
    required this.title,
    required this.subtitle,
    required this.trailingLabel,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailingLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2DDEF)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFDCE8FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF2B67D9)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A2B47),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF7389AB), fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              trailingLabel,
              style: const TextStyle(
                color: Color(0xFF2B67D9),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8BA0BE)),
          ],
        ),
      ),
    );
  }
}
