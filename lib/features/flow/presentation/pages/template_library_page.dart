import 'package:flutter/material.dart';

import '../../../../core/services/plan_template_bridge.dart';
import '../../data/template_library_storage.dart';

const _surface = Color(0xFFF2F6FB);
const _card = Color(0xFFFAFDFF);
const _ink = Color(0xFF15213A);
const _muted = Color(0xFF7F92AF);
const _primary = Color(0xFF245FEA);
const _soft = Color(0xFFE8F0FF);
const _border = Color(0xFFDCE6F3);

typedef UseTemplateCallback =
    Future<void> Function(PlanTemplatePreset preset, {bool replaceCurrentDay});

class TemplateLibraryPage extends StatefulWidget {
  const TemplateLibraryPage({super.key, required this.onUseTemplate});

  final UseTemplateCallback onUseTemplate;

  @override
  State<TemplateLibraryPage> createState() => _TemplateLibraryPageState();
}

class _TemplateLibraryPageState extends State<TemplateLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PlanTemplatePreset> _customTemplates = const <PlanTemplatePreset>[];
  bool _isLoading = true;
  String _query = '';

  PlanTemplatePreset get _featured => PlanTemplateBridge.deepWork;

  List<PlanTemplatePreset> get _library {
    final items = <PlanTemplatePreset>[
      for (final preset in PlanTemplateBridge.presets)
        if (preset.id != _featured.id) preset,
      ..._customTemplates,
    ];
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) => _matches(item, q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTemplates();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_query == _searchController.text) return;
    setState(() {
      _query = _searchController.text;
    });
  }

  Future<void> _loadTemplates() async {
    final items = await TemplateLibraryStorage.loadCustomTemplates();
    if (!mounted) return;
    setState(() {
      _customTemplates = items;
      _isLoading = false;
    });
  }

  Future<void> _persistTemplates(List<PlanTemplatePreset> items) async {
    await TemplateLibraryStorage.saveCustomTemplates(items);
    if (!mounted) return;
    setState(() {
      _customTemplates = items;
    });
  }

  Future<void> _createTemplate() async {
    final result = await Navigator.push<_TemplateEditorResult>(
      context,
      MaterialPageRoute<_TemplateEditorResult>(
        builder: (_) => const _TemplateEditorPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == null) return;
    await _persistTemplates([..._customTemplates, result.template]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template "${result.template.title}" dibuat.')),
    );
    if (result.applyToToday) {
      await widget.onUseTemplate(result.template, replaceCurrentDay: true);
    }
  }

  Future<void> _editTemplate(PlanTemplatePreset preset) async {
    final result = await Navigator.push<_TemplateEditorResult>(
      context,
      MaterialPageRoute<_TemplateEditorResult>(
        builder: (_) => _TemplateEditorPage(initialValue: preset),
        fullscreenDialog: true,
      ),
    );
    if (result == null) return;
    final next = _customTemplates
        .map((item) => item.id == preset.id ? result.template : item)
        .toList();
    await _persistTemplates(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "${result.template.title}" diperbarui.'),
      ),
    );
    if (result.applyToToday) {
      await widget.onUseTemplate(result.template, replaceCurrentDay: true);
    }
  }

  Future<void> _deleteTemplate(PlanTemplatePreset preset) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus template?'),
        content: Text('Template "${preset.title}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _persistTemplates(
      _customTemplates.where((item) => item.id != preset.id).toList(),
    );
  }

  Future<void> _useTemplate(PlanTemplatePreset preset) async {
    await widget.onUseTemplate(preset);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "${preset.title}" ditambahkan ke schedule.'),
      ),
    );
  }

  Future<void> _openDetails(PlanTemplatePreset preset, bool isCustom) async {
    final accent = _accentFor(preset, isCustom);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1411213D),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6E0EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(_iconFor(preset, isCustom), color: accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.title,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _summaryFor(preset),
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DetailLine(
                  icon: Icons.schedule_rounded,
                  label: 'Total durasi',
                  value: _durationLabel(preset.durationMinutes),
                ),
                const SizedBox(height: 12),
                _DetailLine(
                  icon: Icons.view_timeline_rounded,
                  label: 'Jumlah blok',
                  value: '${preset.blocks.length} blok aktivitas',
                ),
                const SizedBox(height: 12),
                _DetailLine(
                  icon: Icons.notes_rounded,
                  label: 'Catatan',
                  value: preset.note,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (isCustom) ...[
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _editTemplate(preset);
                        },
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _useTemplate(preset);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Pakai template'),
                      ),
                    ),
                  ],
                ),
                if (isCustom) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _deleteTemplate(preset);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCC4458),
                      ),
                      child: const Text('Hapus template'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = _library;
    final showFeatured = _query.trim().isEmpty || _matches(_featured, _query);

    return ColoredBox(
      color: _surface,
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(onCreateTap: _createTemplate),
                          const SizedBox(height: 16),
                          _SearchField(controller: _searchController),
                          if (showFeatured) ...[
                            const SizedBox(height: 20),
                            const _SectionLabel('REKOMENDASI HARI INI'),
                            const SizedBox(height: 10),
                            _FeaturedCard(
                              preset: _featured,
                              onTap: () => _openDetails(_featured, false),
                              onUse: () => _useTemplate(_featured),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const _SectionTitle(
                            title: 'Library template',
                            subtitle:
                                'Template siap pakai dan template custom untuk mempercepat pembuatan schedule.',
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  if (library.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 132),
                        child: _EmptyState(
                          hasQuery: _query.trim().isNotEmpty,
                          onCreateTap: _createTemplate,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 132),
                      sliver: SliverList.separated(
                        itemCount: library.length,
                        itemBuilder: (context, index) {
                          final preset = library[index];
                          final isCustom = _customTemplates.any(
                            (item) => item.id == preset.id,
                          );
                          return _LibraryCard(
                            preset: preset,
                            isCustom: isCustom,
                            onTap: () => _openDetails(preset, isCustom),
                            onUse: () => _useTemplate(preset),
                            onEdit: isCustom
                                ? () => _editTemplate(preset)
                                : null,
                            onDelete: isCustom
                                ? () => _deleteTemplate(preset)
                                : null,
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Template',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onCreateTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Buat'),
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Cari template atau rutinitas...',
          hintStyle: const TextStyle(color: _muted, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 24),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                  color: _muted,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF6F809C),
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.3),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.preset,
    required this.onTap,
    required this.onUse,
  });

  final PlanTemplatePreset preset;
  final VoidCallback onTap;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF1D5BE4), Color(0xFF3670F3)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Direkomendasikan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_rounded, color: Colors.white, size: 34),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _headlineFor(preset),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _summaryFor(preset),
                style: const TextStyle(
                  color: Color(0xFFE9F0FF),
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.note,
                      style: const TextStyle(
                        color: Color(0xFFEAF0FF),
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: onUse,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Pakai'),
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

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.preset,
    required this.isCustom,
    required this.onTap,
    required this.onUse,
    this.onEdit,
    this.onDelete,
  });

  final PlanTemplatePreset preset;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback onUse;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(preset, isCustom);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _iconFor(preset, isCustom),
                  color: accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preset.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _soft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'CUSTOM',
                              style: TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _summaryFor(preset),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preset.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  if (isCustom)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      icon: const Icon(Icons.more_horiz_rounded, color: _muted),
                    )
                  else
                    const SizedBox(height: 24),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: onUse,
                    style: FilledButton.styleFrom(
                      backgroundColor: _soft,
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Pakai'),
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

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.onCreateTap});

  final bool hasQuery;
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasQuery ? 'Template tidak ditemukan' : 'Belum ada template custom',
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery
                ? 'Coba kata kunci lain atau buat template baru.'
                : 'Simpan rutinitas yang sering diulang supaya menambah schedule tidak perlu isi manual terus.',
            style: const TextStyle(color: _muted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat template'),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateEditorResult {
  const _TemplateEditorResult({
    required this.template,
    required this.applyToToday,
  });

  final PlanTemplatePreset template;
  final bool applyToToday;
}

