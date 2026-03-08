import 'package:flutter/material.dart';

import '../../domain/models/home_models.dart';

class HomeNotificationsPage extends StatefulWidget {
  const HomeNotificationsPage({super.key, required this.initialItems});

  final List<HomeNotificationItem> initialItems;

  @override
  State<HomeNotificationsPage> createState() => _HomeNotificationsPageState();
}

class _HomeNotificationsPageState extends State<HomeNotificationsPage> {
  late List<HomeNotificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.initialItems];
  }

  void _markAllRead() {
    setState(() {
      _items = _items.map((item) => item.copyWith(isRead: true)).toList();
    });
  }

  void _clearRead() {
    setState(() {
      _items = _items.where((item) => !item.isRead).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        Navigator.of(context).pop(_items);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          title: const Text('Notifikasi'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_items),
          ),
          actions: [
            IconButton(
              tooltip: 'Tandai semua dibaca',
              onPressed: _items.isEmpty ? null : _markAllRead,
              icon: const Icon(Icons.done_all_rounded),
            ),
            IconButton(
              tooltip: 'Hapus yang dibaca',
              onPressed: _items.any((item) => item.isRead) ? _clearRead : null,
              icon: const Icon(Icons.cleaning_services_outlined),
            ),
          ],
        ),
        body: _items.isEmpty
            ? const Center(
                child: Text(
                  'Belum ada notifikasi.',
                  style: TextStyle(
                    color: Color(0xFF7B90AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final mutedColor = item.isRead
                      ? const Color(0xFF8EA1BC)
                      : const Color(0xFF243C62);
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _items[index] = item.copyWith(isRead: true);
                      });
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: item.isRead
                            ? const Color(0xFFEAF0FA)
                            : const Color(0xFFDDE8F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.isRead
                              ? const Color(0xFFD5E0F1)
                              : const Color(0xFFC6D7F1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? const Color(0xFFAABCD6)
                                    : const Color(0xFF2B67D9),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: const TextStyle(
                                      color: Color(0xFF6A7FA3),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDateTime(item.createdAt),
                                    style: const TextStyle(
                                      color: Color(0xFF8EA1BC),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}
