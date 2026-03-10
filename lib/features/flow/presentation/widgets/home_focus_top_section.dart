import 'package:flutter/material.dart';

class HomeFocusTopSection extends StatelessWidget {
  const HomeFocusTopSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentXp,
    required this.targetXp,
    required this.progress,
    required this.timerLabel,
    required this.currentSession,
    required this.totalSession,
    required this.phaseLabel,
    required this.sessionProgresses,
    required this.onNotificationTap,
    required this.onSettingsTap,
    required this.onToggleAutoStartTap,
    required this.onResetPomodoroTap,
    required this.settingsSummary,
    required this.autoStartEnabled,
    required this.onPlayTap,
    required this.onPlayLongPress,
    required this.playIcon,
    required this.playTooltip,
  });

  final String title;
  final String subtitle;
  final int currentXp;
  final int targetXp;
  final double progress;
  final String timerLabel;
  final int currentSession;
  final int totalSession;
  final String phaseLabel;
  final List<double> sessionProgresses;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onToggleAutoStartTap;
  final VoidCallback onResetPomodoroTap;
  final String settingsSummary;
  final bool autoStartEnabled;
  final VoidCallback onPlayTap;
  final VoidCallback onPlayLongPress;
  final IconData playIcon;
  final String playTooltip;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF16233A);
    const muted = Color(0xFF7B90AF);
    const accent = Color(0xFF2B67D9);
    const surface = Color(0xFFF8FBFF);
    const card = Color(0xFFE7EDF8);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final safeSegments = sessionProgresses.isEmpty
        ? List<double>.filled(totalSession, 0)
        : sessionProgresses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFD0EA)),
              ),
              child: const Icon(
                Icons.account_circle_rounded,
                color: accent,
                size: 29,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNotificationTap,
              icon: const Icon(Icons.notifications_none_rounded),
              color: const Color(0xFF4C648A),
              iconSize: 22,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            ),
            PopupMenuButton<_HomeSettingsMenuAction>(
              tooltip: 'Pengaturan',
              onSelected: (value) {
                switch (value) {
                  case _HomeSettingsMenuAction.openSettings:
                    onSettingsTap();
                  case _HomeSettingsMenuAction.toggleAutoStart:
                    onToggleAutoStartTap();
                  case _HomeSettingsMenuAction.resetPomodoro:
                    onResetPomodoroTap();
                }
              },
              color: const Color(0xFFFCFEFF),
              surfaceTintColor: Colors.transparent,
              elevation: 10,
              offset: const Offset(0, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFDCE5F2)),
              ),
              constraints: const BoxConstraints(minWidth: 230),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.settings_outlined),
              iconColor: const Color(0xFF4C648A),
              iconSize: 22,
              itemBuilder: (context) => [
                PopupMenuItem<_HomeSettingsMenuAction>(
                  value: _HomeSettingsMenuAction.openSettings,
                  child: _SettingsMenuTile(
                    icon: Icons.tune_rounded,
                    title: 'Pengaturan fokus',
                    subtitle: settingsSummary,
                  ),
                ),
                PopupMenuItem<_HomeSettingsMenuAction>(
                  value: _HomeSettingsMenuAction.toggleAutoStart,
                  child: _SettingsMenuTile(
                    icon: autoStartEnabled
                        ? Icons.play_circle_fill_rounded
                        : Icons.pause_circle_outline_rounded,
                    title: autoStartEnabled
                        ? 'Matikan auto-start'
                        : 'Aktifkan auto-start',
                    subtitle: autoStartEnabled
                        ? 'Sesi berikutnya jalan otomatis'
                        : 'Mulai manual setelah sesi selesai',
                  ),
                ),
                PopupMenuItem<_HomeSettingsMenuAction>(
                  value: _HomeSettingsMenuAction.resetPomodoro,
                  child: const _SettingsMenuTile(
                    icon: Icons.restart_alt_rounded,
                    title: 'Reset pomodoro',
                    subtitle: 'Kembali ke sesi awal',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              'PROGRESS',
              style: TextStyle(
                color: Color(0xFF8A9BB7),
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Text(
              '$currentXp / $targetXp XP',
              style: const TextStyle(
                color: Color(0xFF7F94B6),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: 7,
            backgroundColor: const Color(0xFFD7E0ED),
            valueColor: const AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCD9EC)),
          ),
          child: Row(
            children: [
              Container(
                width: 74,
                height: 46,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  timerLabel,
                  style: const TextStyle(
                    color: surface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pomodoro Session',
                                style: TextStyle(
                                  color: Color(0xFF1F56BF),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phaseLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF7B90AF),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$currentSession of $totalSession',
                          style: const TextStyle(
                            color: Color(0xFF5F769B),
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(totalSession, (index) {
                        final value = index < safeSegments.length
                            ? safeSegments[index].clamp(0.0, 1.0)
                            : 0.0;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index == totalSession - 1 ? 0 : 5,
                            ),
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4DCE8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: playTooltip,
                child: Material(
                  color: surface,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onPlayTap,
                    onLongPress: onPlayLongPress,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(playIcon, color: accent, size: 17),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _HomeSettingsMenuAction { openSettings, toggleAutoStart, resetPomodoro }

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: const Color(0xFF304867), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF182740),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7B90AF),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
