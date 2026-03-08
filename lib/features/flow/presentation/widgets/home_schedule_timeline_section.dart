import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

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
        _WeekDayStrip(
          selectedDate: selectedDate,
          onSelectDate: onSelectDate,
          onShiftWeek: onShiftWeek,
        ),
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
            );
          },
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
