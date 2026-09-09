import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _musicInk = Color(0xFF3A3128);
const Color _musicMuted = Color(0xFF8D8271);
const Color _musicAccent = Color(0xFF8B7FD6);

/// Ambient lofi music player pill for the immersive home scene.
class HomeMusicControl extends StatefulWidget {
  const HomeMusicControl({super.key});

  @override
  State<HomeMusicControl> createState() => _HomeMusicControlState();
}

class _HomeMusicControlState extends State<HomeMusicControl>
    with SingleTickerProviderStateMixin {
  static const String _trackAsset = 'audio/lofi-lofi-chill-lofi-girl-456265.mp3';
  static const String _trackLabel = 'Lofi Chill';

  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _visualizerController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _player.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(AssetSource(_trackAsset));
    }
    if (!mounted) return;
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PillIconButton(icon: Icons.skip_previous_rounded, onTap: null),
              const SizedBox(width: 6),
              _PillIconButton(
                icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                onTap: _toggle,
                filled: true,
              ),
              const SizedBox(width: 6),
              _PillIconButton(icon: Icons.skip_next_rounded, onTap: null),
              const SizedBox(width: 10),
              SizedBox(
                width: 70,
                height: 22,
                child: AnimatedBuilder(
                  animation: _visualizerController,
                  builder: (context, _) {
                    return _Visualizer(
                      animationValue: _visualizerController.value,
                      isPlaying: _isPlaying,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _trackLabel,
            style: GoogleFonts.plusJakartaSans(
              color: _musicMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  const _PillIconButton({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: Material(
        color: filled ? _musicAccent : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              icon,
              size: 17,
              color: filled ? Colors.white : _musicInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _Visualizer extends StatelessWidget {
  const _Visualizer({required this.animationValue, required this.isPlaying});

  final double animationValue;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    const barCount = 10;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(barCount, (index) {
        final phase = (animationValue * 2 * pi) + (index * 0.7);
        final heightFactor = isPlaying
            ? (0.35 + 0.65 * sin(phase).abs())
            : 0.2;
        return Container(
          width: 3,
          height: 22 * heightFactor,
          decoration: BoxDecoration(
            color: _musicAccent.withValues(alpha: isPlaying ? 0.9 : 0.4),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
