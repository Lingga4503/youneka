import 'package:flutter/material.dart';

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
  late int _xpPerPomodoro;
  late bool _autoStartNextSession;

  @override
  void initState() {
    super.initState();
    _pomodoroMinutes = widget.initialSettings.pomodoroMinutes;
    _sessionsPerRound = widget.initialSettings.sessionsPerRound;
    _xpPerPomodoro = widget.initialSettings.xpPerPomodoro;
    _autoStartNextSession = widget.initialSettings.autoStartNextSession;
  }

  void _save() {
    Navigator.of(context).pop(
      HomeSettings(
        pomodoroMinutes: _pomodoroMinutes,
        sessionsPerRound: _sessionsPerRound,
        xpPerPomodoro: _xpPerPomodoro,
        autoStartNextSession: _autoStartNextSession,
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
          _SettingCard(
            title: 'XP per Pomodoro',
            subtitle: 'Reward XP saat satu sesi selesai.',
            trailing: Text(
              '$_xpPerPomodoro XP',
              style: const TextStyle(
                color: Color(0xFF2B67D9),
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Slider(
              min: 50,
              max: 250,
              divisions: 8,
              value: _xpPerPomodoro.toDouble(),
              onChanged: (value) {
                setState(() => _xpPerPomodoro = value.round());
              },
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
