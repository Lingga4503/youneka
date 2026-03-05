import 'package:flutter/material.dart';

const Color _shellSurface = Color(0xFFF0F6FD);
const Color _shellInk = Color(0xFF16233A);
const Color _shellMuted = Color(0xFF7187A6);
const Color _shellAccent = Color(0xFF6F98DC);
const Color _shellAccentDeep = Color(0xFF274976);
const Color _shellSoft = Color(0xFFDDE8F6);
const Color _shellGold = Color(0xFFA4C1E8);

class YounekaHomeShell extends StatefulWidget {
  const YounekaHomeShell({
    super.key,
    required this.pages,
    required this.onSidebarAction,
    required this.onMentorTap,
    this.initialIndex = 0,
  });

  final List<Widget> pages;
  final Future<void> Function(String action) onSidebarAction;
  final VoidCallback onMentorTap;
  final int initialIndex;

  @override
  State<YounekaHomeShell> createState() => _YounekaHomeShellState();
}

class _YounekaHomeShellState extends State<YounekaHomeShell> {
  late int _selectedIndex;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Beranda',
      icon: Icons.home_rounded,
    ),
    _ShellDestination(
      label: 'Andrew',
      icon: Icons.auto_awesome_rounded,
    ),
    _ShellDestination(
      label: 'Coach',
      icon: Icons.self_improvement_rounded,
    ),
    _ShellDestination(
      label: 'Progres',
      icon: Icons.bar_chart_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex
        .clamp(0, widget.pages.length - 1)
        .toInt();
  }

  Future<void> _openQuickActions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _QuickActionSheet(
          onMentorTap: () {
            Navigator.pop(sheetContext);
            widget.onMentorTap();
          },
          onActionTap: (action) async {
            Navigator.pop(sheetContext);
            await widget.onSidebarAction(action);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _shellSurface,
      body: IndexedStack(index: _selectedIndex, children: widget.pages),
      bottomNavigationBar: SizedBox(
        height: 112 + bottomInset,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, 14 + bottomInset),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                top: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ClipPath(
                    clipper: const _BottomBarClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_shellSurface, Color(0xFFE5EFFB)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _BottomNavItem(
                                destination: _destinations[0],
                                selected: _selectedIndex == 0,
                                onTap: () => setState(() => _selectedIndex = 0),
                              ),
                            ),
                            Expanded(
                              child: _BottomNavItem(
                                destination: _destinations[1],
                                selected: _selectedIndex == 1,
                                onTap: () => setState(() => _selectedIndex = 1),
                              ),
                            ),
                            const SizedBox(width: 86),
                            Expanded(
                              child: _BottomNavItem(
                                destination: _destinations[2],
                                selected: _selectedIndex == 2,
                                onTap: () => setState(() => _selectedIndex = 2),
                              ),
                            ),
                            Expanded(
                              child: _BottomNavItem(
                                destination: _destinations[3],
                                selected: _selectedIndex == 3,
                                onTap: () => setState(() => _selectedIndex = 3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -12,
                child: GestureDetector(
                  onTap: _openQuickActions,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_shellAccent, _shellAccentDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: _shellSurface, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: _shellAccent.withValues(alpha: 0.34),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: _shellSurface,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _shellAccent : _shellMuted;
    return Tooltip(
      message: destination.label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        highlightShape: BoxShape.circle,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destination.icon, color: color, size: selected ? 30 : 28),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: selected ? 18 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 1 : 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionSheet extends StatelessWidget {
  const _QuickActionSheet({
    required this.onMentorTap,
    required this.onActionTap,
  });

  final VoidCallback onMentorTap;
  final Future<void> Function(String action) onActionTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _shellSurface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                blurRadius: 36,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                color: _shellGold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAF2FD), Color(0xFFF6FAFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _shellGold),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _shellAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: _shellAccentDeep,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Mentor Andrew',
                              style: TextStyle(
                                color: _shellInk,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Buka mentor chat untuk pecah tugas dan mulai fokus.',
                              style: TextStyle(
                                color: _shellMuted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: onMentorTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: _shellAccentDeep,
                          foregroundColor: _shellSurface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        child: const Text('Buka'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Quick actions',
                  style: TextStyle(
                    color: _shellInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _QuickActionCard(
                      icon: Icons.upload_file_rounded,
                      title: 'Import',
                      subtitle: 'Masukkan backup data',
                      color: _shellAccentDeep,
                      onTap: () => onActionTap('import'),
                    ),
                    _QuickActionCard(
                      icon: Icons.download_rounded,
                      title: 'Export',
                      subtitle: 'Simpan backup terbaru',
                      color: _shellAccent,
                      onTap: () => onActionTap('export'),
                    ),
                    _QuickActionCard(
                      icon: Icons.language_rounded,
                      title: 'Bahasa',
                      subtitle: 'Ganti locale aplikasi',
                      color: _shellGold,
                      onTap: () => onActionTap('language'),
                    ),
                    _QuickActionCard(
                      icon: Icons.settings_rounded,
                      title: 'Pengaturan',
                      subtitle: 'Atur preferensi aplikasi',
                      color: _shellMuted,
                      onTap: () => onActionTap('settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: _shellSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _shellGold),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _shellInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A8599),
                        fontSize: 12,
                        height: 1.25,
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
  }
}

class _BottomBarClipper extends CustomClipper<Path> {
  const _BottomBarClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final notchHalfWidth = size.width * 0.19;
    const notchDepth = 32.0;
    const corner = 26.0;

    path.moveTo(0, corner);
    path.quadraticBezierTo(0, 0, corner, 0);
    path.lineTo(size.width / 2 - notchHalfWidth, 0);
    path.cubicTo(
      size.width / 2 - notchHalfWidth * 0.68,
      0,
      size.width / 2 - notchHalfWidth * 0.48,
      notchDepth,
      size.width / 2,
      notchDepth,
    );
    path.cubicTo(
      size.width / 2 + notchHalfWidth * 0.48,
      notchDepth,
      size.width / 2 + notchHalfWidth * 0.68,
      0,
      size.width / 2 + notchHalfWidth,
      0,
    );
    path.lineTo(size.width - corner, 0);
    path.quadraticBezierTo(size.width, 0, size.width, corner);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
