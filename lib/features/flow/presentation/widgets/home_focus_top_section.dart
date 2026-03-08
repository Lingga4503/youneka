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
    required this.onNotificationTap,
    required this.onSettingsTap,
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
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFD0EA)),
              ),
              child: const Icon(
                Icons.account_circle_rounded,
                color: accent,
                size: 28,
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
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 36 / 2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, fontSize: 28 / 2),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNotificationTap,
              icon: const Icon(Icons.notifications_none_rounded),
              color: const Color(0xFF4C648A),
              iconSize: 24,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            ),
            IconButton(
              onPressed: onSettingsTap,
              icon: const Icon(Icons.settings_outlined),
              color: const Color(0xFF4C648A),
              iconSize: 24,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text(
              'PROGRESS',
              style: TextStyle(
                color: Color(0xFF8A9BB7),
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 22 / 2,
              ),
            ),
            const Spacer(),
            Text(
              '$currentXp / $targetXp XP',
              style: const TextStyle(
                color: Color(0xFF7F94B6),
                fontWeight: FontWeight.w700,
                fontSize: 24 / 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: 9,
            backgroundColor: const Color(0xFFD7E0ED),
            valueColor: const AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFCCD9EC)),
          ),
          child: Row(
            children: [
              Container(
                width: 86,
                height: 54,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  timerLabel,
                  style: const TextStyle(
                    color: surface,
                    fontWeight: FontWeight.w800,
                    fontSize: 30 / 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pomodoro Session',
                            style: TextStyle(
                              color: Color(0xFF1F56BF),
                              fontWeight: FontWeight.w800,
                              fontSize: 27 / 2,
                            ),
                          ),
                        ),
                        Text(
                          '$currentSession of $totalSession',
                          style: const TextStyle(
                            color: Color(0xFF5F769B),
                            fontWeight: FontWeight.w600,
                            fontSize: 24 / 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(totalSession, (index) {
                        final active = index < currentSession;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index == totalSession - 1 ? 0 : 5,
                            ),
                            height: 5,
                            decoration: BoxDecoration(
                              color: active ? accent : const Color(0xFFD4DCE8),
                              borderRadius: BorderRadius.circular(999),
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
                      width: 40,
                      height: 40,
                      child: Icon(playIcon, color: accent, size: 18),
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
