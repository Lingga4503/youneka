import 'package:flutter/foundation.dart';

class PlanTemplatePreset {
  const PlanTemplatePreset({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.note,
  });

  final String id;
  final String title;
  final int durationMinutes;
  final String note;
}

class PlanTemplateSelection {
  const PlanTemplateSelection({
    required this.preset,
    required this.token,
  });

  final PlanTemplatePreset preset;
  final int token;
}

class PlanTemplateBridge {
  PlanTemplateBridge._();

  static const healthyHabit = PlanTemplatePreset(
    id: 'healthy_habit',
    title: 'Kebiasaan sehat 20 menit',
    durationMinutes: 20,
    note: 'Peregangan, air putih, dan napas dalam.',
  );

  static const deepWork = PlanTemplatePreset(
    id: 'deep_work',
    title: 'Deep work 50 menit',
    durationMinutes: 50,
    note: 'Matikan distraksi, fokus satu target.',
  );

  static const studyFocus = PlanTemplatePreset(
    id: 'study_focus',
    title: 'Belajar fokus 25 menit',
    durationMinutes: 25,
    note: 'Satu materi, satu sesi pomodoro.',
  );

  static const presets = <PlanTemplatePreset>[
    healthyHabit,
    deepWork,
    studyFocus,
  ];

  static final ValueNotifier<PlanTemplateSelection?> selectionNotifier =
      ValueNotifier<PlanTemplateSelection?>(null);

  static int _token = 0;

  static void push(PlanTemplatePreset preset) {
    _token += 1;
    selectionNotifier.value = PlanTemplateSelection(
      preset: preset,
      token: _token,
    );
  }
}

