import 'package:flutter/material.dart';

import '../../../../core/services/plan_template_bridge.dart';
import '../../data/template_library_storage.dart';

const Color _templateSurface = Color(0xFFF1F7FF);
const Color _templateCard = Color(0xFFFAFDFF);
const Color _templateInk = Color(0xFF16233A);
const Color _templateMuted = Color(0xFF7187A6);
const Color _templatePrimary = Color(0xFF274976);
const Color _templateSoft = Color(0xFFDDE8F6);

class TemplateLibraryPage extends StatefulWidget {
  const TemplateLibraryPage({super.key, required this.onUseTemplate});

  final Future<void> Function(PlanTemplatePreset preset) onUseTemplate;

  @override
  State<TemplateLibraryPage> createState() => _TemplateLibraryPageState();
}

class _TemplateLibraryPageState extends State<TemplateLibraryPage> {
  List<PlanTemplatePreset> _customTemplates = const <PlanTemplatePreset>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomTemplates();
  }

  Future<void> _loadCustomTemplates() async {
    final items = await TemplateLibraryStorage.loadCustomTemplates();
    if (!mounted) return;
    setState(() {
      _customTemplates = items;
      _isLoading = false;
    });
  }

  Future<void> _saveCustomTemplates(List<PlanTemplatePreset> items) async {
    await TemplateLibraryStorage.saveCustomTemplates(items);
    if (!mounted) return;
    setState(() {
      _customTemplates = items;
    });
  }

  Future<void> _createTemplate() async {
    final result = await showModalBottomSheet<PlanTemplatePreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TemplateComposerSheet(),
    );
    if (result == null) return;
    final next = [..._customTemplates, result];
    await _saveCustomTemplates(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template "${result.title}" dibuat.')),
    );
  }

  Future<void> _editTemplate(PlanTemplatePreset preset) async {
    final result = await showModalBottomSheet<PlanTemplatePreset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateComposerSheet(initialValue: preset),
    );
    if (result == null) return;
    final next = _customTemplates
        .map((item) => item.id == preset.id ? result : item)
        .toList();
    await _saveCustomTemplates(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template "${result.title}" diperbarui.')),
    );
  }

  Future<void> _deleteTemplate(PlanTemplatePreset preset) async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed != true) return;
    final next = _customTemplates
        .where((item) => item.id != preset.id)
        .toList();
    await _saveCustomTemplates(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template "${preset.title}" dihapus.')),
    );
  }

  Future<void> _useTemplate(PlanTemplatePreset preset) async {
    await widget.onUseTemplate(preset);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Template "${preset.title}" siap dipakai untuk membuat schedule.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F8FF), Color(0xFFDCE8F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TemplatePageHeader(onCreateTap: _createTemplate),
                          const SizedBox(height: 16),
                          const _TemplateHeroCard(),
                          const SizedBox(height: 22),
                          const _SectionTitle(
                            title: 'Template siap pakai',
                            subtitle:
                                'Pilih template umum untuk fokus, belajar, atau rutinitas berulang.',
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: PlanTemplateBridge.presets.length,
                      itemBuilder: (context, index) {
                        final preset = PlanTemplateBridge.presets[index];
                        return _TemplatePresetCard(
                          preset: preset,
                          isCustom: false,
                          onUse: () => _useTemplate(preset),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: _SectionTitle(
                        title: 'Template saya',
                        subtitle: _customTemplates.isEmpty
                            ? 'Buat template sendiri untuk schedule yang sering diulang.'
                            : 'Template custom yang bisa kamu edit, hapus, dan pakai kapan saja.',
                      ),
                    ),
                  ),
                  if (_customTemplates.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: _TemplateEmptyState(
                          onCreateTap: _createTemplate,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: _customTemplates.length,
                        itemBuilder: (context, index) {
                          final preset = _customTemplates[index];
                          return _TemplatePresetCard(
                            preset: preset,
                            isCustom: true,
                            onUse: () => _useTemplate(preset),
                            onEdit: () => _editTemplate(preset),
                            onDelete: () => _deleteTemplate(preset),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _TemplatePageHeader extends StatelessWidget {
  const _TemplatePageHeader({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _templatePrimary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.dashboard_customize_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Template',
                style: TextStyle(
                  color: _templateInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pilih template siap pakai atau buat versi rutinitasmu sendiri.',
                style: TextStyle(
                  color: _templateMuted,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onCreateTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Buat'),
          style: FilledButton.styleFrom(
            backgroundColor: _templatePrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateHeroCard extends StatelessWidget {
  const _TemplateHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _templateCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDDE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _templateSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.schedule_send_rounded,
                  color: _templatePrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Template mempercepat pembuatan schedule rutin.',
                  style: TextStyle(
                    color: _templateInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Cocok untuk kegiatan yang sering muncul seperti deep work, olahraga, belajar, meeting mingguan, atau ritual pagi. Pilih satu template dan app akan langsung menyiapkan draft schedule dengan judul, durasi, dan catatan default.',
            style: TextStyle(color: _templateMuted, height: 1.45, fontSize: 14),
          ),
        ],
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
            color: _templateInk,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _templateMuted,
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _TemplatePresetCard extends StatelessWidget {
  const _TemplatePresetCard({
    required this.preset,
    required this.isCustom,
    required this.onUse,
    this.onEdit,
    this.onDelete,
  });

  final PlanTemplatePreset preset;
  final bool isCustom;
  final VoidCallback onUse;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _templateCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCustom
                      ? const Color(0xFFEAF1FB)
                      : const Color(0xFFE8F4EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCustom ? 'CUSTOM' : 'READY',
                  style: TextStyle(
                    color: isCustom
                        ? _templatePrimary
                        : const Color(0xFF2F7A4E),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              if (isCustom) ...[
                IconButton(
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_rounded),
                  color: _templateMuted,
                ),
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: _templateMuted,
                ),
              ],
            ],
          ),
          Text(
            preset.title,
            style: const TextStyle(
              color: _templateInk,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            preset.note,
            style: const TextStyle(
              color: _templateMuted,
              height: 1.4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetaChip(
                icon: Icons.timer_outlined,
                label: '${preset.durationMinutes} menit',
              ),
              const SizedBox(width: 8),
              const _MetaChip(
                icon: Icons.repeat_rounded,
                label: 'Bisa dipakai ulang',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onUse,
              icon: const Icon(Icons.playlist_add_rounded, size: 18),
              label: const Text('Pakai template'),
              style: FilledButton.styleFrom(
                backgroundColor: _templatePrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _templateSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _templateMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _templateMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateEmptyState extends StatelessWidget {
  const _TemplateEmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _templateCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Belum ada template custom',
            style: TextStyle(
              color: _templateInk,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Simpan rutinitas yang sering kamu ulang supaya tambah schedule tidak perlu isi manual dari awal.',
            style: TextStyle(color: _templateMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat template pertama'),
          ),
        ],
      ),
    );
  }
}

class _TemplateComposerSheet extends StatefulWidget {
  const _TemplateComposerSheet({this.initialValue});

  final PlanTemplatePreset? initialValue;

  @override
  State<_TemplateComposerSheet> createState() => _TemplateComposerSheetState();
}

class _TemplateComposerSheetState extends State<_TemplateComposerSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int _durationMinutes = 25;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null) {
      _titleController.text = initial.title;
      _noteController.text = initial.note;
      _durationMinutes = initial.durationMinutes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama template tidak boleh kosong.')),
      );
      return;
    }
    final note = _noteController.text.trim().isEmpty
        ? 'Template schedule umum untuk dipakai ulang.'
        : _noteController.text.trim();
    Navigator.pop(
      context,
      PlanTemplatePreset(
        id:
            widget.initialValue?.id ??
            'custom_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        durationMinutes: _durationMinutes,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const durationOptions = [15, 25, 30, 45, 60, 90, 120];

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 24, 12, 12 + bottomInset),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: _templateCard,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.initialValue == null
                        ? 'Buat template'
                        : 'Edit template',
                    style: const TextStyle(
                      color: _templateInk,
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
                decoration: const InputDecoration(
                  hintText: 'Nama template',
                  prefixIcon: Icon(Icons.bookmark_added_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Catatan default untuk schedule ini',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Durasi default',
                style: TextStyle(
                  color: _templateInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in durationOptions)
                    ChoiceChip(
                      label: Text('$item m'),
                      selected: _durationMinutes == item,
                      onSelected: (_) {
                        setState(() {
                          _durationMinutes = item;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _templatePrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Simpan template'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
