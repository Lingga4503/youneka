import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

class HomeScheduleTimelineSection extends StatelessWidget {
  const HomeScheduleTimelineSection({
    super.key,
    required this.selectedDate,
    required this.schedules,
    required this.onSelectDate,
    required this.onCreateScheduleAt,
    required this.onScheduleTap,
    required this.onToggleCompleted,
    required this.onEditSchedule,
    required this.onDeleteSchedule,
  });

  final DateTime selectedDate;
  final List<HomeScheduleItem> schedules;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<DateTime> onCreateScheduleAt;
  final ValueChanged<HomeScheduleItem> onScheduleTap;
  final ValueChanged<HomeScheduleItem> onToggleCompleted;
  final ValueChanged<HomeScheduleItem> onEditSchedule;
  final ValueChanged<HomeScheduleItem> onDeleteSchedule;

  static const double _hourHeight = 58;
  static const double _timeColumnWidth = 40;
  static const double _timelineGap = 8;
  static const double _canvasTopPadding = 8;
  static const double _canvasBottomPadding = 18;

  @override
  Widget build(BuildContext context) {
    final totalHeight =
        (_hourHeight * 24) + _canvasTopPadding + _canvasBottomPadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeekDayStrip(selectedDate: selectedDate, onSelectDate: onSelectDate),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final canvasLeft = _timeColumnWidth + _timelineGap;
            final canvasWidth = math.max(
              0.0,
              constraints.maxWidth - canvasLeft,
            );
            return SizedBox(
              height: totalHeight,
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
                      onToggleDone: () => onToggleCompleted(item),
                      onEdit: () => onEditSchedule(item),
                      onDelete: () => onDeleteSchedule(item),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeekDayStrip extends StatelessWidget {
  const _WeekDayStrip({required this.selectedDate, required this.onSelectDate});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final selected = DateUtils.dateOnly(selectedDate);
    final startOfWeek = selected.subtract(Duration(days: selected.weekday - 1));
    final days = List<DateTime>.generate(
      7,
      (index) => DateUtils.dateOnly(startOfWeek.add(Duration(days: index))),
    );

    return SizedBox(
      height: 68,
      child: ListView.separated(
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
    );
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
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
  });

  final HomeScheduleItem item;
  final double topPadding;
  final double timeColumnWidth;
  final double canvasLeft;
  final double canvasWidth;
  final double hourHeight;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
      child: _ScheduleCanvasCard(
        item: item,
        onTap: onTap,
        onToggleDone: onToggleDone,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}

class _ScheduleCanvasCard extends StatelessWidget {
  const _ScheduleCanvasCard({
    required this.item,
    required this.onTap,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
  });

  final HomeScheduleItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.location?.trim().isNotEmpty == true
                        ? item.location!
                        : item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 10.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 20,
                    height: 20,
                  ),
                  tooltip: item.isCompleted
                      ? 'Batalkan selesai'
                      : 'Tandai selesai',
                  onPressed: onToggleDone,
                  icon: Icon(
                    item.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 15,
                    color: item.isCompleted
                        ? const Color(0xFF2B67D9)
                        : const Color(0xFFA2B4CE),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  tooltip: 'Aksi jadwal',
                  constraints: const BoxConstraints.tightFor(
                    width: 20,
                    height: 20,
                  ),
                  icon: const Icon(Icons.more_horiz_rounded, size: 15),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
