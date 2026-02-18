import 'package:flutter/material.dart';

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
  static const double _railWidth = 74;

  late int _selectedIndex;
  double _panelVisibleWidth = 0;
  bool _isDraggingSidebar = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _panelVisibleWidth = 0;
  }

  void _onSidebarDragStart(DragStartDetails _) {
    _isDraggingSidebar = true;
  }

  void _onSidebarDragUpdate(DragUpdateDetails details, double maxPanelWidth) {
    setState(() {
      // Geser kiri: panel kanan terbuka mengikuti geseran user.
      _panelVisibleWidth = (_panelVisibleWidth - details.delta.dx).clamp(
        0.0,
        maxPanelWidth,
      );
    });
  }

  void _onSidebarDragEnd(DragEndDetails details, double maxPanelWidth) {
    _isDraggingSidebar = false;
    final velocityX = details.primaryVelocity ?? 0;
    final snapOpenWidth = maxPanelWidth;
    final midpoint = snapOpenWidth * 0.45;
    setState(() {
      if (velocityX < -180) {
        _panelVisibleWidth = snapOpenWidth;
      } else if (velocityX > 180) {
        _panelVisibleWidth = 0;
      } else {
        _panelVisibleWidth = _panelVisibleWidth >= midpoint ? snapOpenWidth : 0;
      }
    });
  }

  void _toggleSidebarPanel(double maxPanelWidth) {
    final snapOpenWidth = maxPanelWidth;
    setState(() {
      _panelVisibleWidth = _panelVisibleWidth <= 1 ? snapOpenWidth : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxPanelWidth = (constraints.maxWidth - _railWidth).clamp(
            0.0,
            double.infinity,
          ).toDouble();
          final settledPanelWidth = _panelVisibleWidth.clamp(
            0.0,
            maxPanelWidth,
          );
          final isPanelOpen = settledPanelWidth > 1;

          return Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: widget.pages,
                ),
              ),
              AnimatedPositioned(
                duration: _isDraggingSidebar
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _onSidebarDragStart,
                  onHorizontalDragUpdate: (details) =>
                      _onSidebarDragUpdate(details, maxPanelWidth),
                  onHorizontalDragEnd: (details) =>
                      _onSidebarDragEnd(details, maxPanelWidth),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _YounekaRightSidebar(
                        selectedIndex: _selectedIndex,
                        isPanelOpen: isPanelOpen,
                        onSelect: (index) =>
                            setState(() => _selectedIndex = index),
                        onActionTap: widget.onSidebarAction,
                        onMentorTap: widget.onMentorTap,
                        onTogglePanel: () => _toggleSidebarPanel(maxPanelWidth),
                      ),
                      AnimatedContainer(
                        duration: _isDraggingSidebar
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: settledPanelWidth,
                        height: double.infinity,
                        child: ClipRect(
                          child: settledPanelWidth <= 0
                              ? const SizedBox.shrink()
                              : _SidebarSlidePanel(
                                  onActionTap: widget.onSidebarAction,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SidebarSlidePanel extends StatelessWidget {
  const _SidebarSlidePanel({required this.onActionTap});

  final Future<void> Function(String action) onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FD),
        border: Border(
          left: BorderSide(color: const Color(0xFFD6E0F3)),
          right: BorderSide(color: const Color(0xFFD6E0F3)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A3D63).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: SafeArea(
        left: false,
        right: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Template Rencana',
                style: TextStyle(
                  color: Color(0xFF1A2A46),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tarik panel ini untuk akses cepat template dan data offline.',
                style: TextStyle(
                  color: const Color(0xFF3D4F73).withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const _PanelTemplateCard(
                icon: Icons.favorite_rounded,
                title: 'Kebiasaan sehat',
                subtitle: 'Olahraga ringan, minum air, dan jeda peregangan.',
                accent: Color(0xFF20A56E),
              ),
              const SizedBox(height: 8),
              const _PanelTemplateCard(
                icon: Icons.work_rounded,
                title: 'Deep work',
                subtitle: 'Blok fokus tanpa distraksi untuk kerja inti.',
                accent: Color(0xFF4A6EAF),
              ),
              const SizedBox(height: 8),
              const _PanelTemplateCard(
                icon: Icons.school_rounded,
                title: 'Belajar terarah',
                subtitle: 'Sesi belajar + review agar materi lebih melekat.',
                accent: Color(0xFF6C58D9),
              ),
              const SizedBox(height: 14),
              const Text(
                'Data offline',
                style: TextStyle(
                  color: Color(0xFF1A2A46),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PanelActionChip(
                    icon: Icons.upload_file_rounded,
                    label: 'Import',
                    onTap: () => onActionTap('import'),
                  ),
                  _PanelActionChip(
                    icon: Icons.download_rounded,
                    label: 'Export',
                    onTap: () => onActionTap('export'),
                  ),
                  _PanelActionChip(
                    icon: Icons.language_rounded,
                    label: 'Bahasa',
                    onTap: () => onActionTap('language'),
                  ),
                  _PanelActionChip(
                    icon: Icons.settings_rounded,
                    label: 'Pengaturan',
                    onTap: () => onActionTap('settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YounekaRightSidebar extends StatelessWidget {
  const _YounekaRightSidebar({
    required this.selectedIndex,
    required this.isPanelOpen,
    required this.onSelect,
    required this.onActionTap,
    required this.onMentorTap,
    required this.onTogglePanel,
  });

  final int selectedIndex;
  final bool isPanelOpen;
  final ValueChanged<int> onSelect;
  final Future<void> Function(String action) onActionTap;
  final VoidCallback onMentorTap;
  final VoidCallback onTogglePanel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      decoration: const BoxDecoration(color: Color(0xFF4A6EAF)),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              tooltip: 'Menu',
              onSelected: (value) {
                onActionTap(value);
              },
              color: Colors.white,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'settings', child: Text('Pengaturan')),
                PopupMenuItem(value: 'import', child: Text('Import data')),
                PopupMenuItem(value: 'export', child: Text('Export data')),
                PopupMenuItem(value: 'language', child: Text('Ganti bahasa')),
              ],
              child: const SizedBox(
                width: 56,
                height: 44,
                child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
              ),
            ),
            Container(
              width: 36,
              height: 1,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            const _RailMissionText(),
            const SizedBox(height: 8),
            IconButton(
              onPressed: onTogglePanel,
              icon: Icon(
                isPanelOpen
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 34,
              ),
            ),
            const Spacer(),
            _RailNavButton(
              icon: Icons.timer_rounded,
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            _RailNavButton(
              icon: Icons.self_improvement_rounded,
              selected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
            _RailNavButton(
              icon: Icons.content_copy_rounded,
              selected: selectedIndex == 3,
              onTap: () => onSelect(3),
            ),
            _RailNavButton(
              icon: Icons.mail_outline_rounded,
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            const SizedBox(height: 14),
            Container(
              width: 36,
              height: 1,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            _RailNavButton(
              icon: Icons.chat_bubble_outline_rounded,
              selected: false,
              onTap: onMentorTap,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _RailMissionText extends StatelessWidget {
  const _RailMissionText();

  @override
  Widget build(BuildContext context) {
    const letters = ['M', 'I', 'S', 'S', 'I', 'O', 'N'];
    return Column(
      children: [
        for (final l in letters)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              l,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

class _RailNavButton extends StatelessWidget {
  const _RailNavButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 42,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.92),
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _PanelActionChip extends StatelessWidget {
  const _PanelActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD5DFF2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4A6EAF)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2B4678),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTemplateCard extends StatelessWidget {
  const _PanelTemplateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E3F6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A2A46),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF5A6C91),
                    fontSize: 10.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
