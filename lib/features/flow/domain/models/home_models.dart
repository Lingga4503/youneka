import 'package:flutter/material.dart';

enum PomodoroPhase { idle, running, paused, completed }

enum SchedulePriority { low, medium, high }

class HomeSettings {
  const HomeSettings({
    required this.pomodoroMinutes,
    required this.sessionsPerRound,
    required this.xpPerPomodoro,
    required this.autoStartNextSession,
  });

  static const defaults = HomeSettings(
    pomodoroMinutes: 25,
    sessionsPerRound: 4,
    xpPerPomodoro: 120,
    autoStartNextSession: false,
  );

  final int pomodoroMinutes;
  final int sessionsPerRound;
  final int xpPerPomodoro;
  final bool autoStartNextSession;

  HomeSettings copyWith({
    int? pomodoroMinutes,
    int? sessionsPerRound,
    int? xpPerPomodoro,
    bool? autoStartNextSession,
  }) {
    return HomeSettings(
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      sessionsPerRound: sessionsPerRound ?? this.sessionsPerRound,
      xpPerPomodoro: xpPerPomodoro ?? this.xpPerPomodoro,
      autoStartNextSession: autoStartNextSession ?? this.autoStartNextSession,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pomodoro_minutes': pomodoroMinutes,
      'sessions_per_round': sessionsPerRound,
      'xp_per_pomodoro': xpPerPomodoro,
      'auto_start_next_session': autoStartNextSession,
    };
  }

  factory HomeSettings.fromMap(Map<String, dynamic> map) {
    return HomeSettings(
      pomodoroMinutes: (map['pomodoro_minutes'] as num?)?.toInt() ?? 25,
      sessionsPerRound: (map['sessions_per_round'] as num?)?.toInt() ?? 4,
      xpPerPomodoro: (map['xp_per_pomodoro'] as num?)?.toInt() ?? 120,
      autoStartNextSession: (map['auto_start_next_session'] as bool?) ?? false,
    );
  }
}

class HomeNotificationItem {
  const HomeNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  HomeNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return HomeNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  factory HomeNotificationItem.fromMap(Map<String, dynamic> map) {
    return HomeNotificationItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: (map['is_read'] as bool?) ?? false,
    );
  }
}

class HomeScheduleItem {
  const HomeScheduleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.priority,
    required this.isCompleted,
    required this.rewardedXp,
    this.location,
  });

  final String id;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final SchedulePriority priority;
  final bool isCompleted;
  final bool rewardedXp;
  final String? location;

  HomeScheduleItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    SchedulePriority? priority,
    bool? isCompleted,
    bool? rewardedXp,
    String? location,
    bool clearLocation = false,
  }) {
    return HomeScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      rewardedXp: rewardedXp ?? this.rewardedXp,
      location: clearLocation ? null : (location ?? this.location),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'priority': priority.name,
      'is_completed': isCompleted,
      'rewarded_xp': rewardedXp,
      'location': location,
    };
  }

  factory HomeScheduleItem.fromMap(Map<String, dynamic> map) {
    final priorityName =
        map['priority'] as String? ?? SchedulePriority.medium.name;
    return HomeScheduleItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      startAt:
          DateTime.tryParse(map['start_at'] as String? ?? '') ?? DateTime.now(),
      endAt:
          DateTime.tryParse(map['end_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      priority: SchedulePriority.values.firstWhere(
        (value) => value.name == priorityName,
        orElse: () => SchedulePriority.medium,
      ),
      isCompleted: (map['is_completed'] as bool?) ?? false,
      rewardedXp: (map['rewarded_xp'] as bool?) ?? false,
      location: map['location'] as String?,
    );
  }
}

class PomodoroRuntime {
  const PomodoroRuntime({
    required this.phase,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.completedSessions,
    required this.totalSessions,
    required this.lastUpdatedMs,
  });

