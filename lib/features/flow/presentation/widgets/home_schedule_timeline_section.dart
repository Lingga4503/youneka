import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

class HomeScheduleTimelineSection extends StatelessWidget {
  const HomeScheduleTimelineSection({
    super.key,
    required this.dateLabel,
    required this.schedules,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickDay,
    required this.onAddSchedule,
    required this.onScheduleTap,
    required this.onToggleCompleted,
    required this.onEditSchedule,
    required this.onDeleteSchedule,
  });

  final String dateLabel;
  final List<HomeScheduleItem> schedules;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDay;
  final VoidCallback onAddSchedule;
  final ValueChanged<HomeScheduleItem> onScheduleTap;
  final ValueChanged<HomeScheduleItem> onToggleCompleted;
  final ValueChanged<HomeScheduleItem> onEditSchedule;
  final ValueChanged<HomeScheduleItem> onDeleteSchedule;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 200) onPreviousDay();
        if (velocity < -200) onNextDay();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's Schedule",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF152642),
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
              ),
              _HeaderIconButton(
                tooltip: 'Tambah jadwal',
                onPressed: onAddSchedule,
                icon: Icons.add_circle_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _HeaderIconButton(
                tooltip: 'Hari sebelumnya',
                onPressed: onPreviousDay,
                icon: Icons.chevron_left_rounded,
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onPickDay,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      dateLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8B9DB8),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              _HeaderIconButton(
                tooltip: 'Hari berikutnya',
                onPressed: onNextDay,
                icon: Icons.chevron_right_rounded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (schedules.isEmpty)
            _EmptyScheduleState(onAddSchedule: onAddSchedule)
          else
            Stack(
              children: [
                Positioned(
                  left: 78,
                  top: 14,
                  bottom: 12,
                  child: Container(width: 1, color: const Color(0xFFD2DBE7)),
                ),
                Column(
                  children: List.generate(schedules.length, (index) {
                    final item = schedules[index];
                    final isPrimary =
                        item.priority == SchedulePriority.high &&
                        !item.isCompleted;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == schedules.length - 1 ? 0 : 12,
                      ),
                      child: _TimelineRow(
                        item: item,
                        isPrimary: isPrimary,
                        onTap: () => onScheduleTap(item),
                        onToggleDone: () => onToggleCompleted(item),
                        onEdit: () => onEditSchedule(item),
                        onDelete: () => onDeleteSchedule(item),
                      ),
                    );
                  }),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.isPrimary,
    required this.onTap,
    required this.onToggleDone,
    required this.onEdit,
    required this.onDelete,
  });

  final HomeScheduleItem item;
  final bool isPrimary;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeColor = isPrimary
        ? const Color(0xFF7B8FB0)
        : const Color(0xFF95A7C0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _formatTime(item.startAt),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: timeColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 14),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isPrimary
                    ? const Color(0xFFE6EEFC)
                    : const Color(0xFFBFCBDC),
                shape: BoxShape.circle,
                border: isPrimary
                    ? Border.all(color: const Color(0xFF2563EB), width: 2)
                    : null,
              ),
            ),
          ),
        ),
        Expanded(
          child: _ScheduleCard(
            item: item,
            onTap: onTap,
            onToggleDone: onToggleDone,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: item.isCompleted
              ? const Color(0xFFF0F4FA)
              : (isHighlighted
                    ? const Color(0xFFE7EEFB)
                    : const Color(0xFFFFFFFF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFD8E3F4)
                : const Color(0xFFE1E7F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10264A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighlighted)
              Container(
                width: 4,
                height: 52,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (item.priority == SchedulePriority.high)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7D8F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'HIGH',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (item.location != null && item.location!.trim().isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Color(0xFF6E87AA),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        fontStyle:
                            item.description.toLowerCase().contains('lunch')
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: item.isCompleted
                      ? 'Batalkan selesai'
                      : 'Tandai selesai',
                  onPressed: onToggleDone,
                  icon: Icon(
                    item.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: item.isCompleted
                        ? const Color(0xFF2B67D9)
                        : const Color(0xFFA2B4CE),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Aksi jadwal',
                  icon: const Icon(Icons.more_horiz_rounded),
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

class _EmptyScheduleState extends StatelessWidget {
  const _EmptyScheduleState({required this.onAddSchedule});

  final VoidCallback onAddSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD2DDEF)),
      ),
      child: Column(
        children: [
          const Text(
            'Belum ada schedule untuk hari ini.',
            style: TextStyle(
              color: Color(0xFF6F84A6),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAddSchedule,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah schedule'),
          ),
        ],
      ),
    );
  }
}
