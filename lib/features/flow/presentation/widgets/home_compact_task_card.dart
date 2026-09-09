import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

/// Compact corner card showing the next upcoming task. Tap to expand into
/// the full task list bottom sheet.
class HomeCompactTaskCard extends StatelessWidget {
  const HomeCompactTaskCard({
    super.key,
    required this.tasks,
    required this.onTap,
    required this.onAddTap,
  });

  final List<HomeScheduleItem> tasks;
  final VoidCallback onTap;
  final VoidCallback onAddTap;

  HomeScheduleItem? get _nextTask {
    final incomplete = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) {
        if (a.startAt == null && b.startAt == null) return 0;
        if (a.startAt == null) return 1;
        if (b.startAt == null) return -1;
        return a.startAt!.compareTo(b.startAt!);
      });
    return incomplete.isEmpty ? null : incomplete.first;
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextTask;
    final remaining = tasks.where((t) => !t.isCompleted).length;

    return Material(
      color: const Color(0x33101828),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x44FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.checklist_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              next?.title ?? 'Tidak ada tugas',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (remaining > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$remaining tersisa',
                                style: const TextStyle(
                                  color: Color(0xFFD8DEEE),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 28,
              color: const Color(0x33FFFFFF),
            ),
            InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(18),
              ),
              onTap: onAddTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