  factory PomodoroRuntime.initial(HomeSettings settings) {
    final totalSeconds = settings.pomodoroMinutes * 60;
    return PomodoroRuntime(
      phase: PomodoroPhase.idle,
      totalSeconds: totalSeconds,
      remainingSeconds: totalSeconds,
      completedSessions: 0,
      totalSessions: settings.sessionsPerRound,
      lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  final PomodoroPhase phase;
  final int totalSeconds;
  final int remainingSeconds;
  final int completedSessions;
  final int totalSessions;
  final int lastUpdatedMs;

  PomodoroRuntime copyWith({
    PomodoroPhase? phase,
    int? totalSeconds,
    int? remainingSeconds,
    int? completedSessions,
    int? totalSessions,
    int? lastUpdatedMs,
  }) {
    return PomodoroRuntime(
      phase: phase ?? this.phase,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedSessions: completedSessions ?? this.completedSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      lastUpdatedMs: lastUpdatedMs ?? this.lastUpdatedMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase.name,
      'total_seconds': totalSeconds,
      'remaining_seconds': remainingSeconds,
      'completed_sessions': completedSessions,
      'total_sessions': totalSessions,
      'last_updated_ms': lastUpdatedMs,
    };
  }

  factory PomodoroRuntime.fromMap(Map<String, dynamic> map) {
    final phaseName = map['phase'] as String? ?? PomodoroPhase.idle.name;
    return PomodoroRuntime(
      phase: PomodoroPhase.values.firstWhere(
        (value) => value.name == phaseName,
        orElse: () => PomodoroPhase.idle,
      ),
      totalSeconds: (map['total_seconds'] as num?)?.toInt() ?? 1500,
      remainingSeconds: (map['remaining_seconds'] as num?)?.toInt() ?? 1500,
      completedSessions: (map['completed_sessions'] as num?)?.toInt() ?? 0,
      totalSessions: (map['total_sessions'] as num?)?.toInt() ?? 4,
      lastUpdatedMs:
          (map['last_updated_ms'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class HomeStateSnapshot {
  const HomeStateSnapshot({
    required this.selectedDate,
    required this.settings,
    required this.pomodoro,
    required this.notifications,
    required this.schedules,
    required this.currentLevel,
    required this.currentXp,
    required this.targetXp,
  });

  final DateTime selectedDate;
  final HomeSettings settings;
  final PomodoroRuntime pomodoro;
  final List<HomeNotificationItem> notifications;
  final List<HomeScheduleItem> schedules;
  final int currentLevel;
  final int currentXp;
  final int targetXp;

  HomeStateSnapshot copyWith({
    DateTime? selectedDate,
    HomeSettings? settings,
    PomodoroRuntime? pomodoro,
    List<HomeNotificationItem>? notifications,
    List<HomeScheduleItem>? schedules,
    int? currentLevel,
    int? currentXp,
    int? targetXp,
  }) {
    return HomeStateSnapshot(
      selectedDate: selectedDate ?? this.selectedDate,
      settings: settings ?? this.settings,
      pomodoro: pomodoro ?? this.pomodoro,
      notifications: notifications ?? this.notifications,
      schedules: schedules ?? this.schedules,
      currentLevel: currentLevel ?? this.currentLevel,
      currentXp: currentXp ?? this.currentXp,
      targetXp: targetXp ?? this.targetXp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selected_date': DateUtils.dateOnly(selectedDate).toIso8601String(),
      'settings': settings.toMap(),
      'pomodoro': pomodoro.toMap(),
      'notifications': notifications.map((item) => item.toMap()).toList(),
      'schedules': schedules.map((item) => item.toMap()).toList(),
      'current_level': currentLevel,
      'current_xp': currentXp,
      'target_xp': targetXp,
    };
  }

  factory HomeStateSnapshot.fromMap(Map<String, dynamic> map) {
    final settingsMap = map['settings'];
    final pomodoroMap = map['pomodoro'];
    final notificationsRaw = map['notifications'];
    final schedulesRaw = map['schedules'];
    return HomeStateSnapshot(
      selectedDate:
          DateTime.tryParse(map['selected_date'] as String? ?? '') ??
          DateUtils.dateOnly(DateTime.now()),
      settings: settingsMap is Map<String, dynamic>
          ? HomeSettings.fromMap(settingsMap)
          : HomeSettings.defaults,
      pomodoro: pomodoroMap is Map<String, dynamic>
          ? PomodoroRuntime.fromMap(pomodoroMap)
          : PomodoroRuntime.initial(HomeSettings.defaults),
      notifications: notificationsRaw is List
          ? notificationsRaw
                .whereType<Map>()
                .map(
                  (item) => HomeNotificationItem.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      schedules: schedulesRaw is List
          ? schedulesRaw
                .whereType<Map>()
                .map(
                  (item) =>
                      HomeScheduleItem.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      currentLevel: (map['current_level'] as num?)?.toInt() ?? 12,
      currentXp: (map['current_xp'] as num?)?.toInt() ?? 1500,
      targetXp: (map['target_xp'] as num?)?.toInt() ?? 2000,
    );
  }
}
