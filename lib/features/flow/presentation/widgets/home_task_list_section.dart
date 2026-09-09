import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

class HomeTaskListSection extends StatelessWidget {
  const HomeTaskListSection({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    this.bottomPadding = 0,
    this.scrollController,
  });

  final List<HomeScheduleItem> tasks;
  final ValueChanged<HomeScheduleItem> onTaskTap;
  final double bottomPadding;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return _TaskListView(
      tasks: tasks,
      onTaskTap: onTaskTap,
      bottomPadding: bottomPadding,
      scrollController: scrollController,
    );
  }
}

class _TaskListView extends StatefulWidget {
  const _TaskListView({
    required this.tasks,
    required this.onTaskTap,
    this.bottomPadding = 0,
    this.scrollController,
  });

  final List<HomeScheduleItem> tasks;
  final ValueChanged<HomeScheduleItem> onTaskTap;
  final double bottomPadding;
  final ScrollController? scrollController;

  @override
  State<_TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<_TaskListView> {
  bool _completedExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: Text(
            'Belum ada tugas. Minta Andrew menambahkannya lewat chat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AADC5), fontSize: 14),
          ),
        ),
      );
    }

    final incomplete = widget.tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) {
        if (a.startAt == null && b.startAt == null) return 0;
        if (a.startAt == null) return 1;
        if (b.startAt == null) return -1;
        return a.startAt!.compareTo(b.startAt!);
      });
    final completed = widget.tasks.where((t) => t.isCompleted).toList();

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: widget.bottomPadding,
      ),
      children: [
        if (incomplete.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(
              child: Text(
                'Semua tugas selesai. Mantap!',
                style: TextStyle(color: Color(0xFF9AADC5), fontSize: 14),
              ),
            ),
          )
        else
          ...incomplete.map(
            (item) => _TaskListTile(
              key: ValueKey(item.id),
              item: item,
              onTap: () => widget.onTaskTap(item),
            ),
          ),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                setState(() => _completedExpanded = !_completedExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _completedExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: const Color(0xFF7B90AF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Selesai (${completed.length})',
                    style: const TextStyle(
                      color: Color(0xFF7B90AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_completedExpanded)
            ...completed.map(
              (item) => _TaskListTile(
                key: ValueKey(item.id),
                item: item,
                onTap: () => widget.onTaskTap(item),
              ),
            ),
        ],
      ],
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final HomeScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHigh = item.priority == SchedulePriority.high;
    final accentColor = item.isCompleted
        ? const Color(0xFF22C55E)
        : isHigh
        ? const Color(0xFF2563EB)
        : const Color(0xFF6F98DC);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isCompleted
                ? const Color(0xFFD4F0E0)
                : const Color(0xFFE1EAF5),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10264A).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.isCompleted ? accentColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 2),
              ),
              child: item.isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: item.isCompleted
                          ? const Color(0xFF9AADC5)
                          : const Color(0xFF1A2B47),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (item.startAt != null || item.pomodorosCompleted > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (item.startAt != null) ...[
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Color(0xFF9AADC5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _fmt(item.startAt!),
                            style: const TextStyle(
                              color: Color(0xFF9AADC5),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (item.startAt != null &&
                            item.pomodorosCompleted > 0)
                          const SizedBox(width: 8),
                        if (item.pomodorosCompleted > 0) ...[
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 12,
                            color: Color(0xFFE08A2B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item.pomodorosCompleted}x',
                            style: const TextStyle(
                              color: Color(0xFFE08A2B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (!item.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isHigh ? 'High' : 'Normal',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $h:$m';
  }
}
