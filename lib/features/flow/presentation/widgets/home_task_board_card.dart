import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/home_models.dart';

const Color _boardInk = Color(0xFF3A3128);
const Color _boardMuted = Color(0xFF8D8271);
const Color _boardAccent = Color(0xFF8B7FD6);

/// Always-visible task board card shown on the immersive home scene.
class HomeTaskBoardCard extends StatelessWidget {
  const HomeTaskBoardCard({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    required this.onAddTap,
    required this.onToggleComplete,
  });

  final List<HomeScheduleItem> tasks;
  final ValueChanged<HomeScheduleItem> onTaskTap;
  final VoidCallback onAddTap;
  final ValueChanged<HomeScheduleItem> onToggleComplete;

  static const int _maxVisible = 5;

  @override
  Widget build(BuildContext context) {
    final incomplete = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) {
        if (a.startAt == null && b.startAt == null) return 0;
        if (a.startAt == null) return 1;
        if (b.startAt == null) return -1;
        return a.startAt!.compareTo(b.startAt!);
      });
    final completed = tasks.where((t) => t.isCompleted).toList();
    final visible = [...incomplete, ...completed].take(_maxVisible).toList();
    final now = DateTime.now();
    final dateLabel =
        '${_monthName(now.month)} ${now.day}, ${now.year}';

    return Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Tugas Hari Ini',
                  style: GoogleFonts.plusJakartaSans(
                    color: _boardInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  dateLabel,
                  style: GoogleFonts.plusJakartaSans(
                    color: _boardMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text(
                'Belum ada tugas.',
                style: GoogleFonts.plusJakartaSans(
                  color: _boardMuted,
                  fontSize: 13,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  return _BoardTaskRow(
                    item: visible[index],
                    onTap: () => onTaskTap(visible[index]),
                    onToggle: () => onToggleComplete(visible[index]),
                  );
                },
              ),
            ),
          InkWell(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            onTap: onAddTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, color: _boardAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tambah tugas',
                    style: GoogleFonts.plusJakartaSans(
                      color: _boardAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}

class _BoardTaskRow extends StatelessWidget {
  const _BoardTaskRow({
    required this.item,
    required this.onTap,
    required this.onToggle,
  });

  final HomeScheduleItem item;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: item.isCompleted ? _boardAccent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _boardAccent, width: 2),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: item.isCompleted ? _boardMuted : _boardInk,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.edit_rounded, size: 15),
              color: _boardMuted,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
          ],
        ),
      ),
    );
  }
}
