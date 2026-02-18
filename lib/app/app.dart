import 'package:flutter/material.dart';
import 'package:flow/features/flow/flow_app.dart';

/// Root widget for the Youneka app. Keeps main.dart minimal
/// and delegates the real app tree to feature code.
class YounekaApp extends StatelessWidget {
  const YounekaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse existing AndrewApp tree for now.
    return const AndrewApp();
  }
}

