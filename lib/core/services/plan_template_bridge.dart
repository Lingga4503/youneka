import 'package:flutter/foundation.dart';

enum PlanTemplateBlockKind { task, breakTime, study, meeting, fitness, meal }

class PlanTemplateBlock {
  const PlanTemplateBlock({
    required this.id,
    required this.title,
    required this.startMinute,
    required this.endMinute,
    required this.kind,
    this.note = '',
  });

  final String id;
  final String title;
  final int startMinute;
  final int endMinute;
  final PlanTemplateBlockKind kind;
  final String note;

  int get durationMinutes => (endMinute - startMinute).clamp(0, 1440);

  PlanTemplateBlock copyWith({
    String? id,
    String? title,
    int? startMinute,
    int? endMinute,
    PlanTemplateBlockKind? kind,
    String? note,
  }) {
    return PlanTemplateBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      kind: kind ?? this.kind,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_minute': startMinute,
      'end_minute': endMinute,
      'kind': kind.name,
      'note': note,
    };
  }

  factory PlanTemplateBlock.fromMap(Map<String, dynamic> map) {
    final kindName = map['kind'] as String? ?? PlanTemplateBlockKind.task.name;
    return PlanTemplateBlock(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      startMinute: (map['start_minute'] as num?)?.toInt() ?? 540,
      endMinute: (map['end_minute'] as num?)?.toInt() ?? 600,
      kind: PlanTemplateBlockKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => PlanTemplateBlockKind.task,
      ),
      note: map['note'] as String? ?? '',
    );
  }
}

class PlanTemplatePreset {
  const PlanTemplatePreset({
    required this.id,
    required this.title,
    required this.note,
    required this.blocks,
  });

  final String id;
  final String title;
  final String note;
  final List<PlanTemplateBlock> blocks;

  int get durationMinutes =>
      blocks.fold<int>(0, (sum, block) => sum + block.durationMinutes);

  PlanTemplatePreset copyWith({
    String? id,
    String? title,
    String? note,
    List<PlanTemplateBlock>? blocks,
  }) {
    return PlanTemplatePreset(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      blocks: blocks ?? this.blocks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'blocks': blocks.map((item) => item.toMap()).toList(),
    };
  }

  factory PlanTemplatePreset.fromMap(Map<String, dynamic> map) {
    final blocksRaw = map['blocks'];
    final blocks = blocksRaw is List
        ? blocksRaw
              .whereType<Map>()
              .map(
                (item) =>
                    PlanTemplateBlock.fromMap(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.title.trim().isNotEmpty)
              .toList()
        : <PlanTemplateBlock>[];

    if (blocks.isEmpty) {
      // Backward compatibility with the old single-block template format.
      final duration = (map['duration_minutes'] as num?)?.toInt() ?? 25;
      blocks.add(
        PlanTemplateBlock(
          id: 'legacy_${map['id'] ?? DateTime.now().microsecondsSinceEpoch}',
          title: map['title'] as String? ?? 'Template',
          startMinute: 9 * 60,
          endMinute: (9 * 60) + duration,
          kind: PlanTemplateBlockKind.task,
          note: map['note'] as String? ?? '',
        ),
      );
    }

    return PlanTemplatePreset(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      note: map['note'] as String? ?? '',
      blocks: blocks,
    );
  }
}

class PlanTemplateSelection {
  const PlanTemplateSelection({
    required this.preset,
    required this.token,
    required this.replaceCurrentDay,
  });

  final PlanTemplatePreset preset;
  final int token;
  final bool replaceCurrentDay;
}

class PlanTemplateBridge {
  PlanTemplateBridge._();

  static const healthyHabit = PlanTemplatePreset(
    id: 'healthy_habit',
    title: 'Pagi sehat',
    note: 'Reset energi dengan rangkaian kebiasaan sehat singkat.',
    blocks: [
      PlanTemplateBlock(
        id: 'healthy_habit_water',
        title: 'Minum air & peregangan',
        startMinute: 420,
        endMinute: 440,
        kind: PlanTemplateBlockKind.fitness,
        note: 'Air putih, stretching, napas dalam.',
      ),
      PlanTemplateBlock(
        id: 'healthy_habit_walk',
        title: 'Jalan ringan',
        startMinute: 450,
        endMinute: 470,
        kind: PlanTemplateBlockKind.fitness,
        note: 'Jalan santai atau mobilitas tubuh.',
      ),
    ],
  );

  static const deepWork = PlanTemplatePreset(
    id: 'deep_work',
    title: 'Deep Work Day',
    note: 'Satu fokus utama dengan ritme kerja yang minim distraksi.',
    blocks: [
      PlanTemplateBlock(
        id: 'deep_work_focus_1',
        title: 'Sesi fokus 1',
        startMinute: 540,
        endMinute: 660,
        kind: PlanTemplateBlockKind.task,
        note: 'Kerjakan target paling penting.',
      ),
      PlanTemplateBlock(
        id: 'deep_work_break',
        title: 'Istirahat makan siang',
        startMinute: 720,
        endMinute: 780,
        kind: PlanTemplateBlockKind.breakTime,
        note: 'Jeda total dari layar.',
      ),
      PlanTemplateBlock(
        id: 'deep_work_focus_2',
        title: 'Sesi fokus 2',
        startMinute: 840,
        endMinute: 960,
        kind: PlanTemplateBlockKind.task,
        note: 'Lanjutkan pekerjaan prioritas.',
      ),
    ],
  );

  static const studyFocus = PlanTemplatePreset(
    id: 'study_focus',
    title: 'Belajar fokus',
    note: 'Belajar terarah dengan sesi singkat dan review.',
    blocks: [
      PlanTemplateBlock(
        id: 'study_focus_session',
        title: 'Belajar materi utama',
        startMinute: 570,
        endMinute: 620,
        kind: PlanTemplateBlockKind.study,
        note: 'Satu materi, satu tujuan.',
      ),
      PlanTemplateBlock(
        id: 'study_focus_review',
        title: 'Review catatan',
        startMinute: 630,
        endMinute: 655,
        kind: PlanTemplateBlockKind.study,
        note: 'Ringkas poin penting.',
      ),
    ],
  );

  static const presets = <PlanTemplatePreset>[
    healthyHabit,
    deepWork,
    studyFocus,
  ];

  static final ValueNotifier<PlanTemplateSelection?> selectionNotifier =
      ValueNotifier<PlanTemplateSelection?>(null);

  static int _token = 0;

  static void push(
    PlanTemplatePreset preset, {
    bool replaceCurrentDay = false,
  }) {
    _token += 1;
    selectionNotifier.value = PlanTemplateSelection(
      preset: preset,
      token: _token,
      replaceCurrentDay: replaceCurrentDay,
    );
  }
}
