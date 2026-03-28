import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

enum ScheduleViewMode { timeline, kanban, list }

class HomeScheduleTimelineSection extends StatelessWidget {
  const HomeScheduleTimelineSection({
    super.key,
    required this.selectedDate,
    required this.schedules,
    required this.quickCreateStartAt,
    required this.quickCreateTitleController,
    required this.quickCreateTitleFocusNode,
    required this.onSelectDate,
    required this.onShiftWeek,
    required this.onCreateScheduleAt,
    required this.onScheduleTap,
    required this.onQuickCreateDismiss,
    required this.onQuickCreateSave,
    this.viewMode = ScheduleViewMode.timeline,
    this.onViewModeChanged,
    this.bottomPadding = 0,
  });

  final DateTime selectedDate;
  final List<HomeScheduleItem> schedules;
  final DateTime? quickCreateStartAt;
  final TextEditingController quickCreateTitleController;
  final FocusNode quickCreateTitleFocusNode;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<int> onShiftWeek;
  final ValueChanged<DateTime> onCreateScheduleAt;
  final ValueChanged<HomeScheduleItem> onScheduleTap;
  final VoidCallback onQuickCreateDismiss;
  final VoidCallback onQuickCreateSave;
  final ScheduleViewMode viewMode;
  final ValueChanged<ScheduleViewMode>? onViewModeChanged;
  final double bottomPadding;

  static const double _hourHeight = 58;
  static const double _timeColumnWidth = 40;
  static const double _timelineGap = 8;
  static const double _canvasTopPadding = 8;
  static const double _canvasBottomPadding = 18;

  @override
  Widget build(BuildContext context) {
    final totalHeight =
        (_hourHeight * 24) + _canvasTopPadding + _canvasBottomPadding;

    // ── Sticky header: switcher + week strip ────────────────────────────────
    final stickyHeader = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ViewModeSwitcher(
          current: viewMode,
          onChanged: onViewModeChanged ?? (_) {},
        ),
        const SizedBox(height: 12),
        _WeekDayStrip(
          selectedDate: selectedDate,
          onSelectDate: onSelectDate,
          onShiftWeek: onShiftWeek,
        ),
        const SizedBox(height: 8),
      ],
    );

    if (viewMode == ScheduleViewMode.timeline) {
      // Hanya grid jam yang scroll, header tetap di atas
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stickyHeader,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasLeft = _timeColumnWidth + _timelineGap;
                final canvasWidth = math.max(
                  0.0,
                  constraints.maxWidth - canvasLeft,
                );
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: SizedBox(
                    height: totalHeight,
                    width: constraints.maxWidth,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _HourGrid(
                            timeColumnWidth: _timeColumnWidth,
                            canvasLeft: canvasLeft,
                            hourHeight: _hourHeight,
                            topPadding: _canvasTopPadding,
                          ),
                        ),
                        Positioned(
                          left: canvasLeft,
                          right: 0,
                          top: _canvasTopPadding,
                          height: _hourHeight * 24,
                          child: _TapCalendarSurface(
                            selectedDate: selectedDate,
                            canvasWidth: canvasWidth,
                            hourHeight: _hourHeight,
                            onCreateScheduleAt: onCreateScheduleAt,
                          ),
                        ),
                        for (final item in schedules)
                          _PositionedScheduleCard(
                            item: item,
                            topPadding: _canvasTopPadding,
                            timeColumnWidth: _timeColumnWidth,
                            canvasLeft: canvasLeft,
                            canvasWidth: canvasWidth,
                            hourHeight: _hourHeight,
                            onTap: () => onScheduleTap(item),
                          ),
                        if (quickCreateStartAt != null)
                          _PositionedQuickCreateComposer(
                            startAt: quickCreateStartAt!,
                            topPadding: _canvasTopPadding,
                            canvasLeft: canvasLeft,
                            canvasWidth: canvasWidth,
                            hourHeight: _hourHeight,
                            titleController: quickCreateTitleController,
                            titleFocusNode: quickCreateTitleFocusNode,
                            onDismiss: onQuickCreateDismiss,
                            onSave: onQuickCreateSave,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Kanban & List: header sticky, konten scroll sendiri
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stickyHeader,
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: viewMode == ScheduleViewMode.kanban
                ? _KanbanView(
                    schedules: schedules,
                    onScheduleTap: onScheduleTap,
                  )
                : _TaskListView(
                    schedules: schedules,
                    onScheduleTap: onScheduleTap,
                  ),
          ),
        ),
      ],
    );
  }
}

