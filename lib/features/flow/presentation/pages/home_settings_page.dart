import 'package:flutter/material.dart';

import '../../../mentor/data/mentor_access_service.dart';
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
          const _AiMembershipCard(),
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

class _AiMembershipCard extends StatelessWidget {
  const _AiMembershipCard();

  @override
  Widget build(BuildContext context) {
    final service = MentorAccessService.instance;
    return ValueListenableBuilder<MentorAccessState>(
      valueListenable: service.state,
      builder: (context, state, _) {
        final quota = state.quota;
        final quotaText = quota == null
            ? 'Login Google untuk melihat paket dan kuota AI.'
            : '${quota.planLabel} • ${quota.remaining}/${quota.limit} chat tersisa'
                  '${quota.isPremium ? ' bulan ini' : ' hari ini'}';
        final renewalText = quota?.premiumUntil == null
            ? null
            : 'Aktif sampai ${_formatDate(quota!.premiumUntil!)}';

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
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD77B),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AI Membership',
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
                state.isSignedIn ? state.effectiveDisplayName : 'Belum login',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (state.isSignedIn) ...[
                const SizedBox(height: 4),
                Text(
                  state.user?.email ?? '',
                  style: const TextStyle(
                    color: Color(0xFFD7E4F7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                quotaText,
                style: const TextStyle(color: Color(0xFFD7E4F7), height: 1.35),
              ),
              if (renewalText != null) ...[
                const SizedBox(height: 4),
                Text(
                  renewalText,
                  style: const TextStyle(color: Color(0xFFD7E4F7)),
                ),
              ],
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!state.isSignedIn)
                    FilledButton.icon(
                      onPressed: state.loading
                          ? null
                          : service.signInWithGoogle,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2B67D9),
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Login Google'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: state.loading ? null : service.signOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF8FA6C8)),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                    ),
                  FilledButton.icon(
                    onPressed:
                        state.isSignedIn &&
                            !state.purchasePending &&
                            state.canPurchase
                        ? () async {
                            await service.purchasePremium();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD77B),
                      foregroundColor: const Color(0xFF16233A),
                    ),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: Text(
                      state.premiumProduct?.price == null
                          ? 'Premium Rp33k'
                          : 'Premium ${state.premiumProduct!.price}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: state.purchasePending
                        ? null
                        : service.restorePurchases,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD7E4F7),
                    ),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
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
