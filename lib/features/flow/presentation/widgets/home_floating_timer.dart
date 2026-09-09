import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Circular pomodoro timer overlaid on the immersive home background.
class HomeFloatingTimer extends StatelessWidget {
  const HomeFloatingTimer({
    super.key,
    required this.timerLabel,
    required this.phaseLabel,
    required this.completedSessions,
    required this.totalSessions,
    required this.sessionProgresses,
    required this.playIcon,
    required this.playTooltip,
    required this.onPlayTap,
  });

  final String timerLabel;
  final String phaseLabel;
  final int completedSessions;
  final int totalSessions;
  final List<double> sessionProgresses;
  final IconData playIcon;
  final String playTooltip;
  final VoidCallback onPlayTap;

  double get _ringProgress {
    if (sessionProgresses.isEmpty || totalSessions == 0) return 0;
    final sum = sessionProgresses.fold<double>(0, (a, b) => a + b.clamp(0.0, 1.0));
    return (sum / totalSessions).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 210,
            height: 210,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 4,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.35)),
            ),
          ),
          SizedBox(
            width: 210,
            height: 210,
            child: CircularProgressIndicator(
              value: _ringProgress,
              strokeWidth: 4,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phaseLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timerLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 3)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sesi $completedSessions/$totalSessions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RingButton(
                      icon: Icons.stop_rounded,
                      onTap: null,
                      small: true,
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: playTooltip,
                      child: _RingButton(
                        icon: playIcon,
                        onTap: onPlayTap,
                        small: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingButton extends StatelessWidget {
  const _RingButton({required this.icon, required this.onTap, required this.small});

  final IconData icon;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 30.0 : 38.0;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: Colors.white.withValues(alpha: 0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: Colors.white, size: small ? 15 : 19),
          ),
        ),
      ),
    );
  }
}