class _WeekDayStrip extends StatelessWidget {
  const _WeekDayStrip({
    required this.selectedDate,
    required this.onSelectDate,
    required this.onShiftWeek,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<int> onShiftWeek;

  @override
  Widget build(BuildContext context) {
    final selected = DateUtils.dateOnly(selectedDate);
    final startOfWeek = selected.subtract(Duration(days: selected.weekday - 1));
    final days = List<DateTime>.generate(
      7,
      (index) => DateUtils.dateOnly(startOfWeek.add(Duration(days: index))),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity <= -120) {
          onShiftWeek(1);
        } else if (velocity >= 120) {
          onShiftWeek(-1);
        }
      },
      child: SizedBox(
        height: 68,
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final day = days[index];
            final isSelected = DateUtils.isSameDay(day, selected);
            return _DayPill(
              date: day,
              selected: isSelected,
              onTap: () => onSelectDate(day),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View Mode Switcher
// ─────────────────────────────────────────────────────────────────────────────

class _ViewModeSwitcher extends StatelessWidget {
  const _ViewModeSwitcher({required this.current, required this.onChanged});

  final ScheduleViewMode current;
  final ValueChanged<ScheduleViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD7E2F2).withValues(alpha: 0.0),
                          const Color(0xFFD7E2F2),
                          const Color(0xFFD7E2F2).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openModeMenu(context),
                onLongPress: () => _openModeMenu(context),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3C72EA), Color(0xFF6D95FF)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2D5BE3,
                              ).withValues(alpha: 0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.95),
                            width: 1.5,
                          ),
                        ),
                        child: Transform.rotate(
                          angle: -math.pi / 4,
                          child: Icon(
                            _modeIcon(current),
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openModeMenu(BuildContext context) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final trigger = context.findRenderObject() as RenderBox?;
    if (overlay == null || trigger == null) return;
    final triggerCenter = trigger.localToGlobal(
      trigger.size.center(Offset.zero),
      ancestor: overlay,
    );

    final selected = await showGeneralDialog<ScheduleViewMode>(
      context: context,
      barrierLabel: 'Mode',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, _, __) {
        final dockWidth = 164.0;
        final dockHeight = 86.0;
        final left = (triggerCenter.dx - (dockWidth / 2)).clamp(
          12.0,
          overlay.size.width - dockWidth - 12.0,
        );
        final top = math.max(12.0, triggerCenter.dy - 104.0);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: dockWidth,
              height: dockHeight,
              child: _ModeDock(
                current: current,
                onSelected: (mode) => Navigator.of(dialogContext).pop(mode),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (selected != null && selected != current) {
      onChanged(selected);
    }
  }

  IconData _modeIcon(ScheduleViewMode mode) {
    switch (mode) {
      case ScheduleViewMode.timeline:
        return Icons.tune_rounded;
      case ScheduleViewMode.kanban:
        return Icons.view_kanban_outlined;
      case ScheduleViewMode.list:
        return Icons.checklist_rounded;
    }
  }
}

class _ModeDock extends StatelessWidget {
  const _ModeDock({required this.current, required this.onSelected});

  final ScheduleViewMode current;
  final ValueChanged<ScheduleViewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 164,
        height: 86,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 8,
              child: _ModeDockBackdrop(
                selected: current == ScheduleViewMode.timeline,
              ),
            ),
            Positioned(
              left: 56,
              top: 0,
              child: _ModeDockBackdrop(
                selected: current == ScheduleViewMode.kanban,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 8,
              child: _ModeDockBackdrop(
                selected: current == ScheduleViewMode.list,
              ),
            ),
            Positioned(
              left: 6,
              bottom: 13,
              child: _ModeDockButton(
                icon: Icons.tune_rounded,
                selected: current == ScheduleViewMode.timeline,
                onTap: () => onSelected(ScheduleViewMode.timeline),
              ),
            ),
            Positioned(
              left: 62,
              top: 6,
              child: _ModeDockButton(
                icon: Icons.view_kanban_outlined,
                selected: current == ScheduleViewMode.kanban,
                onTap: () => onSelected(ScheduleViewMode.kanban),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 13,
              child: _ModeDockButton(
                icon: Icons.checklist_rounded,
                selected: current == ScheduleViewMode.list,
                onTap: () => onSelected(ScheduleViewMode.list),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeDockBackdrop extends StatelessWidget {
  const _ModeDockBackdrop({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE4EDFF) : const Color(0xFFFCFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? const Color(0xFFC7D8FF) : const Color(0xFFD7E2F2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x180F172A).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

class _ModeDockButton extends StatelessWidget {
  const _ModeDockButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 40,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D5BE3) : const Color(0xFFF2F6FC),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2D5BE3).withValues(alpha: 0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : const Color(0xFF6B84A5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kanban View
// ─────────────────────────────────────────────────────────────────────────────

class _KanbanView extends StatelessWidget {
  const _KanbanView({required this.schedules, required this.onScheduleTap});

  final List<HomeScheduleItem> schedules;
  final ValueChanged<HomeScheduleItem> onScheduleTap;

  @override
  Widget build(BuildContext context) {
    final todo = schedules
        .where((s) => !s.isCompleted && s.priority != SchedulePriority.high)
        .toList();
    final inProgress = schedules
        .where((s) => !s.isCompleted && s.priority == SchedulePriority.high)
        .toList();
    final done = schedules.where((s) => s.isCompleted).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumn(
            title: 'To Do',
            color: const Color(0xFF6F98DC),
            items: todo,
            onTap: onScheduleTap,
          ),
          const SizedBox(width: 10),
          _KanbanColumn(
            title: 'In Progress',
            color: const Color(0xFFF59E0B),
            items: inProgress,
            onTap: onScheduleTap,
          ),
          const SizedBox(width: 10),
          _KanbanColumn(
            title: 'Done',
            color: const Color(0xFF22C55E),
            items: done,
            onTap: onScheduleTap,
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.items,
    required this.onTap,
  });

  final String title;
  final Color color;
  final List<HomeScheduleItem> items;
  final ValueChanged<HomeScheduleItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Cards
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Tidak ada tugas',
                style: TextStyle(
                  color: const Color(0xFF9AADC5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...items.map(
              (item) => _KanbanCard(
                item: item,
                accentColor: color,
                onTap: () => onTap(item),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.item,
    required this.accentColor,
    required this.onTap,
  });

  final HomeScheduleItem item;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1EAF5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10264A).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF1A2B47),
                fontWeight: FontWeight.w700,
                fontSize: 13,
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            if (item.description.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8097B4), fontSize: 11),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: const Color(0xFF9AADC5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_fmt(item.startAt)} - ${_fmt(item.endAt)}',
                  style: const TextStyle(
                    color: Color(0xFF9AADC5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task List View
// ─────────────────────────────────────────────────────────────────────────────

class _TaskListView extends StatelessWidget {
  const _TaskListView({required this.schedules, required this.onScheduleTap});

  final List<HomeScheduleItem> schedules;
  final ValueChanged<HomeScheduleItem> onScheduleTap;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32),
        child: Center(
          child: Text(
            'Tidak ada jadwal hari ini',
            style: TextStyle(color: Color(0xFF9AADC5), fontSize: 14),
          ),
        ),
      );
    }

    final sorted = [...schedules]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return Column(
      children: sorted
          .map(
            (item) =>
                _TaskListTile(item: item, onTap: () => onScheduleTap(item)),
          )
          .toList(),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({required this.item, required this.onTap});

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
            // Checkbox visual
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
            // Content
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: const Color(0xFF9AADC5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_fmt(item.startAt)} - ${_fmt(item.endAt)}',
                        style: const TextStyle(
                          color: Color(0xFF9AADC5),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.location?.trim().isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: const Color(0xFF9AADC5),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            item.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF9AADC5),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Priority chip
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayLabel = _dayLabel(date.weekday);
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? const Color(0xFF4D4BE4) : const Color(0xFFEFF3F8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4D4BE4).withValues(alpha: 0.26),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFE6EAFE)
                    : const Color(0xFF9AA8BE),
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF8798B4),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(int weekday) {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[(weekday - 1) % 7];
  }
}

class _HourGrid extends StatelessWidget {
  const _HourGrid({
    required this.timeColumnWidth,
    required this.canvasLeft,
    required this.hourHeight,
    required this.topPadding,
  });

  final double timeColumnWidth;
  final double canvasLeft;
  final double hourHeight;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: canvasLeft - 9,
          top: topPadding,
          bottom: 24,
          child: Container(width: 1, color: const Color(0xFFD6E0EE)),
        ),
        for (var hour = 0; hour < 24; hour++) ...[
          Positioned(
            left: 0,
            top: topPadding + (hour * hourHeight) - 9,
            width: timeColumnWidth,
            child: Text(
              _hourLabel(hour),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF95A7C0),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          Positioned(
            left: canvasLeft,
            right: 0,
            top: topPadding + (hour * hourHeight),
            child: Container(height: 1, color: const Color(0xFFE2E9F3)),
          ),
          if (hour < 23)
            Positioned(
              left: canvasLeft,
              right: 0,
              top: topPadding + (hour * hourHeight) + (hourHeight / 2),
              child: Container(height: 1, color: const Color(0xFFF0F4F9)),
            ),
        ],
      ],
    );
  }

  static String _hourLabel(int hour) => '${hour.toString().padLeft(2, '0')}:00';
}

class _TapCalendarSurface extends StatelessWidget {
  const _TapCalendarSurface({
    required this.selectedDate,
    required this.canvasWidth,
    required this.hourHeight,
    required this.onCreateScheduleAt,
  });

  final DateTime selectedDate;
  final double canvasWidth;
  final double hourHeight;
  final ValueChanged<DateTime> onCreateScheduleAt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: const Color(0x1A4D4BE4),
        highlightColor: const Color(0x0D4D4BE4),
        onTapDown: (details) {
          final local = details.localPosition;
          final totalMinutes = ((local.dy / hourHeight) * 60).round();
          final clampedMinutes = totalMinutes.clamp(0, 23 * 60 + 59);
          final snappedMinutes = ((clampedMinutes / 30).round() * 30).clamp(
            0,
            23 * 60 + 30,
          );
          final hour = snappedMinutes ~/ 60;
          final minute = snappedMinutes % 60;
          onCreateScheduleAt(
            DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              hour,
              minute,
            ),
          );
        },
        child: SizedBox(width: canvasWidth),
      ),
    );
  }
}

class _PositionedScheduleCard extends StatelessWidget {
  const _PositionedScheduleCard({
    required this.item,
    required this.topPadding,
    required this.timeColumnWidth,
    required this.canvasLeft,
    required this.canvasWidth,
    required this.hourHeight,
    required this.onTap,
  });

  final HomeScheduleItem item;
  final double topPadding;
  final double timeColumnWidth;
  final double canvasLeft;
  final double canvasWidth;
  final double hourHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final startMinutes = (item.startAt.hour * 60) + item.startAt.minute;
    final durationMinutes = item.endAt.difference(item.startAt).inMinutes;
    final top = topPadding + ((startMinutes / 60) * hourHeight);
    final height = math.max(42.0, (durationMinutes / 60) * hourHeight);

    return Positioned(
      left: canvasLeft + 4,
      width: math.max(0, canvasWidth - 8),
      top: top,
      height: height,
      child: _ScheduleCanvasCard(item: item, onTap: onTap),
    );
  }
}

class _PositionedQuickCreateComposer extends StatelessWidget {
  const _PositionedQuickCreateComposer({
    required this.startAt,
    required this.topPadding,
    required this.canvasLeft,
    required this.canvasWidth,
    required this.hourHeight,
    required this.titleController,
    required this.titleFocusNode,
    required this.onDismiss,
    required this.onSave,
  });