class _TemplateEditorPage extends StatefulWidget {
  const _TemplateEditorPage({this.initialValue});

  final PlanTemplatePreset? initialValue;

  @override
  State<_TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<_TemplateEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<PlanTemplateBlock> _blocks = <PlanTemplateBlock>[];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null) {
      _titleController.text = initial.title;
      _noteController.text = initial.note;
      _blocks = [...initial.blocks]
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _totalMinutes =>
      _blocks.fold<int>(0, (sum, block) => sum + block.durationMinutes);

  Future<void> _addBlock() async {
    final initial = _blocks.isEmpty
        ? PlanTemplateBlock(
            id: 'block_${DateTime.now().microsecondsSinceEpoch}',
            title: 'Task block',
            startMinute: 9 * 60,
            endMinute: 10 * 60,
            kind: PlanTemplateBlockKind.task,
          )
        : _blocks.last.copyWith(
            id: 'block_${DateTime.now().microsecondsSinceEpoch}',
            title: 'Task block',
            startMinute: _blocks.last.endMinute,
            endMinute: (_blocks.last.endMinute + 60).clamp(0, 24 * 60),
          );
    final result = await showModalBottomSheet<PlanTemplateBlock>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BlockEditorSheet(initialValue: initial),
    );
    if (result == null) return;
    setState(() {
      _blocks = [..._blocks, result]
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    });
  }

  Future<void> _editBlock(PlanTemplateBlock block) async {
    final result = await showModalBottomSheet<PlanTemplateBlock>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BlockEditorSheet(initialValue: block),
    );
    if (result == null) return;
    setState(() {
      _blocks =
          _blocks.map((item) => item.id == block.id ? result : item).toList()
            ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
    });
  }

  void _deleteBlock(PlanTemplateBlock block) {
    setState(() {
      _blocks = _blocks.where((item) => item.id != block.id).toList();
    });
  }

  PlanTemplatePreset? _buildTemplate() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama template tidak boleh kosong.')),
      );
      return null;
    }
    if (_blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu task block.')),
      );
      return null;
    }
    if (_hasOverlap(_blocks)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masih ada blok waktu yang saling bertabrakan.'),
        ),
      );
      return null;
    }
    return PlanTemplatePreset(
      id:
          widget.initialValue?.id ??
          'custom_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      note: _noteController.text.trim().isEmpty
          ? 'Template schedule umum untuk dipakai ulang.'
          : _noteController.text.trim(),
      blocks: [..._blocks]
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute)),
    );
  }

  void _save({required bool applyToToday}) {
    final template = _buildTemplate();
    if (template == null) return;
    Navigator.pop(
      context,
      _TemplateEditorResult(template: template, applyToToday: applyToToday),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _EditorHeader(
              title: widget.initialValue == null
                  ? 'Create New Template'
                  : 'Edit Template',
              onClose: () => Navigator.pop(context),
              onSave: () => _save(applyToToday: false),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Template Name',
                      style: TextStyle(
                        color: Color(0xFF445B78),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Final Exam Week',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi template',
                        hintText: 'Ringkasan singkat untuk library template',
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Schedule Builder',
                            style: TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _soft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_durationLabel(_totalMinutes)} total',
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (_blocks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Belum ada block. Tambahkan block pertama untuk mulai menyusun template.',
                          style: TextStyle(color: _muted, height: 1.4),
                        ),
                      ),
                    for (var i = 0; i < _blocks.length; i++) ...[
                      _TimelineBlockCard(
                        block: _blocks[i],
                        isLast: i == _blocks.length - 1,
                        onEdit: () => _editBlock(_blocks[i]),
                        onDelete: () => _deleteBlock(_blocks[i]),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _AddBlockButton(onTap: _addBlock),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
              decoration: const BoxDecoration(
                color: _card,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _save(applyToToday: true),
                      icon: const Icon(Icons.bolt_rounded),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      label: const Text('Save and Apply to Today'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ini akan mengganti schedule di hari yang sedang dipilih.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.title,
    required this.onClose,
    required this.onSave,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: _muted, size: 30),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          TextButton(
            onPressed: onSave,
            child: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineBlockCard extends StatelessWidget {
  const _TimelineBlockCard({
    required this.block,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  final PlanTemplateBlock block;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForBlock(block.kind);
    final isBreak =
        block.kind == PlanTemplateBlockKind.breakTime ||
        block.kind == PlanTemplateBlockKind.meal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Column(
            children: [
              Text(
                _minuteLabel(block.startMinute),
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 2,
                height: isLast ? 80 : 112,
                color: isLast ? _border : _soft,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isBreak ? accent.withValues(alpha: 0.08) : _card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isBreak ? accent.withValues(alpha: 0.28) : _border,
              ),
              boxShadow: isBreak
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0A11213D),
                        blurRadius: 12,
                        offset: Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconForKind(block.kind),
                    color: accent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.title,
                        style: TextStyle(
                          color: _ink,
                          fontWeight: isBreak
                              ? FontWeight.w600
                              : FontWeight.w800,
                          fontSize: 18,
                          fontStyle: isBreak
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_minuteLabel(block.startMinute)} - ${_minuteLabel(block.endMinute)}'
                        '${block.note.isEmpty ? '' : ' - ${block.note}'}',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit block')),
                    PopupMenuItem(value: 'delete', child: Text('Delete block')),
                  ],
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddBlockButton extends StatelessWidget {
  const _AddBlockButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Column(
            children: [
              Text(
                'ADD',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 2,
                height: 84,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _soft,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFBFD0F8), width: 2),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_rounded,
                    color: Color(0xFF7B9CF3),
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'ADD TASK BLOCK',
                    style: TextStyle(
                      color: Color(0xFF6A90F0),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlockEditorSheet extends StatefulWidget {
  const _BlockEditorSheet({required this.initialValue});

  final PlanTemplateBlock initialValue;

  @override
  State<_BlockEditorSheet> createState() => _BlockEditorSheetState();
}

class _BlockEditorSheetState extends State<_BlockEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late PlanTemplateBlockKind _kind;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialValue.title);
    _noteController = TextEditingController(text: widget.initialValue.note);
    _kind = widget.initialValue.kind;
    _start = _timeOfDayFromMinute(widget.initialValue.startMinute);
    _end = _timeOfDayFromMinute(widget.initialValue.endMinute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final result = await showTimePicker(context: context, initialTime: _start);
    if (result == null) return;
    setState(() => _start = result);
  }

  Future<void> _pickEnd() async {
    final result = await showTimePicker(context: context, initialTime: _end);
    if (result == null) return;
    setState(() => _end = result);
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama block tidak boleh kosong.')),
      );
      return;
    }
    final startMinute = _start.hour * 60 + _start.minute;
    final endMinute = _end.hour * 60 + _end.minute;
    if (endMinute <= startMinute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai harus setelah waktu mulai.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      widget.initialValue.copyWith(
        title: title,
        startMinute: startMinute,
        endMinute: endMinute,
        kind: _kind,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 24, 12, 12 + inset),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Task Block',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Judul block'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  hintText: 'Catatan atau lokasi',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Jenis block',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kind in PlanTemplateBlockKind.values)
                    ChoiceChip(
                      label: Text(_kindLabel(kind)),
                      selected: _kind == kind,
                      onSelected: (_) => setState(() => _kind = kind),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text('Mulai ${_start.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickEnd,
                      icon: const Icon(Icons.schedule_send_rounded),
                      label: Text('Selesai ${_end.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Simpan block'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _matches(PlanTemplatePreset preset, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return preset.title.toLowerCase().contains(q) ||
      preset.note.toLowerCase().contains(q);
}

bool _hasOverlap(List<PlanTemplateBlock> blocks) {
  final sorted = [...blocks]
    ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  for (var i = 0; i < sorted.length - 1; i++) {
    if (sorted[i].endMinute > sorted[i + 1].startMinute) return true;
  }
  return false;
}

IconData _iconFor(PlanTemplatePreset preset, bool isCustom) {
  if (isCustom) return Icons.auto_awesome_rounded;
  if (preset.id == PlanTemplateBridge.healthyHabit.id) {
    return Icons.wb_sunny_rounded;
  }
  if (preset.id == PlanTemplateBridge.studyFocus.id) {
    return Icons.menu_book_rounded;
  }
  return Icons.bolt_rounded;
}

Color _accentFor(PlanTemplatePreset preset, bool isCustom) {
  if (isCustom) return const Color(0xFF9B51E0);
  if (preset.id == PlanTemplateBridge.healthyHabit.id) {
    return const Color(0xFFFF7A00);
  }
  if (preset.id == PlanTemplateBridge.studyFocus.id) {
    return const Color(0xFF21A46B);
  }
  return _primary;
}

Color _accentForBlock(PlanTemplateBlockKind kind) {
  switch (kind) {
    case PlanTemplateBlockKind.breakTime:
      return const Color(0xFFF59E0B);
    case PlanTemplateBlockKind.meal:
      return const Color(0xFFF97316);
    case PlanTemplateBlockKind.study:
      return _primary;
    case PlanTemplateBlockKind.meeting:
      return const Color(0xFF0EA5E9);
    case PlanTemplateBlockKind.fitness:
      return const Color(0xFF10B981);
    case PlanTemplateBlockKind.task:
      return _primary;
  }
}

IconData _iconForKind(PlanTemplateBlockKind kind) {
  switch (kind) {
    case PlanTemplateBlockKind.breakTime:
      return Icons.free_breakfast_rounded;
    case PlanTemplateBlockKind.meal:
      return Icons.restaurant_rounded;
    case PlanTemplateBlockKind.study:
      return Icons.menu_book_rounded;
    case PlanTemplateBlockKind.meeting:
      return Icons.groups_rounded;
    case PlanTemplateBlockKind.fitness:
      return Icons.fitness_center_rounded;
    case PlanTemplateBlockKind.task:
      return Icons.checklist_rounded;
  }
}

String _kindLabel(PlanTemplateBlockKind kind) {
  switch (kind) {
    case PlanTemplateBlockKind.breakTime:
      return 'Break';
    case PlanTemplateBlockKind.meal:
      return 'Meal';
    case PlanTemplateBlockKind.study:
      return 'Study';
    case PlanTemplateBlockKind.meeting:
      return 'Meeting';
    case PlanTemplateBlockKind.fitness:
      return 'Fitness';
    case PlanTemplateBlockKind.task:
      return 'Task';
  }
}

String _headlineFor(PlanTemplatePreset preset) {
  if (preset.id == PlanTemplateBridge.deepWork.id) return 'Deep Work';
  return preset.title;
}

String _summaryFor(PlanTemplatePreset preset) {
  return '${_durationLabel(preset.durationMinutes)} - ${preset.blocks.length} blok';
}

String _durationLabel(int minutes) {
  if (minutes % 60 == 0) return '${minutes ~/ 60} jam';
  if (minutes > 60) return '${(minutes / 60).toStringAsFixed(1)} jam';
  return '$minutes menit';
}

String _minuteLabel(int minute) {
  final hour = (minute ~/ 60).toString().padLeft(2, '0');
  final min = (minute % 60).toString().padLeft(2, '0');
  return '$hour:$min';
}

TimeOfDay _timeOfDayFromMinute(int minute) {
  return TimeOfDay(hour: minute ~/ 60, minute: minute % 60);
}
