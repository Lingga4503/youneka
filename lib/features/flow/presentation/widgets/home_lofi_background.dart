import 'package:flutter/material.dart';

/// Full-bleed background for the immersive home scene.
class HomeLofiBackground extends StatelessWidget {
  const HomeLofiBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/home_lofi_room.png',
      fit: BoxFit.cover,
    );
  }
}

/// Subtle top/bottom gradient scrim so overlay text/icons stay legible
/// over a busy background illustration.
class HomeSceneScrim extends StatelessWidget {
  const HomeSceneScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x59000000),
            Color(0x14000000),
            Color(0x14000000),
            Color(0x66000000),
          ],
          stops: [0.0, 0.22, 0.7, 1.0],
        ),
      ),
    );
  }
}