  final DateTime startAt;
  final double topPadding;
  final double canvasLeft;
  final double canvasWidth;
  final double hourHeight;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final VoidCallback onDismiss;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final startMinutes = (startAt.hour * 60) + startAt.minute;
    final rawTop = topPadding + ((startMinutes / 60) * hourHeight);
    final safeWidth = canvasWidth <= 0
        ? 0.0
        : math
              .max(
                0.0,
                math.min(math.max(220.0, canvasWidth * 0.84), canvasWidth - 8),
              )
              .toDouble();
    final isCompact = safeWidth < 252;
    final composerHeight = isCompact ? 182.0 : 160.0;
    final maxTop = topPadding + (hourHeight * 24) - composerHeight - 6;
    final safeTop = rawTop
        .clamp(topPadding + 2, math.max(topPadding + 2, maxTop))
        .toDouble();

    return Positioned(
      left: canvasLeft + 6,
      top: safeTop,
      width: safeWidth,
      height: composerHeight,
      child: _QuickCreateComposerCard(
        startAt: startAt,
        titleController: titleController,
        titleFocusNode: titleFocusNode,
        isCompact: isCompact,
        onDismiss: onDismiss,
        onSave: onSave,
      ),
    );
  }
}

class _QuickCreateComposerCard extends StatelessWidget {
  const _QuickCreateComposerCard({
    required this.startAt,
    required this.titleController,
    required this.titleFocusNode,
    required this.isCompact,
    required this.onDismiss,
    required this.onSave,
  });

  final DateTime startAt;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final bool isCompact;
  final VoidCallback onDismiss;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final endAt = startAt.add(const Duration(hours: 1));
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 10, 12, isCompact ? 8 : 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFDFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE5F1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A2B47).withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.drag_handle_rounded,
                  size: 18,
                  color: Color(0xFF7B8CA7),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF66778F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: titleController,
              focusNode: titleFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSave(),
              style: TextStyle(
                color: Color(0xFF31445F),
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 14 : 15,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Add title',
                hintStyle: TextStyle(
                  color: Color(0xFF8D9DB5),
                  fontWeight: FontWeight.w500,
                  fontSize: isCompact ? 14 : 15,
                ),
                contentPadding: const EdgeInsets.only(bottom: 6),
                border: InputBorder.none,
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4DDEA)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 8 : 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: Color(0xFF6F8098),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _quickCreateDateRangeText(startAt, endAt),
                        maxLines: isCompact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF40536F),
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 11 : 11.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Time zone | Does not repeat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF8C9DB3),
                          fontWeight: FontWeight.w500,
                          fontSize: isCompact ? 10 : 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 6 : 10),
            Row(
              children: [
                const Spacer(),
                FilledButton(
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    minimumSize: Size(0, isCompact ? 30 : 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isCompact ? 11.5 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _quickCreateDateRangeText(DateTime startAt, DateTime endAt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekday = weekdays[(startAt.weekday - 1) % 7];
    final month = months[startAt.month - 1];
    return '$weekday, $month ${startAt.day}  ${_formatTime(startAt)} - ${_formatTime(endAt)}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute$suffix';
  }
}

class _ScheduleCanvasCard extends StatelessWidget {
  const _ScheduleCanvasCard({required this.item, required this.onTap});

  final HomeScheduleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHighlighted =
        item.priority == SchedulePriority.high && !item.isCompleted;
    final titleColor = item.isCompleted
        ? const Color(0xFF7F8EA6)
        : (isHighlighted ? const Color(0xFF2563EB) : const Color(0xFF1A2B47));
    final subColor = item.isCompleted
        ? const Color(0xFF95A3B8)
        : (isHighlighted ? const Color(0xFF4D79D8) : const Color(0xFF798CA8));

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.isCompleted
              ? const Color(0xFFF0F4FA)
              : (isHighlighted
                    ? const Color(0xFFE7EEFB)
                    : const Color(0xFFFFFFFF)),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFD8E3F4)
                : const Color(0xFFE1E7F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10264A).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isTight = availableHeight < 52;
            final isCompact = availableHeight < 66;
            final bodyText = item.location?.trim().isNotEmpty == true
                ? item.location!
                : item.description;
            final subtitleLines = isCompact ? 1 : 2;
            final horizontalPadding = isCompact ? 7.0 : 8.0;
            final verticalPadding = isCompact ? 5.0 : 6.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                verticalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFBFCBDC),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: isTight
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isCompact ? 12.5 : 13,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (bodyText.trim().isNotEmpty) ...[
                                SizedBox(height: isCompact ? 1 : 2),
                                Flexible(
                                  child: Text(
                                    bodyText,
                                    maxLines: subtitleLines,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: subColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: isCompact ? 10 : 10.5,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
