import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../../core/services/app_data_portability_service.dart';
import '../../core/services/app_locale_service.dart';
import '../../core/services/plan_template_bridge.dart';
import 'data/home_state_storage.dart';
import 'domain/models/home_models.dart';
import 'presentation/pages/home_notifications_page.dart';
import 'presentation/pages/home_settings_page.dart';
import 'presentation/pages/template_library_page.dart';
import 'presentation/widgets/home_focus_top_section.dart';
import 'presentation/widgets/home_schedule_timeline_section.dart';
import '../mentor/presentation/mentor_chat_popup_dialog.dart';
import '../shell/presentation/youneka_home_shell.dart';

const Color _appWhite = Color(0xFFF8FBFF);
const Color _matchaInk = Color(0xFF16233A);
const Color _matchaDeep = Color(0xFF274976);
const Color _matchaOlive = Color(0xFF5E86C8);
const Color _matchaGold = Color(0xFF9FBDE7);
const Color _matchaCream = Color(0xFFF0F6FD);
const Color _matchaMist = Color(0xFFDDE8F6);
const Color _matchaSoft = Color(0xFFC5D8F1);
const Color _matchaMuted = Color(0xFF7187A6);

enum ResizeHandlePosition { topLeft, topRight, bottomLeft, bottomRight }

enum SpawnDirection { top, right, bottom, left }

class _RailDivider extends StatelessWidget {
  const _RailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: const Color(0xFFE2E8F0),
      ),
    );
  }
}

class FlowNodeWidget extends StatelessWidget {
  const FlowNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.isConnectionSource,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onRequestEdit,
    this.isEditing = false,
    this.editController,
    this.editFocusNode,
    this.onTextChanged,
    this.onEditingComplete,
  });

  final FlowNode node;
  final bool isSelected;
  final bool isConnectionSource;
  final ValueChanged<String> onTap;
  final void Function(String nodeId, Offset globalPosition) onDragStart;
  final void Function(String nodeId, Offset globalPosition) onDragUpdate;
  final ValueChanged<String> onDragEnd;
  final ValueChanged<FlowNode> onRequestEdit;
  final bool isEditing;
  final TextEditingController? editController;
  final FocusNode? editFocusNode;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) {
    final FlowNodeStyle style = node.type.style;
    final bool editing =
        isEditing && editController != null && editFocusNode != null;
    final Color borderColor = isConnectionSource
        ? const Color(0xFF22C55E)
        : isSelected
        ? _matchaDeep
        : style.borderColor;

    final TextStyle textStyle =
        Theme.of(context).textTheme.titleSmall?.copyWith(
          color: style.textColor,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ) ??
        TextStyle(
          color: style.textColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        );

    Widget content;
    if (editing) {
      content = TextField(
        controller: editController,
        focusNode: editFocusNode,
        onChanged: onTextChanged,
        onEditingComplete: onEditingComplete,
        onSubmitted: (_) => onEditingComplete?.call(),
        onTapOutside: (_) => onEditingComplete?.call(),
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: textStyle,
        cursorColor: style.textColor,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
      );
    } else {
      content = Text(
        node.text,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    const double paddingHorizontal = 22;
    const double paddingVertical = 18;

    Widget shapedNode;
    switch (style.shape) {
      case FlowShape.diamond:
        shapedNode = _DiamondShape(
          borderColor: borderColor,
          fillColor: style.fillColor,
          borderWidth: isSelected ? 3 : 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: paddingHorizontal,
              vertical: paddingVertical,
            ),
            child: content,
          ),
        );
        break;
      case FlowShape.parallelogram:
        shapedNode = _ParallelogramShape(
          borderColor: borderColor,
          fillColor: style.fillColor,
          borderWidth: isSelected ? 3 : 2,
          skew: 0.18,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: paddingHorizontal,
              vertical: paddingVertical,
            ),
            child: content,
          ),
        );
        break;
      case FlowShape.stadium:
        shapedNode = DecoratedBox(
          decoration: BoxDecoration(
            color: style.fillColor,
            borderRadius: BorderRadius.circular(node.size.height),
            border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
          ),
          child: Center(child: content),
        );
        break;
      case FlowShape.rounded:
        shapedNode = DecoratedBox(
          decoration: BoxDecoration(
            color: style.fillColor,
            borderRadius: BorderRadius.circular(style.borderRadius),
            border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
          ),
          child: Center(child: content),
        );
        break;
      case FlowShape.rectangle:
        shapedNode = DecoratedBox(
          decoration: BoxDecoration(
            color: style.fillColor,
            borderRadius: BorderRadius.circular(style.borderRadius),
            border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
          ),
          child: Center(child: content),
        );
        break;
    }

    final Widget body = Container(
      width: node.size.width,
      height: node.size.height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0x2256661F)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isSelected ? 20 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  style.shape == FlowShape.diamond ||
                      style.shape == FlowShape.parallelogram
                  ? BorderRadius.zero
                  : BorderRadius.circular(
                      style.shape == FlowShape.stadium
                          ? node.size.height
                          : style.borderRadius,
                    ),
              child: shapedNode,
            ),
          ),
          if (isConnectionSource)
            Positioned(
              right: -12,
              top: node.size.height / 2 - 6,
              child: _ConnectionBadge(color: borderColor),
            ),
        ],
      ),
    );

    return MouseRegion(
      cursor: editing ? SystemMouseCursors.text : SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: editing
            ? HitTestBehavior.deferToChild
            : HitTestBehavior.opaque,
        onTap: editing ? null : () => onTap(node.id),
        onDoubleTap: editing ? null : () => onRequestEdit(node),
        onPanStart: editing
            ? null
            : (details) => onDragStart(node.id, details.globalPosition),
        onPanUpdate: editing
            ? null
            : (details) => onDragUpdate(node.id, details.globalPosition),
        onPanEnd: editing ? null : (_) => onDragEnd(node.id),
        onPanCancel: editing ? null : () => onDragEnd(node.id),
        child: body,
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.arrow_outward_rounded,
        size: 14,
        color: _appWhite,
      ),
    );
  }
}

class _DiamondShape extends StatelessWidget {
  const _DiamondShape({
    required this.borderColor,
    required this.fillColor,
    required this.child,
    this.borderWidth = 2,
  });

  final Color borderColor;
  final Color fillColor;
  final double borderWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(
          clipper: _DiamondClipper(),
          child: DecoratedBox(decoration: BoxDecoration(color: borderColor)),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: ClipPath(
              clipper: _DiamondClipper(),
              child: DecoratedBox(
                decoration: BoxDecoration(color: fillColor),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParallelogramShape extends StatelessWidget {
  const _ParallelogramShape({
    required this.borderColor,
    required this.fillColor,
    required this.child,
    required this.skew,
    this.borderWidth = 2,
  });

  final Color borderColor;
  final Color fillColor;
  final Widget child;
  final double skew;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(
          clipper: _ParallelogramClipper(skew),
          child: DecoratedBox(decoration: BoxDecoration(color: borderColor)),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: ClipPath(
              clipper: _ParallelogramClipper(skew),
              child: DecoratedBox(
                decoration: BoxDecoration(color: fillColor),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiamondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ParallelogramClipper extends CustomClipper<Path> {
  const _ParallelogramClipper(this.skew);

  final double skew;

  @override
  Path getClip(Size size) {
    final double dx = size.height * skew;
    final Path path = Path()
      ..moveTo(dx, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SpawnMenuCard extends StatelessWidget {
  const _SpawnMenuCard({required this.origin, required this.onSelect});

  final FlowNode origin;
  final ValueChanged<FlowNodeType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: _appWhite,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah objek',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => onSelect(origin.type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF0E9D6),
                    border: Border.all(color: _matchaDeep, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.subdirectory_arrow_right,
                        color: _matchaDeep,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tambah  serupa',
                        style: const TextStyle(
                          color: _matchaInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: FlowNodeType.values.map((type) {
                  return Tooltip(
                    message: type.shortLabel,
                    child: _SpawnMenuItem(
                      type: type,
                      isPrimary: type == origin.type,
                      onTap: () {
                        onSelect(type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpawnMenuItem extends StatelessWidget {
  const _SpawnMenuItem({
    required this.type,
    required this.onTap,
    this.isPrimary = false,
  });

  final FlowNodeType type;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final Color border = isPrimary ? _matchaDeep : _matchaGold;
    final Color iconColor = isPrimary ? _matchaDeep : _matchaInk;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.2),
          color: _appWhite,
        ),
        child: Icon(type.icon, size: 22, color: iconColor),
      ),
    );
  }
}

class FlowGridPainter extends CustomPainter {
  const FlowGridPainter({required this.scale});

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    const double minorSpacing = 80;
    const double majorSpacing = 320;

    final double opacityFactor = (0.25 + (scale - 1).abs() * -0.1).clamp(
      0.15,
      0.35,
    );

    final Paint minorPaint = Paint()
      ..color = const Color(0xFFD8D1B7).withValues(alpha: opacityFactor)
      ..strokeWidth = 1;
    final Paint majorPaint = Paint()
      ..color = const Color(0xFFC8C091).withValues(alpha: (opacityFactor + 0.1))
      ..strokeWidth = 1.2;

    for (double x = 0; x <= size.width; x += minorSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }
    for (double y = 0; y <= size.height; y += minorSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }
    for (double x = 0; x <= size.width; x += majorSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }
    for (double y = 0; y <= size.height; y += majorSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FlowGridPainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}

class ConnectionPainter extends CustomPainter {
  ConnectionPainter({
    required this.nodes,
    required this.connections,
    required this.highlightFrom,
  });

  final List<FlowNode> nodes;
  final List<FlowConnection> connections;
  final String? highlightFrom;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD4CCAE);

    final Paint highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = _matchaDeep;

    for (final connection in connections) {
      final FlowNode? from = nodes.firstWhereOrNull(
        (node) => node.id == connection.fromId,
      );
      final FlowNode? to = nodes.firstWhereOrNull(
        (node) => node.id == connection.toId,
      );
      if (from == null || to == null) continue;

      final bool isHighlighted =
          connection.fromId == highlightFrom ||
          connection.toId == highlightFrom;

      final Offset start = from.position.dx <= to.position.dx
          ? from.centerRight
          : from.centerBottom;
      final Offset end = from.position.dx <= to.position.dx
          ? to.centerLeft
          : to.centerTop;

      final double midX = (start.dx + end.dx) / 2;
      final Path path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);

      final Paint paint = isHighlighted ? highlightPaint : basePaint;
      canvas.drawPath(path, paint);

      final Offset arrowBase = Offset(midX, end.dy);
      _drawArrowHead(canvas, paint, end, arrowBase);
    }
  }

  void _drawArrowHead(Canvas canvas, Paint paint, Offset tip, Offset origin) {
    const double arrowLength = 12;
    const double arrowAngle = pi / 8;

    final double angle = atan2(tip.dy - origin.dy, tip.dx - origin.dx);

    final Path arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * cos(angle - arrowAngle),
        tip.dy - arrowLength * sin(angle - arrowAngle),
      )
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * cos(angle + arrowAngle),
        tip.dy - arrowLength * sin(angle + arrowAngle),
      );

    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) => true;
}

class FlowNode {
  FlowNode({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.text,
  });

  String id;
  FlowNodeType type;
  Offset position;
  Size size;
  String text;

  FlowNode copy({
    String? id,
    FlowNodeType? type,
    Offset? position,
    Size? size,
    String? text,
  }) {
    return FlowNode(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'x': position.dx,
      'y': position.dy,
      'width': size.width,
      'height': size.height,
      'text': text,
    };
  }

  factory FlowNode.fromJson(Map<String, dynamic> json) {
    final FlowNodeType type = FlowNodeType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => FlowNodeType.process,
    );
    return FlowNode(
      id: json['id'] as String,
      type: type,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      size: Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      text: json['text'] as String? ?? '',
    );
  }

  Rect get rect =>
      Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  Offset get center =>
      Offset(position.dx + size.width / 2, position.dy + size.height / 2);
  Offset get centerLeft => Offset(position.dx, position.dy + size.height / 2);
  Offset get centerRight =>
      Offset(position.dx + size.width, position.dy + size.height / 2);
  Offset get centerTop => Offset(position.dx + size.width / 2, position.dy);
  Offset get centerBottom =>
      Offset(position.dx + size.width / 2, position.dy + size.height);
}

class FlowConnection {
  FlowConnection({required this.id, required this.fromId, required this.toId});

  String id;
  String fromId;
  String toId;

  FlowConnection copy({String? id, String? fromId, String? toId}) {
    return FlowConnection(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'fromId': fromId, 'toId': toId};
  }

  factory FlowConnection.fromJson(Map<String, dynamic> json) {
    return FlowConnection(
      id: json['id'] as String,
      fromId: json['fromId'] as String,
      toId: json['toId'] as String,
    );
  }
}

class FlowDiagram {
  FlowDiagram({
    required List<FlowNode> nodes,
    required List<FlowConnection> connections,
  }) : nodes = List<FlowNode>.unmodifiable(nodes.map((node) => node.copy())),
       connections = List<FlowConnection>.unmodifiable(
         connections.map((connection) => connection.copy()),
       );

  final List<FlowNode> nodes;
  final List<FlowConnection> connections;

  static FlowDiagram blank() =>
      FlowDiagram(nodes: const [], connections: const []);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'connections': connections
          .map((connection) => connection.toJson())
          .toList(),
    };
  }

  factory FlowDiagram.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawNodes = json['nodes'] as List<dynamic>? ?? const [];
    final List<dynamic> rawConnections =
        json['connections'] as List<dynamic>? ?? const [];

    return FlowDiagram(
      nodes: rawNodes
          .map((node) => FlowNode.fromJson(node as Map<String, dynamic>))
          .toList(),
      connections: rawConnections
          .map(
            (connection) =>
                FlowConnection.fromJson(connection as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class DiagramTemplate {
  const DiagramTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.buildDiagram,
    required this.previewBuilder,
    required this.previewColor,
  });

  final String id;
  final String title;
  final String description;
  final FlowDiagram Function() buildDiagram;
  final Widget Function() previewBuilder;
  final Color previewColor;

  static final DiagramTemplate blankCanvas = DiagramTemplate(
    id: 'blank',
    title: 'Rencana kosong',
    description: 'Mulai dari awal, pecah tugas jadi langkah kecil.',
    previewColor: const Color(0xFFF4F8FF),
    previewBuilder: _BlankPreview.new,
    buildDiagram: FlowDiagram.blank,
  );

  static final List<DiagramTemplate> presets = [
    DiagramTemplate(
      id: 'focus_sprint',
      title: 'Sesi fokus 25 menit',
      description:
          'Mulai cepat, lindungi fokus, lalu tutup dengan review singkat.',
      previewColor: const Color(0xFFE7EFFB),
      previewBuilder: () => const _TemplatePreview(
        nodes: [
          _PreviewNodeData(
            position: Offset(0.08, 0.15),
            size: Size(0.28, 0.24),
            color: Color(0xFF6C9BE6),
            borderRadius: 32,
            label: 'Mulai fokus',
          ),
          _PreviewNodeData(
            position: Offset(0.45, 0.15),
            size: Size(0.34, 0.24),
            color: Color(0xFF4F79C6),
            borderRadius: 22,
            label: '1 target',
          ),
          _PreviewNodeData.diamond(
            position: Offset(0.23, 0.52),
            size: Size(0.36, 0.3),
            color: Color(0xFFA9C4F4),
            label: 'Terdistraksi?',
          ),
          _PreviewNodeData(
            position: Offset(0.63, 0.55),
            size: Size(0.28, 0.24),
            color: Color(0xFF7DA7EA),
            borderRadius: 20,
            label: 'Kembali fokus',
          ),
        ],
        connections: [
          _PreviewConnectionData(0, 1, Color(0xFF4F79C6)),
          _PreviewConnectionData(1, 2, Color(0xFF4F79C6)),
          _PreviewConnectionData(2, 3, Color(0xFF4F79C6)),
        ],
      ),
      buildDiagram: () {
        return FlowDiagram(
          nodes: [
            FlowNode(
              id: 'node_1',
              type: FlowNodeType.start,
              position: const Offset(280, 220),
              size: FlowNodeType.start.style.defaultSize,
              text: 'Mulai fokus',
            ),
            FlowNode(
              id: 'node_2',
              type: FlowNodeType.process,
              position: const Offset(520, 220),
              size: FlowNodeType.process.style.defaultSize,
              text: 'Tentukan 1 target',
            ),
            FlowNode(
              id: 'node_3',
              type: FlowNodeType.decision,
              position: const Offset(360, 440),
              size: FlowNodeType.decision.style.defaultSize,
              text: 'Terdistraksi?',
            ),
            FlowNode(
              id: 'node_4',
              type: FlowNodeType.data,
              position: const Offset(620, 470),
              size: FlowNodeType.data.style.defaultSize,
              text: 'Rapikan lingkungan',
            ),
            FlowNode(
              id: 'node_5',
              type: FlowNodeType.terminator,
              position: const Offset(860, 360),
              size: FlowNodeType.terminator.style.defaultSize,
              text: 'Sesi selesai',
            ),
          ],
          connections: [
            FlowConnection(id: 'conn_1', fromId: 'node_1', toId: 'node_2'),
            FlowConnection(id: 'conn_2', fromId: 'node_2', toId: 'node_3'),
            FlowConnection(id: 'conn_3', fromId: 'node_3', toId: 'node_4'),
            FlowConnection(id: 'conn_4', fromId: 'node_4', toId: 'node_5'),
          ],
        );
      },
    ),
    DiagramTemplate(
      id: 'weekly_plan',
      title: 'Rencana mingguan',
      description: 'Susun prioritas, blok waktu, lalu eksekusi harian.',
      previewColor: const Color(0xFFEDF4FF),
      previewBuilder: () => const _TemplatePreview(
        nodes: [
          _PreviewNodeData(
            position: Offset(0.12, 0.18),
            size: Size(0.3, 0.22),
            color: Color(0xFF7DA7EA),
            borderRadius: 30,
            label: 'Catat tugas',
          ),
          _PreviewNodeData(
            position: Offset(0.48, 0.12),
            size: Size(0.32, 0.24),
            color: Color(0xFF9DBDEA),
            borderRadius: 24,
            label: 'Kelompokkan',
          ),
          _PreviewNodeData.diamond(
            position: Offset(0.28, 0.5),
            size: Size(0.34, 0.32),
            color: Color(0xFFC8DBF4),
            label: 'Prioritas?',
          ),
          _PreviewNodeData(
            position: Offset(0.68, 0.5),
            size: Size(0.28, 0.24),
            color: Color(0xFF5B84CB),
            borderRadius: 22,
            label: 'Blok waktu',
          ),
        ],
        connections: [
          _PreviewConnectionData(0, 1, Color(0xFF5B84CB)),
          _PreviewConnectionData(1, 2, Color(0xFF5B84CB)),
          _PreviewConnectionData(2, 3, Color(0xFF5B84CB)),
        ],
      ),
      buildDiagram: () {
        return FlowDiagram(
          nodes: [
            FlowNode(
              id: 'node_1',
              type: FlowNodeType.start,
              position: const Offset(280, 200),
              size: FlowNodeType.start.style.defaultSize,
              text: 'Daftar tugas',
            ),
            FlowNode(
              id: 'node_2',
              type: FlowNodeType.process,
              position: const Offset(540, 180),
              size: FlowNodeType.process.style.defaultSize,
              text: 'Kelompokkan jadi tema',
            ),
            FlowNode(
              id: 'node_3',
              type: FlowNodeType.decision,
              position: const Offset(360, 420),
              size: FlowNodeType.decision.style.defaultSize,
              text: 'Prioritas tinggi?',
            ),
            FlowNode(
              id: 'node_4',
              type: FlowNodeType.process,
              position: const Offset(620, 420),
              size: FlowNodeType.process.style.defaultSize,
              text: 'Blok waktu fokus',
            ),
            FlowNode(
              id: 'node_5',
              type: FlowNodeType.note,
              position: const Offset(840, 300),
              size: FlowNodeType.note.style.defaultSize,
              text: 'Catatan strategi',
            ),
          ],
          connections: [
            FlowConnection(id: 'conn_1', fromId: 'node_1', toId: 'node_2'),
            FlowConnection(id: 'conn_2', fromId: 'node_2', toId: 'node_3'),
            FlowConnection(id: 'conn_3', fromId: 'node_3', toId: 'node_4'),
            FlowConnection(id: 'conn_4', fromId: 'node_4', toId: 'node_5'),
          ],
        );
      },
    ),
    DiagramTemplate(
      id: 'anti_procrastination',
      title: 'Siklus anti menunda',
      description: 'Dari pemicu, aksi kecil, sampai reward sederhana.',
      previewColor: const Color(0xFFEAF1FB),
      previewBuilder: () => const _TemplatePreview(
        nodes: [
          _PreviewNodeData(
            position: Offset(0.1, 0.15),
            size: Size(0.28, 0.24),
            color: Color(0xFF86A8DD),
            borderRadius: 22,
            label: 'Pemicu',
          ),
          _PreviewNodeData(
            position: Offset(0.44, 0.15),
            size: Size(0.32, 0.24),
            color: Color(0xFF456DB1),
            borderRadius: 22,
            label: 'Tarik napas',
          ),
          _PreviewNodeData(
            position: Offset(0.72, 0.18),
            size: Size(0.32, 0.24),
            color: Color(0xFFB8CEF2),
            borderRadius: 22,
            label: 'Mulai 5m',
          ),
          _PreviewNodeData.parallelogram(
            position: Offset(0.28, 0.55),
            size: Size(0.32, 0.26),
            color: Color(0xFF9DB7E1),
            label: 'Checkpoint',
          ),
          _PreviewNodeData(
            position: Offset(0.64, 0.56),
            size: Size(0.28, 0.24),
            color: Color(0xFF6D93D3),
            borderRadius: 24,
            label: 'Rayakan',
          ),
        ],
        connections: [
          _PreviewConnectionData(0, 1, Color(0xFF5C84C6)),
          _PreviewConnectionData(1, 2, Color(0xFF456DB1)),
          _PreviewConnectionData(1, 3, Color(0xFF456DB1)),
          _PreviewConnectionData(3, 4, Color(0xFF6D93D3)),
        ],
      ),
      buildDiagram: () {
        return FlowDiagram(
          nodes: [
            FlowNode(
              id: 'node_1',
              type: FlowNodeType.note,
              position: const Offset(280, 200),
              size: FlowNodeType.note.style.defaultSize,
              text: 'Pemicu menunda',
            ),
            FlowNode(
              id: 'node_2',
              type: FlowNodeType.process,
              position: const Offset(520, 200),
              size: FlowNodeType.process.style.defaultSize,
              text: 'Tarik napas',
            ),
            FlowNode(
              id: 'node_3',
              type: FlowNodeType.data,
              position: const Offset(780, 200),
              size: FlowNodeType.data.style.defaultSize,
              text: 'Mulai 5 menit',
            ),
            FlowNode(
              id: 'node_4',
              type: FlowNodeType.data,
              position: const Offset(420, 440),
              size: FlowNodeType.data.style.defaultSize,
              text: 'Checkpoint',
            ),
            FlowNode(
              id: 'node_5',
              type: FlowNodeType.terminator,
              position: const Offset(700, 420),
              size: FlowNodeType.terminator.style.defaultSize,
              text: 'Rayakan',
            ),
          ],
          connections: [
            FlowConnection(id: 'conn_1', fromId: 'node_1', toId: 'node_2'),
            FlowConnection(id: 'conn_2', fromId: 'node_2', toId: 'node_3'),
            FlowConnection(id: 'conn_3', fromId: 'node_2', toId: 'node_4'),
            FlowConnection(id: 'conn_4', fromId: 'node_4', toId: 'node_5'),
          ],
        );
      },
    ),
  ];
}

class _BlankPreview extends StatelessWidget {
  const _BlankPreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome, size: 48, color: Color(0xFF0F766E)),
          SizedBox(height: 12),
          Text(
            'Mulai dari rencana kosong',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({required this.nodes, required this.connections});

  final List<_PreviewNodeData> nodes;
  final List<_PreviewConnectionData> connections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PreviewConnectionPainter(
                  nodes: nodes,
                  connections: connections,
                ),
              ),
            ),
            for (final node in nodes)
              Positioned(
                left: node.position.dx * constraints.maxWidth,
                top: node.position.dy * constraints.maxHeight,
                width: node.size.width * constraints.maxWidth,
                height: node.size.height * constraints.maxHeight,
                child: _PreviewNode(node: node),
              ),
          ],
        );
      },
    );
  }
}

class _PreviewNode extends StatelessWidget {
  const _PreviewNode({required this.node});

  final _PreviewNodeData node;

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (node.shape) {
      case _PreviewShape.diamond:
        child = _DiamondShape(
          borderColor: node.color.withValues(alpha: 0.9),
          fillColor: node.color,
          borderWidth: 2,
          child: Center(
            child: Text(
              node.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _appWhite,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        );
        break;
      case _PreviewShape.parallelogram:
        child = _ParallelogramShape(
          borderColor: node.color.withValues(alpha: 0.9),
          fillColor: node.color,
          skew: 0.22,
          borderWidth: 2,
          child: Center(
            child: Text(
              node.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _appWhite,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        );
        break;
      case _PreviewShape.rounded:
        child = DecoratedBox(
          decoration: BoxDecoration(
            color: node.color,
            borderRadius: BorderRadius.circular(node.borderRadius),
          ),
          child: Center(
            child: Text(
              node.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _appWhite,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        );
        break;
    }

    return Material(
      elevation: 4,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(node.borderRadius),
      child: child,
    );
  }
}

class _PreviewNodeData {
  const _PreviewNodeData({
    required this.position,
    required this.size,
    required this.color,
    required this.borderRadius,
    required this.label,
  }) : shape = _PreviewShape.rounded;

  const _PreviewNodeData.diamond({
    required this.position,
    required this.size,
    required this.color,
    required this.label,
  }) : borderRadius = 0,
       shape = _PreviewShape.diamond;

  const _PreviewNodeData.parallelogram({
    required this.position,
    required this.size,
    required this.color,
    required this.label,
  }) : borderRadius = 18,
       shape = _PreviewShape.parallelogram;

  final Offset position;
  final Size size;
  final Color color;
  final double borderRadius;
  final String label;
  final _PreviewShape shape;
}

enum _PreviewShape { rounded, diamond, parallelogram }

class _PreviewConnectionData {
  const _PreviewConnectionData(this.fromIndex, this.toIndex, this.color);

  final int fromIndex;
  final int toIndex;
  final Color color;
}

class _PreviewConnectionPainter extends CustomPainter {
  _PreviewConnectionPainter({required this.nodes, required this.connections});

  final List<_PreviewNodeData> nodes;
  final List<_PreviewConnectionData> connections;

  @override
  void paint(Canvas canvas, Size size) {
    for (final connection in connections) {
      if (connection.fromIndex >= nodes.length ||
          connection.toIndex >= nodes.length) {
        continue;
      }
      final _PreviewNodeData from = nodes[connection.fromIndex];
      final _PreviewNodeData to = nodes[connection.toIndex];

      final Offset start = Offset(
        (from.position.dx + from.size.width) * size.width,
        (from.position.dy + from.size.height / 2) * size.height,
      );
      final Offset end = Offset(
        (to.position.dx) * size.width,
        (to.position.dy + to.size.height / 2) * size.height,
      );

      final double midX = (start.dx + end.dx) / 2;

      final Path path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);

      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = connection.color.withValues(alpha: 0.85);

      canvas.drawPath(path, paint);
      final Offset arrowOrigin = Offset(midX, end.dy);
      _drawArrow(canvas, paint, end, arrowOrigin);
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset tip, Offset origin) {
    const double arrowLength = 8;
    const double arrowAngle = pi / 8;

    final double angle = atan2(tip.dy - origin.dy, tip.dx - origin.dx);
    final Path arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * cos(angle - arrowAngle),
        tip.dy - arrowLength * sin(angle - arrowAngle),
      )
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * cos(angle + arrowAngle),
        tip.dy - arrowLength * sin(angle + arrowAngle),
      );
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant _PreviewConnectionPainter oldDelegate) => false;
}

enum FlowNodeType { start, process, decision, data, terminator, note }

extension FlowNodeTypeX on FlowNodeType {
  FlowNodeStyle get style => _styles[this]!;

  IconData get icon {
    switch (this) {
      case FlowNodeType.start:
        return Icons.play_circle_fill_rounded;
      case FlowNodeType.process:
        return Icons.view_agenda_rounded;
      case FlowNodeType.decision:
        return Icons.call_split;
      case FlowNodeType.data:
        return Icons.storage_rounded;
      case FlowNodeType.terminator:
        return Icons.stop_circle_outlined;
      case FlowNodeType.note:
        return Icons.sticky_note_2_outlined;
    }
  }

  String get shortLabel {
    switch (this) {
      case FlowNodeType.start:
        return 'Mulai';
      case FlowNodeType.process:
        return 'Proses';
      case FlowNodeType.decision:
        return 'Keputusan';
      case FlowNodeType.data:
        return 'Data/IO';
      case FlowNodeType.terminator:
        return 'Selesai';
      case FlowNodeType.note:
        return 'Catatan';
    }
  }
}

const Map<FlowNodeType, FlowNodeStyle> _styles = <FlowNodeType, FlowNodeStyle>{
  FlowNodeType.start: FlowNodeStyle(
    defaultSize: Size(160, 72),
    defaultLabel: 'Mulai',
    fillColor: _matchaOlive,
    borderColor: _matchaDeep,
    shape: FlowShape.stadium,
    textColor: _appWhite,
    borderRadius: 32,
  ),
  FlowNodeType.process: FlowNodeStyle(
    defaultSize: Size(220, 120),
    defaultLabel: 'Langkah proses',
    fillColor: Color(0xFFDFEAF8),
    borderColor: Color(0xFF6B8FCF),
    shape: FlowShape.rounded,
    textColor: _matchaInk,
    borderRadius: 24,
  ),
  FlowNodeType.decision: FlowNodeStyle(
    defaultSize: Size(200, 200),
    defaultLabel: 'Keputusan?',
    fillColor: Color(0xFFD4E2F8),
    borderColor: Color(0xFF88A8D9),
    shape: FlowShape.diamond,
    textColor: Color(0xFF274976),
    borderRadius: 20,
  ),
  FlowNodeType.data: FlowNodeStyle(
    defaultSize: Size(220, 120),
    defaultLabel: 'Data / IO',
    fillColor: Color(0xFFC8D9F2),
    borderColor: Color(0xFF5E86C8),
    shape: FlowShape.parallelogram,
    textColor: Color(0xFF203A63),
    borderRadius: 20,
  ),
  FlowNodeType.terminator: FlowNodeStyle(
    defaultSize: Size(160, 72),
    defaultLabel: 'Selesai',
    fillColor: Color(0xFFBFD0EC),
    borderColor: Color(0xFF5579B7),
    shape: FlowShape.stadium,
    textColor: Color(0xFF17355D),
    borderRadius: 32,
  ),
  FlowNodeType.note: FlowNodeStyle(
    defaultSize: Size(220, 140),
    defaultLabel: 'Catatan penting',
    fillColor: Color(0xFFECF3FC),
    borderColor: Color(0xFF88A8D9),
    shape: FlowShape.rectangle,
    textColor: Color(0xFF274976),
    borderRadius: 18,
  ),
};

class FlowNodeStyle {
  const FlowNodeStyle({
    required this.defaultSize,
    required this.defaultLabel,
    required this.fillColor,
    required this.borderColor,
    required this.shape,
    required this.textColor,
    this.borderRadius = 16,
  });

  final Size defaultSize;
  final String defaultLabel;
  final Color fillColor;
  final Color borderColor;
  final FlowShape shape;
  final Color textColor;
  final double borderRadius;
}

enum FlowShape { rectangle, rounded, stadium, diamond, parallelogram }

extension IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay({
    required this.node,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.onEditRequested,
    required this.onDuplicateRequested,
    required this.onDeleteRequested,
    required this.onConnectRequested,
    required this.onSpawnRequested,
  });

  final FlowNode node;
  final void Function(ResizeHandlePosition handle, Offset globalPosition)
  onResizeStart;
  final ValueChanged<Offset> onResizeUpdate;
  final VoidCallback onResizeEnd;
  final VoidCallback onEditRequested;
  final VoidCallback onDuplicateRequested;
  final VoidCallback onDeleteRequested;
  final VoidCallback onConnectRequested;
  final void Function(
    FlowNode node,
    SpawnDirection direction,
    Offset globalPosition,
  )
  onSpawnRequested;

  static const double _padding = 12;
  static const double _handleSize = 18;

  @override
  Widget build(BuildContext context) {
    final FlowNodeStyle style = node.type.style;

    return Positioned(
      left: node.position.dx - _padding,
      top: node.position.dy - _padding,
      child: SizedBox(
        width: node.size.width + _padding * 2,
        height: node.size.height + _padding * 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              ignoring: true,
              child: Container(
                margin: const EdgeInsets.all(_padding),
                decoration: BoxDecoration(
                  border: Border.all(color: _matchaDeep, width: 1.5),
                  borderRadius: BorderRadius.circular(
                    style.shape == FlowShape.stadium
                        ? node.size.height
                        : style.borderRadius + 4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2456661F),
                      blurRadius: 20,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -60,
              left: -(_padding),
              right: -(_padding),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickActionButton(
                    icon: Icons.merge_type,
                    tooltip: 'Buat koneksi',
                    onTap: onConnectRequested,
                  ),
                  _QuickActionButton(
                    icon: Icons.mode_edit_outline,
                    tooltip: 'Edit',
                    onTap: onEditRequested,
                  ),
                  _QuickActionButton(
                    icon: Icons.copy,
                    tooltip: 'Duplikasi',
                    onTap: onDuplicateRequested,
                  ),
                  _QuickActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Hapus',
                    onTap: onDeleteRequested,
                    destructive: true,
                  ),
                ],
              ),
            ),
            for (final handle in ResizeHandlePosition.values)
              _ResizeHandle(
                handle: handle,
                onStart: (position) => onResizeStart(handle, position),
                onUpdate: onResizeUpdate,
                onEnd: onResizeEnd,
                size: _handleSize,
                padding: _padding,
                nodeSize: node.size,
              ),
            for (final direction in SpawnDirection.values)
              _SpawnHandle(
                direction: direction,
                nodeSize: node.size,
                padding: _padding,
                onTap: (globalPosition) =>
                    onSpawnRequested(node, direction, globalPosition),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpawnHandle extends StatelessWidget {
  const _SpawnHandle({
    required this.direction,
    required this.nodeSize,
    required this.padding,
    required this.onTap,
  });

  final SpawnDirection direction;
  final Size nodeSize;
  final double padding;
  final ValueChanged<Offset> onTap;

  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    double left;
    double top;
    switch (direction) {
      case SpawnDirection.top:
        left = padding + nodeSize.width / 2 - _size / 2;
        top = -padding - _size - 4;
        break;
      case SpawnDirection.bottom:
        left = padding + nodeSize.width / 2 - _size / 2;
        top = padding + nodeSize.height + 4;
        break;
      case SpawnDirection.left:
        left = -padding - _size - 4;
        top = padding + nodeSize.height / 2 - _size / 2;
        break;
      case SpawnDirection.right:
        left = padding + nodeSize.width + 4;
        top = padding + nodeSize.height / 2 - _size / 2;
        break;
    }

    final double rotation;
    switch (direction) {
      case SpawnDirection.top:
        rotation = -pi / 2;
        break;
      case SpawnDirection.bottom:
        rotation = pi / 2;
        break;
      case SpawnDirection.left:
        rotation = pi;
        break;
      case SpawnDirection.right:
        rotation = 0;
        break;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => onTap(details.globalPosition),
        child: Tooltip(
          message: 'Tambah simpul',
          waitDuration: const Duration(milliseconds: 300),
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: _appWhite,
              shape: BoxShape.circle,
              border: Border.all(color: _matchaDeep, width: 1.6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A56661F),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: _matchaDeep,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color foreground = destructive
        ? const Color(0xFFE11D48)
        : const Color(0xFF1F2937);
    final Color background = destructive
        ? const Color(0xFFFFE4E6)
        : const Color(0xFFF8FAFF);
    return Tooltip(
      waitDuration: const Duration(milliseconds: 300),
      message: tooltip,
      child: Material(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.handle,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.size,
    required this.padding,
    required this.nodeSize,
  });

  final ResizeHandlePosition handle;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;
  final double size;
  final double padding;
  final Size nodeSize;

  @override
  Widget build(BuildContext context) {
    double left = padding;
    double top = padding;

    switch (handle) {
      case ResizeHandlePosition.topLeft:
        break;
      case ResizeHandlePosition.topRight:
        left += nodeSize.width;
        break;
      case ResizeHandlePosition.bottomLeft:
        top += nodeSize.height;
        break;
      case ResizeHandlePosition.bottomRight:
        left += nodeSize.width;
        top += nodeSize.height;
        break;
    }

    left -= size / 2;
    top -= size / 2;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (details) => onStart(details.globalPosition),
        onPanUpdate: (details) => onUpdate(details.globalPosition),
        onPanEnd: (_) => onEnd(),
        onPanCancel: onEnd,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _appWhite,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _matchaDeep, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2256661F),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const Color _andrewInk = _matchaInk;
const Color _andrewTeal = _matchaDeep;
const Color _andrewCream = _matchaCream;
const Color _andrewSoftTeal = _matchaSoft;

class AndrewApp extends StatefulWidget {
  const AndrewApp({super.key});

  @override
  State<AndrewApp> createState() => _AndrewAppState();
}

class _AndrewAppState extends State<AndrewApp> {
  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    await AppLocaleService.loadSavedLocale();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _andrewTeal,
      brightness: Brightness.light,
    );
    final TextTheme textTheme = GoogleFonts.plusJakartaSansTextTheme();
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLocaleService.localeNotifier,
      builder: (context, locale, _) => MaterialApp(
        title: 'Youneka',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: colorScheme,
          textTheme: textTheme,
          scaffoldBackgroundColor: _andrewCream,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: _appWhite,
            foregroundColor: _andrewInk,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(
            color: _appWhite,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: _appWhite,
            hintStyle: const TextStyle(color: _matchaMuted),
            prefixIconColor: _matchaMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _andrewTeal,
              foregroundColor: _appWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: _appWhite,
            indicatorColor: _andrewSoftTeal,
            height: 72,
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              final base =
                  textTheme.labelSmall ?? const TextStyle(fontSize: 12);
              final color = states.contains(MaterialState.selected)
                  ? _andrewTeal
                  : _matchaMuted;
              return base.copyWith(fontWeight: FontWeight.w600, color: color);
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              final color = states.contains(MaterialState.selected)
                  ? _andrewTeal
                  : _matchaMuted;
              return IconThemeData(color: color, size: 24);
            }),
          ),
        ),
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final ValueNotifier<int?> _tabRequestNotifier = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _tabRequestNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleSidebarAction(String action) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case 'settings':
        messenger.showSnackBar(
          const SnackBar(content: Text('Pengaturan akan segera tersedia.')),
        );
        break;
      case 'import':
        await _importAppData();
        break;
      case 'export':
        await _exportAppData();
        break;
      case 'language':
        await _showLanguagePicker();
        break;
    }
  }

  Future<void> _exportAppData() async {
    final path = await AppDataPortabilityService.exportToJsonFile();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export berhasil: $path')));
  }

  Future<void> _importAppData() async {
    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import data'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tempel path file backup .json',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (path == null || path.isEmpty) return;
    final ok = await AppDataPortabilityService.importFromJsonFile(path);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File backup tidak valid / tidak ditemukan.'),
        ),
      );
      return;
    }
    await AppLocaleService.loadSavedLocale();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import berhasil. Silakan restart app.')),
    );
  }

  Future<void> _showLanguagePicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti bahasa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Indonesia'),
              onTap: () => Navigator.pop(ctx, 'id'),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.pop(ctx, 'en'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await AppLocaleService.setLocale(selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bahasa diubah ke ${selected.toUpperCase()}')),
    );
  }

  Future<void> _openMentorChatPopup() async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'mentor-chat',
      barrierDismissible: true,
      barrierColor: const Color(0x990B1220),
      pageBuilder: (context, _, __) => const MentorChatPopupDialog(),
    );
  }

  Future<void> _handleTemplateUse(
    PlanTemplatePreset preset, {
    bool replaceCurrentDay = false,
  }) async {
    _tabRequestNotifier.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlanTemplateBridge.push(preset, replaceCurrentDay: replaceCurrentDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _AndrewPlanPage(),
      TemplateLibraryPage(onUseTemplate: _handleTemplateUse),
      const _AndrewAchievementPage(),
      const _AndrewProfilePage(),
    ];

    return YounekaHomeShell(
      pages: pages,
      initialIndex: 0,
      onSidebarAction: _handleSidebarAction,
      onMentorTap: () => _openMentorChatPopup(),
      tabRequestNotifier: _tabRequestNotifier,
    );
  }
}

// ignore: unused_element
class _AndrewHomePage extends StatelessWidget {
  const _AndrewHomePage();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const _AndrewHomeHeader(),
            const SizedBox(height: 16),
            const _AndrewFocusCard(),
            const SizedBox(height: 20),
            const _AndrewSectionHeader(
              title: 'Toolkit Andrew',
              subtitle: 'Template visual untuk memecah tugas besar.',
            ),
            const SizedBox(height: 8),
            const Expanded(child: _TemplateGrid()),
          ],
        ),
      ),
    );
  }
}

class _AndrewHomeHeader extends StatelessWidget {
  const _AndrewHomeHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _andrewTeal,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _appWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Andrew',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _andrewInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mentor anti menunda untuk anak muda.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: _matchaMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                color: _andrewInk,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Mulai dari langkah kecil, lalu jaga ritme.',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _andrewInk,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Apa yang ingin kamu selesaikan hari ini?',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _QuickChip(
                icon: Icons.timer_rounded,
                label: 'Fokus 25m',
                color: _andrewTeal,
              ),
              _QuickChip(
                icon: Icons.account_tree_rounded,
                label: 'Pecah tugas',
                color: _matchaOlive,
              ),
              _QuickChip(
                icon: Icons.calendar_today_rounded,
                label: 'Rapikan jadwal',
                color: _matchaGold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AndrewFocusCard extends StatelessWidget {
  const _AndrewFocusCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _appWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F0F172A),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesi fokus 25 menit',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _andrewInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Andrew akan bantu kamu mulai tanpa menunggu mood.',
                    style: textTheme.bodyMedium?.copyWith(color: _matchaMuted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _FocusPill(icon: Icons.flag_rounded, label: '1 target'),
                      _FocusPill(icon: Icons.timer_rounded, label: '25 menit'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlowEditorScreen(
                      diagram: FlowDiagram.blank(),
                      title: 'Rencana fokus',
                    ),
                  ),
                );
              },
              child: const Text('Mulai'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusPill extends StatelessWidget {
  const _FocusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _matchaMist,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _matchaMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _matchaMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AndrewSectionHeader extends StatelessWidget {
  const _AndrewSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _andrewInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(color: _matchaMuted),
          ),
        ],
      ),
    );
  }
}

class _AndrewPlanPage extends StatefulWidget {
  const _AndrewPlanPage();

  @override
  State<_AndrewPlanPage> createState() => _AndrewPlanPageState();
}

class _PlanSheetResultData {
  const _PlanSheetResultData({
    required this.title,
    required this.date,
    required this.start,
    required this.end,
  });

  final String title;
  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
}

class _PomodoroUiSnapshot {
  const _PomodoroUiSnapshot({
    required this.phase,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.completedSessions,
    required this.totalSessions,
  });

  final PomodoroPhase phase;
  final int remainingSeconds;
  final int totalSeconds;
  final int completedSessions;
  final int totalSessions;
}

class _AndrewPlanPageState extends State<_AndrewPlanPage>
    with WidgetsBindingObserver {
  late DateTime _selectedDate;
  HomeSettings _settings = HomeSettings.defaults;
  PomodoroRuntime _pomodoro = PomodoroRuntime.initial(HomeSettings.defaults);
  late final ValueNotifier<_PomodoroUiSnapshot> _pomodoroUi;
  late final TextEditingController _quickCreateTitleController;
  late final FocusNode _quickCreateTitleFocusNode;
  List<HomeScheduleItem> _schedules = <HomeScheduleItem>[];
  List<HomeScheduleItem> _selectedDaySchedules = <HomeScheduleItem>[];
  List<HomeNotificationItem> _notifications = <HomeNotificationItem>[];
  Timer? _pomodoroTimer;
  Timer? _persistDebounceTimer;
  int _currentLevel = 12;
  int _currentXp = 1500;
  int _targetXp = 2000;
  bool _isLoading = true;
  int _lastTemplateToken = -1;
  int _idCounter = 0;
  DateTime? _quickCreateStartAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _pomodoroUi = ValueNotifier<_PomodoroUiSnapshot>(_buildPomodoroUi());
    _quickCreateTitleController = TextEditingController();
    _quickCreateTitleFocusNode = FocusNode();
    PlanTemplateBridge.selectionNotifier.addListener(_onTemplateSelected);
    _loadHomeState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pomodoroTimer?.cancel();
    _persistDebounceTimer?.cancel();
    unawaited(_persistHomeStateNow());
    _pomodoroUi.dispose();
    _quickCreateTitleController.dispose();
    _quickCreateTitleFocusNode.dispose();
    PlanTemplateBridge.selectionNotifier.removeListener(_onTemplateSelected);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSelectedDateToToday();
    }
  }

  _PomodoroUiSnapshot _buildPomodoroUi() {
    return _PomodoroUiSnapshot(
      phase: _pomodoro.phase,
      remainingSeconds: _pomodoro.remainingSeconds,
      totalSeconds: _pomodoro.totalSeconds,
      completedSessions: _pomodoro.completedSessions,
      totalSessions: _pomodoro.totalSessions,
    );
  }

  void _syncPomodoroUi() {
    _pomodoroUi.value = _buildPomodoroUi();
  }

  void _refreshSelectedDaySchedules() {
    final selected = DateUtils.dateOnly(_selectedDate);
    _selectedDaySchedules =
        _schedules
            .where((item) => DateUtils.isSameDay(item.startAt, selected))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  void _syncSelectedDateToToday({bool persist = false}) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(_selectedDate, today)) return;
    setState(() {
      _selectedDate = today;
      _quickCreateStartAt = null;
      _quickCreateTitleController.clear();
      _refreshSelectedDaySchedules();
    });
    _quickCreateTitleFocusNode.unfocus();
    if (persist) {
      _queuePersist();
    }
  }

  void _openQuickCreateComposer(DateTime startAt, {String? initialTitle}) {
    final normalizedDate = DateUtils.dateOnly(startAt);
    final normalizedStartAt = DateTime(
      normalizedDate.year,
      normalizedDate.month,
      normalizedDate.day,
      startAt.hour,
      startAt.minute,
    );
    setState(() {
      _selectedDate = normalizedDate;
      _quickCreateStartAt = normalizedStartAt;
      _quickCreateTitleController.text = initialTitle?.trim() ?? '';
      _refreshSelectedDaySchedules();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _quickCreateStartAt == null) return;
      _quickCreateTitleFocusNode.requestFocus();
      _quickCreateTitleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quickCreateTitleController.text.length,
      );
    });
  }

  void _dismissQuickCreateComposer() {
    if (_quickCreateStartAt == null &&
        _quickCreateTitleController.text.isEmpty) {
      return;
    }
    setState(() {
      _quickCreateStartAt = null;
      _quickCreateTitleController.clear();
    });
    _quickCreateTitleFocusNode.unfocus();
  }

  HomeScheduleItem _createQuickScheduleItem() {
    final startAt =
        _quickCreateStartAt ??
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 9);
    final rawTitle = _quickCreateTitleController.text.trim();
    final title = rawTitle.isEmpty ? 'Tanpa judul' : rawTitle;
    return HomeScheduleItem(
      id: 'sch_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      title: title,
      description: 'Kegiatan terjadwal',
      startAt: startAt,
      endAt: startAt.add(const Duration(hours: 1)),
      priority: SchedulePriority.medium,
      isCompleted: false,
      rewardedXp: false,
    );
  }

  void _saveQuickCreateComposer() {
    if (_quickCreateStartAt == null) return;
    final item = _createQuickScheduleItem();
    setState(() {
      _selectedDate = DateUtils.dateOnly(item.startAt);
      _schedules = [..._schedules, item];
      _quickCreateStartAt = null;
      _quickCreateTitleController.clear();
      _refreshSelectedDaySchedules();
      _appendNotification(title: 'Schedule ditambahkan', body: item.title);
    });
    _quickCreateTitleFocusNode.unfocus();
    _queuePersist();
  }

  Future<void> _loadHomeState() async {
    final snapshot = await HomeStateStorage.load();
    if (!mounted) return;

    if (snapshot == null) {
      setState(() {
        _schedules = _buildDefaultSchedules(_selectedDate);
        _refreshSelectedDaySchedules();
        _appendNotification(
          title: 'Selamat datang di Focus Mode',
          body: 'Tap tombol play untuk mulai pomodoro pertama kamu.',
        );
        _isLoading = false;
      });
      _queuePersist();
      return;
    }

    final reconciledPomodoro = _reconcilePomodoro(
      runtime: snapshot.pomodoro,
      settings: snapshot.settings,
    );
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _selectedDate = today;
      _settings = snapshot.settings;
      _pomodoro = reconciledPomodoro;
      _schedules = [...snapshot.schedules];
      _refreshSelectedDaySchedules();
      _notifications = [...snapshot.notifications]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _currentLevel = snapshot.currentLevel;
      _currentXp = snapshot.currentXp;
      _targetXp = snapshot.targetXp;
      _isLoading = false;
    });
    _syncPomodoroUi();
    if (_schedules.isEmpty) {
      setState(() {
        _schedules = _buildDefaultSchedules(_selectedDate);
        _refreshSelectedDaySchedules();
      });
      _queuePersist();
    }
    if (_pomodoro.phase == PomodoroPhase.running) {
      _startPomodoroTicker();
    }
  }

  PomodoroRuntime _reconcilePomodoro({
    required PomodoroRuntime runtime,
    required HomeSettings settings,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expectedTotal = settings.pomodoroMinutes * 60;
    var next = runtime.copyWith(totalSessions: settings.sessionsPerRound);

    if (next.phase == PomodoroPhase.running) {
      final elapsedSeconds = ((nowMs - next.lastUpdatedMs) / 1000).floor();
      final updatedRemaining = (next.remainingSeconds - elapsedSeconds)
          .clamp(0, 86400)
          .toInt();
      next = next.copyWith(
        remainingSeconds: updatedRemaining,
        lastUpdatedMs: nowMs,
      );
      if (updatedRemaining == 0) {
        next = next.copyWith(phase: PomodoroPhase.completed);
      }
    }

    if (next.phase == PomodoroPhase.idle ||
        next.phase == PomodoroPhase.completed) {
      next = next.copyWith(
        totalSeconds: expectedTotal,
        remainingSeconds: next.phase == PomodoroPhase.completed
            ? 0
            : expectedTotal,
        totalSessions: settings.sessionsPerRound,
        completedSessions: next.completedSessions
            .clamp(0, settings.sessionsPerRound)
            .toInt(),
      );
    } else if (next.totalSeconds != expectedTotal) {
      next = next.copyWith(totalSeconds: expectedTotal);
    }
    return next;
  }

  void _onTemplateSelected() {
    unawaited(_handleTemplateSelected());
  }

  Future<void> _handleTemplateSelected() async {
    final payload = PlanTemplateBridge.selectionNotifier.value;
    if (payload == null || payload.token == _lastTemplateToken) return;
    _lastTemplateToken = payload.token;
    final targetDate = DateUtils.dateOnly(_selectedDate);
    final generated = _buildSchedulesFromTemplate(payload.preset, targetDate);
    if (generated.isEmpty || !mounted) return;
    setState(() {
      _selectedDate = targetDate;
      if (payload.replaceCurrentDay) {
        _schedules = [
          ..._schedules.where(
            (item) => !DateUtils.isSameDay(item.startAt, targetDate),
          ),
          ...generated,
        ];
      } else {
        _schedules = [..._schedules, ...generated];
      }
      _schedules.sort((a, b) => a.startAt.compareTo(b.startAt));
      _refreshSelectedDaySchedules();
      _appendNotification(
        title: 'Template ditambahkan',
        body: payload.preset.title,
      );
    });
    _queuePersist();
  }

  List<HomeScheduleItem> _buildSchedulesFromTemplate(
    PlanTemplatePreset preset,
    DateTime date,
  ) {
    return preset.blocks.map((block) {
      final startAt = DateTime(
        date.year,
        date.month,
        date.day,
        block.startMinute ~/ 60,
        block.startMinute % 60,
      );
      final endAt = DateTime(
        date.year,
        date.month,
        date.day,
        block.endMinute ~/ 60,
        block.endMinute % 60,
      );
      return HomeScheduleItem(
        id: 'sch_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
        title: block.title,
        description: block.note.isEmpty ? preset.note : block.note,
        startAt: startAt,
        endAt: endAt.isAfter(startAt)
            ? endAt
            : startAt.add(const Duration(minutes: 30)),
        priority: _priorityFromTemplateBlock(block),
        isCompleted: false,
        rewardedXp: false,
      );
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  SchedulePriority _priorityFromTemplateBlock(PlanTemplateBlock block) {
    switch (block.kind) {
      case PlanTemplateBlockKind.breakTime:
      case PlanTemplateBlockKind.meal:
        return SchedulePriority.low;
      case PlanTemplateBlockKind.task:
      case PlanTemplateBlockKind.study:
      case PlanTemplateBlockKind.meeting:
      case PlanTemplateBlockKind.fitness:
        return SchedulePriority.medium;
    }
  }

  Future<_PlanSheetResultData?> _openAddPlanSheet({
    DateTime? initialDate,
    TimeOfDay? initialStart,
    String? initialTitle,
    int? initialDurationMinutes,
  }) async {
    final result = await showModalBottomSheet<_PlanSheetResultData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddPlanSheet(
        initialDate: initialDate ?? _selectedDate,
        initialStart: initialStart ?? TimeOfDay.now(),
        initialTitle: initialTitle,
        initialDurationMinutes: initialDurationMinutes,
      ),
    );
    return result;
  }

  double get _xpProgress {
    if (_targetXp <= 0) return 0;
    return (_currentXp / _targetXp).clamp(0.0, 1.0);
  }

  Future<void> _persistHomeStateNow() async {
    await HomeStateStorage.save(
      HomeStateSnapshot(
        selectedDate: _selectedDate,
        settings: _settings,
        pomodoro: _pomodoro,
        notifications: _notifications,
        schedules: _schedules,
        currentLevel: _currentLevel,
        currentXp: _currentXp,
        targetXp: _targetXp,
      ),
    );
  }

  void _queuePersist({Duration delay = const Duration(milliseconds: 600)}) {
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(delay, () {
      unawaited(_persistHomeStateNow());
    });
  }

  void _appendNotification({required String title, required String body}) {
    final item = HomeNotificationItem(
      id: 'notif_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isRead: false,
    );
    _notifications = [item, ..._notifications];
    if (_notifications.length > 100) {
      _notifications = _notifications.take(100).toList();
    }
  }

  List<HomeScheduleItem> _buildDefaultSchedules(DateTime date) {
    DateTime at(int hour, int minute) {
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return [
      HomeScheduleItem(
        id: 'seed_${date.millisecondsSinceEpoch}_1',
        title: 'Morning Standup',
        description: 'Sync tim harian.',
        location: 'Zoom Meeting',
        startAt: at(9, 0),
        endAt: at(9, 30),
        priority: SchedulePriority.medium,
        isCompleted: false,
        rewardedXp: false,
      ),
      HomeScheduleItem(
        id: 'seed_${date.millisecondsSinceEpoch}_2',
        title: 'UI Design System',
        description: 'Focusing on component library and tokens',
        startAt: at(10, 0),
        endAt: at(11, 0),
        priority: SchedulePriority.high,
        isCompleted: false,
        rewardedXp: false,
      ),
      HomeScheduleItem(
        id: 'seed_${date.millisecondsSinceEpoch}_3',
        title: 'Review PRs',
        description: '3 pending requests',
        startAt: at(11, 30),
        endAt: at(12, 30),
        priority: SchedulePriority.medium,
        isCompleted: false,
        rewardedXp: false,
      ),
      HomeScheduleItem(
        id: 'seed_${date.millisecondsSinceEpoch}_4',
        title: 'Lunch Break',
        description: 'Lunch Break',
        startAt: at(13, 0),
        endAt: at(13, 45),
        priority: SchedulePriority.low,
        isCompleted: false,
        rewardedXp: false,
      ),
    ];
  }

  HomeScheduleItem _createScheduleFromSheet(
    _PlanSheetResultData data, {
    SchedulePriority? priority,
    String? description,
    String? id,
    bool rewardedXp = false,
    bool isCompleted = false,
  }) {
    final startAt = DateTime(
      data.date.year,
      data.date.month,
      data.date.day,
      data.start.hour,
      data.start.minute,
    );
    var endAt = DateTime(
      data.date.year,
      data.date.month,
      data.date.day,
      data.end.hour,
      data.end.minute,
    );
    if (!endAt.isAfter(startAt)) {
      endAt = startAt.add(const Duration(hours: 1));
    }
    final inferredPriority =
        data.title.toLowerCase().contains('urgent') ||
            data.title.toLowerCase().contains('high')
        ? SchedulePriority.high
        : SchedulePriority.medium;
    return HomeScheduleItem(
      id: id ?? 'sch_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}',
      title: data.title,
      description: description ?? 'Kegiatan terjadwal',
      startAt: startAt,
      endAt: endAt,
      priority: priority ?? inferredPriority,
      isCompleted: isCompleted,
      rewardedXp: rewardedXp,
    );
  }

  Future<void> _openNotifications() async {
    final result = await Navigator.push<List<HomeNotificationItem>>(
      context,
      MaterialPageRoute<List<HomeNotificationItem>>(
        builder: (_) => HomeNotificationsPage(initialItems: _notifications),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _notifications = result;
    });
    _queuePersist();
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<HomeSettings>(
      context,
      MaterialPageRoute<HomeSettings>(
        builder: (_) => HomeSettingsPage(initialSettings: _settings),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _settings = result;
      final totalSeconds = _settings.pomodoroMinutes * 60;
      if (_pomodoro.phase == PomodoroPhase.idle ||
          _pomodoro.phase == PomodoroPhase.completed) {
        _pomodoro = _pomodoro.copyWith(
          totalSeconds: totalSeconds,
          remainingSeconds: _pomodoro.phase == PomodoroPhase.completed
              ? 0
              : totalSeconds,
          totalSessions: _settings.sessionsPerRound,
          completedSessions: _pomodoro.completedSessions
              .clamp(0, _settings.sessionsPerRound)
              .toInt(),
        );
      } else {
        _pomodoro = _pomodoro.copyWith(
          totalSeconds: totalSeconds,
          totalSessions: _settings.sessionsPerRound,
          completedSessions: _pomodoro.completedSessions
              .clamp(0, _settings.sessionsPerRound)
              .toInt(),
        );
      }
      _appendNotification(
        title: 'Pengaturan diperbarui',
        body:
            'Pomodoro ${result.pomodoroMinutes} menit, target ${result.sessionsPerRound} sesi.',
      );
      _syncPomodoroUi();
    });
    _queuePersist();
  }

  void _toggleAutoStartFromMenu() {
    setState(() {
      _settings = _settings.copyWith(
        autoStartNextSession: !_settings.autoStartNextSession,
      );
      _appendNotification(
        title: 'Auto-start diperbarui',
        body: _settings.autoStartNextSession
            ? 'Sesi berikutnya akan berjalan otomatis.'
            : 'Sesi berikutnya akan dimulai manual.',
      );
    });
    _queuePersist();
  }

  void _applyXpGain(int amount) {
    if (amount <= 0) return;
    var xp = _currentXp + amount;
    while (xp >= _targetXp) {
      xp -= _targetXp;
      _currentLevel += 1;
      _targetXp += 250;
      _appendNotification(
        title: 'Level Up',
        body: 'Selamat! Kamu naik ke Level $_currentLevel.',
      );
    }
    _currentXp = xp;
  }

  void _togglePomodoro() {
    switch (_pomodoro.phase) {
      case PomodoroPhase.running:
        _pausePomodoro();
        break;
      case PomodoroPhase.paused:
        _resumePomodoro();
        break;
      case PomodoroPhase.idle:
      case PomodoroPhase.completed:
        _startPomodoro();
        break;
    }
  }

  void _startPomodoro() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final totalSeconds = _settings.pomodoroMinutes * 60;
    setState(() {
      final shouldResetRound =
          _pomodoro.phase == PomodoroPhase.completed ||
          _pomodoro.completedSessions >= _settings.sessionsPerRound;
      _pomodoro = _pomodoro.copyWith(
        phase: PomodoroPhase.running,
        totalSeconds: totalSeconds,
        remainingSeconds: shouldResetRound || _pomodoro.remainingSeconds <= 0
            ? totalSeconds
            : _pomodoro.remainingSeconds,
        completedSessions: shouldResetRound ? 0 : _pomodoro.completedSessions,
        totalSessions: _settings.sessionsPerRound,
        lastUpdatedMs: now,
      );
      _syncPomodoroUi();
    });
    _startPomodoroTicker();
    _queuePersist();
  }

  void _pausePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _pomodoro = _pomodoro.copyWith(
        phase: PomodoroPhase.paused,
        lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
      );
      _syncPomodoroUi();
    });
    _queuePersist();
  }

  void _resumePomodoro() {
    setState(() {
      _pomodoro = _pomodoro.copyWith(
        phase: PomodoroPhase.running,
        lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
      );
      _syncPomodoroUi();
    });
    _startPomodoroTicker();
    _queuePersist();
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    final totalSeconds = _settings.pomodoroMinutes * 60;
    setState(() {
      _pomodoro = _pomodoro.copyWith(
        phase: PomodoroPhase.idle,
        totalSeconds: totalSeconds,
        remainingSeconds: totalSeconds,
        completedSessions: 0,
        totalSessions: _settings.sessionsPerRound,
        lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
      );
      _appendNotification(
        title: 'Pomodoro di-reset',
        body: 'Sesi kembali ke awal.',
      );
      _syncPomodoroUi();
    });
    _queuePersist();
  }

  void _startPomodoroTicker() {
    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _pomodoro.phase != PomodoroPhase.running) {
        _pomodoroTimer?.cancel();
        return;
      }

      if (_pomodoro.remainingSeconds <= 1) {
        _pomodoroTimer?.cancel();
        setState(() {
          final completed = (_pomodoro.completedSessions + 1)
              .clamp(0, _settings.sessionsPerRound)
              .toInt();
          _applyXpGain(_settings.xpPerPomodoro);
          final totalSeconds = _settings.pomodoroMinutes * 60;
          final isRoundFinished = completed >= _settings.sessionsPerRound;
          _pomodoro = _pomodoro.copyWith(
            phase: isRoundFinished
                ? PomodoroPhase.completed
                : (_settings.autoStartNextSession
                      ? PomodoroPhase.running
                      : PomodoroPhase.paused),
            totalSeconds: totalSeconds,
            remainingSeconds: isRoundFinished ? 0 : totalSeconds,
            completedSessions: completed,
            totalSessions: _settings.sessionsPerRound,
            lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
          );
          _appendNotification(
            title: isRoundFinished
                ? 'Ronde Pomodoro selesai'
                : 'Sesi Pomodoro selesai',
            body: isRoundFinished
                ? 'Semua target sesi tercapai hari ini.'
                : 'Lanjut ke sesi ${completed + 1} saat siap.',
          );
          _syncPomodoroUi();
        });
        if (_pomodoro.phase == PomodoroPhase.running) {
          _startPomodoroTicker();
        }
        _queuePersist();
        return;
      }

      _pomodoro = _pomodoro.copyWith(
        remainingSeconds: _pomodoro.remainingSeconds - 1,
        lastUpdatedMs: DateTime.now().millisecondsSinceEpoch,
      );
      _syncPomodoroUi();
      if (_pomodoro.remainingSeconds % 5 == 0) {
        _queuePersist();
      }
    });
  }

  Future<void> _editSchedule(HomeScheduleItem item) async {
    final result = await _openAddPlanSheet(
      initialDate: item.startAt,
      initialStart: TimeOfDay.fromDateTime(item.startAt),
      initialTitle: item.title,
      initialDurationMinutes: item.endAt.difference(item.startAt).inMinutes,
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedDate = DateUtils.dateOnly(result.date);
      final updated = _createScheduleFromSheet(
        result,
        id: item.id,
        priority: item.priority,
        description: item.description,
        rewardedXp: item.rewardedXp,
        isCompleted: item.isCompleted,
      );
      _schedules = _schedules
          .map((current) => current.id == item.id ? updated : current)
          .toList();
      _refreshSelectedDaySchedules();
      _appendNotification(title: 'Schedule diperbarui', body: updated.title);
    });
    _queuePersist();
  }

  Future<void> _deleteSchedule(HomeScheduleItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus schedule?'),
        content: Text('Schedule "${item.title}" akan dihapus permanen.'),
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
    if (confirmed != true || !mounted) return;
    setState(() {
      _schedules = _schedules
          .where((current) => current.id != item.id)
          .toList();
      _refreshSelectedDaySchedules();
      _appendNotification(title: 'Schedule dihapus', body: item.title);
    });
    _queuePersist();
  }

  void _toggleScheduleComplete(HomeScheduleItem item) {
    setState(() {
      _schedules = _schedules.map((current) {
        if (current.id != item.id) return current;
        final nextCompleted = !current.isCompleted;
        var updated = current.copyWith(isCompleted: nextCompleted);
        if (nextCompleted && !current.rewardedXp) {
          _applyXpGain(40);
          updated = updated.copyWith(rewardedXp: true);
          _appendNotification(
            title: 'Task selesai',
            body: '${current.title} (+40 XP)',
          );
        }
        return updated;
      }).toList();
      _refreshSelectedDaySchedules();
    });
    _queuePersist();
  }

  Future<void> _openScheduleDetail(HomeScheduleItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF8FBFF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        final timeRange =
            '${_formatHour(item.startAt)} - ${_formatHour(item.endAt)}';
        final dayLabel = DateUtils.isSameDay(item.startAt, DateTime.now())
            ? 'Hari ini'
            : '${item.startAt.day}/${item.startAt.month}/${item.startAt.year}';
        final cardColor = item.priority == SchedulePriority.high
            ? const Color(0xFF2563EB)
            : const Color(0xFF6F98DC);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SheetActionIcon(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _SheetActionIcon(
                      icon: item.isCompleted
                          ? Icons.undo_rounded
                          : Icons.check_circle_outline_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        _toggleScheduleComplete(item);
                      },
                    ),
                    const SizedBox(width: 10),
                    _SheetActionIcon(
                      icon: Icons.edit_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        _editSchedule(item);
                      },
                    ),
                    const SizedBox(width: 10),
                    _SheetActionIcon(
                      icon: Icons.delete_outline_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        _deleteSchedule(item);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Color(0xFF16233A),
                              fontWeight: FontWeight.w800,
                              fontSize: 21,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$dayLabel • $timeRange',
                            style: const TextStyle(
                              color: Color(0xFF5F769B),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ScheduleDetailRow(
                  icon: Icons.notes_rounded,
                  title: item.description,
                  subtitle: item.isCompleted
                      ? 'Status: selesai'
                      : 'Status: belum selesai',
                ),
                _ScheduleDetailRow(
                  icon: Icons.notifications_none_rounded,
                  title: '30 menit sebelumnya',
                  subtitle: 'Pengingat schedule',
                ),
                _ScheduleDetailRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'Kalender saya',
                  subtitle: item.location?.trim().isNotEmpty == true
                      ? item.location!
                      : 'Youneka personal calendar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectDate(DateTime date) {
    final picked = DateUtils.dateOnly(date);
    if (DateUtils.isSameDay(_selectedDate, picked)) return;
    setState(() {
      _selectedDate = picked;
      _quickCreateStartAt = null;
      _quickCreateTitleController.clear();
      _refreshSelectedDaySchedules();
    });
    _quickCreateTitleFocusNode.unfocus();
    _queuePersist();
  }

  void _shiftWeek(int direction) {
    if (direction == 0) return;
    final target = DateUtils.dateOnly(
      _selectedDate.add(Duration(days: 7 * direction)),
    );
    setState(() {
      _selectedDate = target;
      _quickCreateStartAt = null;
      _quickCreateTitleController.clear();
      _refreshSelectedDaySchedules();
    });
    _quickCreateTitleFocusNode.unfocus();
    _queuePersist();
  }

  String _formatHour(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ColoredBox(
        color: Color(0xFFF4F6FB),
        child: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Container(
      color: const Color(0xFFF4F6FB),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<_PomodoroUiSnapshot>(
                valueListenable: _pomodoroUi,
                builder: (context, pomodoroUi, _) {
                  final safeTotalSessions = pomodoroUi.totalSessions <= 0
                      ? 1
                      : pomodoroUi.totalSessions;
                  final safeCompletedSessions = pomodoroUi.completedSessions
                      .clamp(0, safeTotalSessions)
                      .toInt();
                  final sessionLabel = switch (pomodoroUi.phase) {
                    PomodoroPhase.idle => 0,
                    PomodoroPhase.completed => safeTotalSessions,
                    PomodoroPhase.running || PomodoroPhase.paused =>
                      (safeCompletedSessions + 1).clamp(1, safeTotalSessions),
                  };
                  final total = pomodoroUi.remainingSeconds
                      .clamp(0, 359999)
                      .toInt();
                  final minutes = (total ~/ 60).toString().padLeft(2, '0');
                  final seconds = (total % 60).toString().padLeft(2, '0');
                  final timerLabel = '$minutes:$seconds';
                  final actionIcon = pomodoroUi.phase == PomodoroPhase.running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded;
                  final perSessionProgress = pomodoroUi.totalSeconds <= 0
                      ? 0.0
                      : (1 -
                                (pomodoroUi.remainingSeconds /
                                    pomodoroUi.totalSeconds))
                            .clamp(0.0, 1.0);
                  final sessionProgresses = List<double>.generate(
                    safeTotalSessions,
                    (index) {
                      if (index < safeCompletedSessions) return 1.0;
                      if (pomodoroUi.phase == PomodoroPhase.completed) {
                        return 1.0;
                      }
                      if (pomodoroUi.phase == PomodoroPhase.running ||
                          pomodoroUi.phase == PomodoroPhase.paused) {
                        return index == safeCompletedSessions
                            ? perSessionProgress
                            : 0.0;
                      }
                      return 0.0;
                    },
                  );
                  final actionTooltip = switch (pomodoroUi.phase) {
                    PomodoroPhase.running => 'Pause Pomodoro',
                    PomodoroPhase.paused => 'Resume Pomodoro',
                    PomodoroPhase.completed => 'Mulai ronde baru',
                    PomodoroPhase.idle => 'Mulai Pomodoro',
                  };
                  final phaseLabel = switch (pomodoroUi.phase) {
                    PomodoroPhase.running => 'Sedang fokus',
                    PomodoroPhase.paused => 'Dijeda',
                    PomodoroPhase.completed => 'Ronde selesai',
                    PomodoroPhase.idle => 'Siap dimulai',
                  };

                  return HomeFocusTopSection(
                    title: 'Focus Mode',
                    subtitle: 'Level $_currentLevel Explorer',
                    currentXp: _currentXp,
                    targetXp: _targetXp,
                    progress: _xpProgress,
                    timerLabel: timerLabel,
                    currentSession: sessionLabel,
                    totalSession: safeTotalSessions,
                    phaseLabel: phaseLabel,
                    sessionProgresses: sessionProgresses,
                    onNotificationTap: () => unawaited(_openNotifications()),
                    onSettingsTap: () => unawaited(_openSettings()),
                    onToggleAutoStartTap: _toggleAutoStartFromMenu,
                    onResetPomodoroTap: _resetPomodoro,
                    settingsSummary:
                        '${_settings.pomodoroMinutes} menit • ${_settings.sessionsPerRound} sesi',
                    autoStartEnabled: _settings.autoStartNextSession,
                    onPlayTap: _togglePomodoro,
                    onPlayLongPress: _resetPomodoro,
                    playIcon: actionIcon,
                    playTooltip: '$actionTooltip (tekan lama untuk reset)',
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: const Color(0xFFE4E9F1)),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: HomeScheduleTimelineSection(
                    selectedDate: _selectedDate,
                    schedules: _selectedDaySchedules,
                    quickCreateStartAt: _quickCreateStartAt,
                    quickCreateTitleController: _quickCreateTitleController,
                    quickCreateTitleFocusNode: _quickCreateTitleFocusNode,
                    onSelectDate: _selectDate,
                    onShiftWeek: _shiftWeek,
                    onCreateScheduleAt: _openQuickCreateComposer,
                    onScheduleTap: (item) =>
                        unawaited(_openScheduleDetail(item)),
                    onQuickCreateDismiss: _dismissQuickCreateComposer,
                    onQuickCreateSave: _saveQuickCreateComposer,
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

class _AddPlanSheet extends StatefulWidget {
  const _AddPlanSheet({
    this.initialDate,
    this.initialStart,
    this.initialTitle,
    this.initialDurationMinutes,
  });

  final DateTime? initialDate;
  final TimeOfDay? initialStart;
  final String? initialTitle;
  final int? initialDurationMinutes;

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final TextEditingController _titleController = TextEditingController();
  int _selectedType = 0;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _start = widget.initialStart ?? TimeOfDay.now();
    final duration = (widget.initialDurationMinutes ?? 60)
        .clamp(5, 240)
        .toInt();
    _end = _addMinutes(_start, duration);
    if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
      _titleController.text = widget.initialTitle!.trim();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedStart = await showTimePicker(
      context: context,
      initialTime: _start,
    );
    if (pickedStart == null || !mounted) return;

    final pickedEnd = await showTimePicker(context: context, initialTime: _end);
    if (pickedEnd == null || !mounted) return;

    final startMinutes = pickedStart.hour * 60 + pickedStart.minute;
    final endMinutes = pickedEnd.hour * 60 + pickedEnd.minute;
    final safeEnd = endMinutes <= startMinutes
        ? _addMinutes(pickedStart, 60)
        : pickedEnd;

    setState(() {
      _date = pickedDate;
      _start = pickedStart;
      _end = safeEnd;
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tugas tidak boleh kosong.')),
      );
      return;
    }
    Navigator.pop(
      context,
      _PlanSheetResultData(title: title, date: _date, start: _start, end: _end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = _buildDateTimeText(date: _date, start: _start, end: _end);
    return Padding(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 10,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1EBDD),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26111827),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {},
                    icon: const Icon(Icons.menu_rounded),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add title',
                    border: UnderlineInputBorder(),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFC8D1E0)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _andrewTeal, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _eventTab(
                      'Event',
                      selected: _selectedType == 0,
                      onTap: () {
                        setState(() => _selectedType = 0);
                      },
                    ),
                    const SizedBox(width: 8),
                    _eventTab(
                      'Task',
                      selected: _selectedType == 1,
                      onTap: () {
                        setState(() => _selectedType = 1);
                      },
                    ),
                    const SizedBox(width: 8),
                    _eventTab(
                      'Appointment schedule',
                      selected: _selectedType == 2,
                      onTap: () {
                        setState(() => _selectedType = 2);
                      },
                      trailing: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _matchaOlive,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                            color: _appWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 24,
                        color: Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          rangeText,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF374151),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 44),
                child: Text(
                  'Time zone | Does not repeat',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'More options',
                      style: TextStyle(
                        color: _matchaOlive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _andrewTeal,
                      foregroundColor: _appWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventTab(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _andrewSoftTeal.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  String _buildDateTimeText({
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
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
    final weekday = weekdays[(date.weekday - 1) % 7];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}   ${_format12h(start)}  -  ${_format12h(end)}';
  }

  String _format12h(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = _two(time.minute);
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute$suffix';
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
  final total = time.hour * 60 + time.minute + minutes;
  final wrapped = total % (24 * 60);
  return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
}

class _AchievementSnapshot {
  const _AchievementSnapshot({
    required this.currentLevel,
    required this.currentXp,
    required this.targetXp,
    required this.totalSchedules,
    required this.completedSchedules,
    required this.totalToday,
    required this.completedToday,
    required this.activeDaysThisWeek,
    required this.currentStreak,
    required this.completedMinutes,
    required this.milestones,
  });

  final int currentLevel;
  final int currentXp;
  final int targetXp;
  final int totalSchedules;
  final int completedSchedules;
  final int totalToday;
  final int completedToday;
  final int activeDaysThisWeek;
  final int currentStreak;
  final int completedMinutes;
  final List<_AchievementMilestone> milestones;

  _AchievementMilestone? get nextMilestone {
    for (final milestone in milestones) {
      if (!milestone.unlocked) return milestone;
    }
    return null;
  }

  factory _AchievementSnapshot.fromHomeState(HomeStateSnapshot? state) {
    if (state == null) {
      return const _AchievementSnapshot(
        currentLevel: 12,
        currentXp: 0,
        targetXp: 2000,
        totalSchedules: 0,
        completedSchedules: 0,
        totalToday: 0,
        completedToday: 0,
        activeDaysThisWeek: 0,
        currentStreak: 0,
        completedMinutes: 0,
        milestones: [],
      );
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = DateUtils.dateOnly(
      today.subtract(Duration(days: today.weekday - 1)),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));
    final completedSchedules = state.schedules
        .where((item) => item.isCompleted)
        .toList();
    final completedCount = completedSchedules.length;
    final totalCount = state.schedules.length;
    final completedToday = state.schedules
        .where(
          (item) =>
              item.isCompleted && DateUtils.isSameDay(item.startAt, today),
        )
        .length;
    final totalToday = state.schedules
        .where((item) => DateUtils.isSameDay(item.startAt, today))
        .length;
    final activeDaysThisWeek = completedSchedules
        .where(
          (item) =>
              !item.startAt.isBefore(weekStart) &&
              item.startAt.isBefore(weekEnd),
        )
        .map((item) => DateUtils.dateOnly(item.startAt))
        .toSet()
        .length;
    final completedMinutes = completedSchedules.fold<int>(
      0,
      (total, item) => total + item.endAt.difference(item.startAt).inMinutes,
    );
    final completedDays = completedSchedules
        .map((item) => DateUtils.dateOnly(item.startAt))
        .toSet();
    var currentStreak = 0;
    var cursor = today;
    while (completedDays.contains(cursor)) {
      currentStreak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return _AchievementSnapshot(
      currentLevel: state.currentLevel,
      currentXp: state.currentXp,
      targetXp: state.targetXp,
      totalSchedules: totalCount,
      completedSchedules: completedCount,
      totalToday: totalToday,
      completedToday: completedToday,
      activeDaysThisWeek: activeDaysThisWeek,
      currentStreak: currentStreak,
      completedMinutes: completedMinutes,
      milestones: [
        _AchievementMilestone(
          order: 1,
          title: 'Langkah pertama',
          description: 'Selesaikan satu schedule pertamamu.',
          tip: 'Tandai 1 task sampai selesai dari timeline harian.',
          reward: 'Membuka jalur progres dan badge dasar.',
          icon: Icons.flag_rounded,
          accent: const Color(0xFF4F7FE8),
          current: completedCount,
          target: 1,
          unit: 'schedule',
        ),
        _AchievementMilestone(
          order: 2,
          title: 'Masuk ritme',
          description: 'Kumpulkan 120 menit task yang benar-benar selesai.',
          tip: 'Gabungkan beberapa task pendek agar cepat menyentuh 2 jam.',
          reward: 'Status konsisten dan peta progres tahap 2.',
          icon: Icons.timer_rounded,
          accent: const Color(0xFFF59E0B),
          current: completedMinutes,
          target: 120,
          unit: 'menit',
        ),
        _AchievementMilestone(
          order: 3,
          title: 'Streak 3 hari',
          description: 'Jaga ritme aktif tiga hari berturut-turut.',
          tip: 'Selalu selesaikan minimal 1 task penting setiap hari.',
          reward: 'Badge api dan reputasi konsisten.',
          icon: Icons.local_fire_department_rounded,
          accent: const Color(0xFFF97316),
          current: currentStreak,
          target: 3,
          unit: 'hari',
        ),
        _AchievementMilestone(
          order: 4,
          title: 'Planner mingguan',
          description: 'Aktif di lima hari dalam satu minggu.',
          tip: 'Sebar task penting ke beberapa hari, jangan menumpuk.',
          reward: 'Template mingguan terasa lebih bernilai.',
          icon: Icons.calendar_month_rounded,
          accent: const Color(0xFF14B8A6),
          current: activeDaysThisWeek,
          target: 5,
          unit: 'hari aktif',
        ),
        _AchievementMilestone(
          order: 5,
          title: 'Eksekutor',
          description: 'Selesaikan sepuluh schedule total.',
          tip: 'Gunakan template agar task rutin lebih cepat diselesaikan.',
          reward: 'Badge premium dan status eksekutor.',
          icon: Icons.workspace_premium_rounded,
          accent: const Color(0xFF7C3AED),
          current: completedCount,
          target: 10,
          unit: 'schedule',
        ),
        _AchievementMilestone(
          order: 6,
          title: 'Naik level',
          description: 'Isi XP hingga level berikutnya.',
          tip: 'Pomodoro selesai dan task selesai sama-sama menambah XP.',
          reward: 'Naik level ke explorer berikutnya.',
          icon: Icons.auto_awesome_rounded,
          accent: const Color(0xFF2563EB),
          current: state.currentXp,
          target: state.targetXp,
          unit: 'XP',
        ),
      ],
    );
  }
}

class _AchievementMilestone {
  const _AchievementMilestone({
    required this.order,
    required this.title,
    required this.description,
    required this.tip,
    required this.reward,
    required this.icon,
    required this.accent,
    required this.current,
    required this.target,
    required this.unit,
  });

  final int order;
  final String title;
  final String description;
  final String tip;
  final String reward;
  final IconData icon;
  final Color accent;
  final int current;
  final int target;
  final String unit;

  bool get unlocked => current >= target;

  double get progress {
    if (target <= 0) return 1;
    return (current / target).clamp(0.0, 1.0);
  }

  int get stars {
    if (unlocked) return 3;
    if (progress >= 0.66) return 2;
    if (progress > 0) return 1;
    return 0;
  }

  String get progressLabel => '$current / $target $unit';
}

class _AndrewAchievementPage extends StatelessWidget {
  const _AndrewAchievementPage();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeStateSnapshot?>(
      future: HomeStateStorage.load(),
      builder: (context, state) {
        final snapshot = _AchievementSnapshot.fromHomeState(state.data);
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF2F7FF), Color(0xFFDCE7F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AndrewSectionHeader(title: 'Prestasi', subtitle: ''),
                  const SizedBox(height: 18),
                  Text(
                    'Peta progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _andrewInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tekan node untuk melihat syarat unlock, progres, dan reward tiap milestone.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: _matchaMuted),
                  ),
                  const SizedBox(height: 16),
                  _AchievementMapSection(
                    milestones: snapshot.milestones,
                    onMilestoneTap: (milestone) =>
                        _showAchievementMilestoneSheet(
                          context: context,
                          milestone: milestone,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showAchievementMilestoneSheet({
  required BuildContext context,
  required _AchievementMilestone milestone,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _appWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14213D).withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: milestone.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        milestone.unlocked
                            ? milestone.icon
                            : Icons.lock_rounded,
                        color: milestone.accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            milestone.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: _andrewInk,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            milestone.unlocked
                                ? 'Milestone sudah terbuka'
                                : 'Milestone berikutnya masih terkunci',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: _matchaMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: milestone.progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE1EAF5),
                    valueColor: AlwaysStoppedAnimation<Color>(milestone.accent),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  milestone.progressLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: milestone.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _AchievementSheetLine(
                  icon: Icons.flag_outlined,
                  title: 'Target',
                  body: milestone.description,
                ),
                const SizedBox(height: 12),
                _AchievementSheetLine(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Tips',
                  body: milestone.tip,
                ),
                const SizedBox(height: 12),
                _AchievementSheetLine(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Reward',
                  body: milestone.reward,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: milestone.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      milestone.unlocked ? 'Lanjutkan' : 'Siap, saya kejar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ignore: unused_element
class _AchievementBadgeData {
  const _AchievementBadgeData({
    required this.title,
    required this.detail,
    required this.icon,
    required this.unlocked,
    required this.accent,
  });

  final String title;
  final String detail;
  final IconData icon;
  final bool unlocked;
  final Color accent;
}

// ignore: unused_element
class _AchievementHeroCard extends StatelessWidget {
  const _AchievementHeroCard({
    required this.level,
    required this.currentXp,
    required this.targetXp,
    required this.xpProgress,
    required this.streakDays,
    required this.unlockedBadges,
  });

  final int level;
  final int currentXp;
  final int targetXp;
  final double xpProgress;
  final int streakDays;
  final int unlockedBadges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F7FE8), Color(0xFF274976)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF274976).withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level Explorer',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unlockedBadges badge terbuka • streak $streakDays hari',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$currentXp / $targetXp XP',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(xpProgress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AchievementMetricCard extends StatelessWidget {
  const _AchievementMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _appWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _matchaGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _matchaMist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _matchaDeep, size: 21),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _matchaMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _andrewInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _matchaMuted),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AchievementFocusCard extends StatelessWidget {
  const _AchievementFocusCard({
    required this.activeDaysThisWeek,
    required this.completionRate,
  });

  final int activeDaysThisWeek;
  final int completionRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _appWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _matchaGold),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _matchaMist,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights_rounded, color: _matchaDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ritme minggu ini',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _andrewInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeDaysThisWeek hari aktif • $completionRate% schedule selesai',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _matchaMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AchievementBadgeTile extends StatelessWidget {
  const _AchievementBadgeTile({required this.badge});

  final _AchievementBadgeData badge;

  @override
  Widget build(BuildContext context) {
    final accent = badge.unlocked ? badge.accent : const Color(0xFFB5C3D9);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badge.unlocked ? _appWhite : const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: badge.unlocked
              ? accent.withValues(alpha: 0.28)
              : const Color(0xFFD7E1EF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: badge.unlocked ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              badge.unlocked ? badge.icon : Icons.lock_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _andrewInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: badge.unlocked ? 0.14 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge.unlocked ? 'Terbuka' : 'Terkunci',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  badge.detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _matchaMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AchievementJourneyHeader extends StatelessWidget {
  const _AchievementJourneyHeader({
    required this.snapshot,
    required this.unlockedCount,
    required this.nextMilestone,
  });

  final _AchievementSnapshot snapshot;
  final int unlockedCount;
  final _AchievementMilestone? nextMilestone;

  @override
  Widget build(BuildContext context) {
    final xpProgress = snapshot.targetXp <= 0
        ? 0.0
        : (snapshot.currentXp / snapshot.targetXp).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5068B8), Color(0xFF9DA2B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C486B).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journey Level ${snapshot.currentLevel}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unlockedCount milestone terbuka • streak ${snapshot.currentStreak} hari',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${snapshot.currentXp} / ${snapshot.targetXp} XP',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(xpProgress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nextMilestone == null
                        ? 'Semua milestone utama sudah terbuka.'
                        : 'Node berikutnya: ${nextMilestone!.title}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

// ignore: unused_element
class _AchievementNextMissionCard extends StatelessWidget {
  const _AchievementNextMissionCard({required this.milestone});

  final _AchievementMilestone? milestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _appWhite,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _matchaGold),
      ),
      child: milestone == null
          ? Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _matchaMist,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: _matchaDeep,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Semua milestone utama sudah kamu buka. Saatnya pertahankan ritme ini.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _andrewInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: milestone!.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        milestone!.icon,
                        color: milestone!.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Misi berikutnya',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: _matchaMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            milestone!.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: _andrewInk,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      milestone!.progressLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: milestone!.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: milestone!.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE1EAF5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      milestone!.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  milestone!.tip,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _matchaMuted),
                ),
              ],
            ),
    );
  }
}

class _AchievementMapSection extends StatelessWidget {
  const _AchievementMapSection({
    required this.milestones,
    required this.onMilestoneTap,
  });

  final List<_AchievementMilestone> milestones;
  final ValueChanged<_AchievementMilestone> onMilestoneTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const sectionHeight = 860.0;
        final positions = <Offset>[
          Offset(width * 0.22, 120),
          Offset(width * 0.68, 240),
          Offset(width * 0.30, 390),
          Offset(width * 0.76, 520),
          Offset(width * 0.22, 670),
          Offset(width * 0.68, 790),
        ];
        return SizedBox(
          height: sectionHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AchievementMapPainter(
                    positions: positions,
                    milestones: milestones,
                  ),
                ),
              ),
              for (
                var index = 0;
                index < milestones.length && index < positions.length;
                index++
              )
                Positioned(
                  left: positions[index].dx - 58,
                  top: positions[index].dy - 58,
                  child: _AchievementMapNode(
                    milestone: milestones[index],
                    onTap: () => onMilestoneTap(milestones[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementMapPainter extends CustomPainter {
  const _AchievementMapPainter({
    required this.positions,
    required this.milestones,
  });

  final List<Offset> positions;
  final List<_AchievementMilestone> milestones;

  @override
  void paint(Canvas canvas, Size size) {
    final decorativePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFA9D4F1).withValues(alpha: 0.55);
    final blobs = <Rect>[
      Rect.fromCenter(
        center: Offset(size.width * 0.18, 90),
        width: 150,
        height: 110,
      ),
      Rect.fromCenter(
        center: Offset(size.width * 0.80, 205),
        width: 138,
        height: 104,
      ),
      Rect.fromCenter(
        center: Offset(size.width * 0.25, 355),
        width: 154,
        height: 112,
      ),
      Rect.fromCenter(
        center: Offset(size.width * 0.74, 500),
        width: 144,
        height: 102,
      ),
      Rect.fromCenter(
        center: Offset(size.width * 0.26, 650),
        width: 160,
        height: 112,
      ),
      Rect.fromCenter(
        center: Offset(size.width * 0.72, 770),
        width: 150,
        height: 106,
      ),
    ];
    for (final rect in blobs) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(36)),
        decorativePaint,
      );
    }

    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14
      ..color = Colors.white.withValues(alpha: 0.78);
    final unlockedPathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14
      ..color = const Color(0xFFC7D8F4);

    final path = Path()..moveTo(positions.first.dx, positions.first.dy);
    for (var i = 1; i < positions.length; i++) {
      final previous = positions[i - 1];
      final current = positions[i];
      final midY = (previous.dy + current.dy) / 2;
      path.cubicTo(previous.dx, midY, current.dx, midY, current.dx, current.dy);
    }
    canvas.drawPath(path, pathPaint);

    final unlockedCount = milestones.where((item) => item.unlocked).length;
    if (unlockedCount > 0) {
      final highlighted = Path()
        ..moveTo(positions.first.dx, positions.first.dy);
      final endIndex = unlockedCount.clamp(1, positions.length) - 1;
      for (var i = 1; i <= endIndex; i++) {
        final previous = positions[i - 1];
        final current = positions[i];
        final midY = (previous.dy + current.dy) / 2;
        highlighted.cubicTo(
          previous.dx,
          midY,
          current.dx,
          midY,
          current.dx,
          current.dy,
        );
      }
      canvas.drawPath(highlighted, unlockedPathPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AchievementMapPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.milestones != milestones;
  }
}

class _AchievementMapNode extends StatelessWidget {
  const _AchievementMapNode({required this.milestone, required this.onTap});

  final _AchievementMilestone milestone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = milestone.unlocked
        ? milestone.accent
        : const Color(0xFF4B3F3F);
    final fill = milestone.unlocked
        ? const Color(0xFFCFE6FB)
        : const Color(0xFFF3F5FA);
    final starColor = milestone.unlocked
        ? const Color(0xFFFFC36D)
        : const Color(0xFFE5E7EB);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 116,
        child: Column(
          children: [
            Container(
              width: 102,
              height: 102,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: milestone.accent.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: milestone.unlocked
                    ? Text(
                        '${milestone.order}',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: _andrewInk,
                              fontWeight: FontWeight.w500,
                            ),
                      )
                    : Icon(Icons.lock_rounded, color: accent, size: 34),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(3, (index) {
                final filled = index < milestone.stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 22,
                    color: filled ? starColor : const Color(0xFFBFC9D8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              milestone.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _andrewInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementSheetLine extends StatelessWidget {
  const _AchievementSheetLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _matchaMist,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _matchaDeep, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _andrewInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _matchaMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AndrewProfilePage extends StatelessWidget {
  const _AndrewProfilePage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF2F7FF), Color(0xFFDDE8F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _AndrewSectionHeader(title: 'Profil', subtitle: ''),
              SizedBox(height: 18),
              _ProfileHeroCard(),
              SizedBox(height: 16),
              _ProfileSectionTitle('Ringkasan'),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ProfileMetricCard(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Level',
                      value: '12',
                      detail: 'Explorer',
                      color: _andrewTeal,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _ProfileMetricCard(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Streak',
                      value: '6 hari',
                      detail: 'Masih aktif',
                      color: _matchaOlive,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _ProfileSectionTitle('Akun'),
              SizedBox(height: 10),
              _ProfileActionTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit profil',
                subtitle: 'Ubah nama, foto, dan bio singkat.',
              ),
              _ProfileActionTile(
                icon: Icons.notifications_none_rounded,
                title: 'Preferensi notifikasi',
                subtitle: 'Atur pengingat fokus dan jadwal.',
              ),
              _ProfileActionTile(
                icon: Icons.lock_outline_rounded,
                title: 'Privasi dan keamanan',
                subtitle: 'Kelola keamanan akun dan data.',
              ),
              SizedBox(height: 16),
              _ProfileSectionTitle('Aktivitas'),
              SizedBox(height: 10),
              _ProfileInfoCard(
                title: 'Target minggu ini',
                body: 'Selesaikan 8 sesi fokus dan review 5 schedule penting.',
                accent: _matchaGold,
              ),
              SizedBox(height: 10),
              _ProfileInfoCard(
                title: 'Mentor favorit',
                body: 'Andrew paling sering membantu memulai sesi pagi.',
                accent: _andrewTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _appWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _matchaGold),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10111827),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _matchaMist,
              shape: BoxShape.circle,
              border: Border.all(color: _matchaGold),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 36,
              color: _andrewTeal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lingga',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _andrewInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level 12 Explorer',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _matchaMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _ProfileBadge(
                      icon: Icons.timer_outlined,
                      label: '4j 20m fokus',
                    ),
                    _ProfileBadge(
                      icon: Icons.check_circle_outline_rounded,
                      label: '14 tugas selesai',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _matchaMist,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _andrewTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _andrewInk,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: _andrewInk,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  const _ProfileMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _appWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12111827),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _matchaMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: _andrewInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _matchaMuted),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _appWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _matchaGold),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _matchaMist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _andrewTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _andrewInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _matchaMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: _matchaMuted),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _appWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _andrewInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _matchaMuted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SheetActionIcon extends StatelessWidget {
  const _SheetActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFE7EDF8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _andrewInk),
      ),
    );
  }
}

class _ScheduleDetailRow extends StatelessWidget {
  const _ScheduleDetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Icon(icon, color: const Color(0xFF5F769B), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF16233A),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A8EAB),
                    fontSize: 14,
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

class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid();

  @override
  Widget build(BuildContext context) {
    final templates = DiagramTemplate.presets;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 720;
        final int crossAxisCount = isNarrow ? 1 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 220,
            crossAxisSpacing: 20,
            mainAxisSpacing: 24,
          ),
          itemCount: templates.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _TemplateCard(
                template: DiagramTemplate.blankCanvas,
                onOpen: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlowEditorScreen(
                        diagram: FlowDiagram.blank(),
                        title: 'Rencana baru',
                      ),
                    ),
                  );
                },
              );
            }
            final template = templates[index - 1];
            return _TemplateCard(
              template: template,
              onOpen: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FlowEditorScreen(
                      diagram: template.buildDiagram(),
                      title: template.title,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onOpen});

  final DiagramTemplate template;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: _appWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F111827),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Container(
                  width: double.infinity,
                  color: template.previewColor,
                  child: template.previewBuilder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
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

class FlowEditorScreen extends StatefulWidget {
  const FlowEditorScreen({
    super.key,
    required this.diagram,
    required this.title,
  });

  final FlowDiagram diagram;
  final String title;

  @override
  State<FlowEditorScreen> createState() => _FlowEditorScreenState();
}

class _FlowEditorScreenState extends State<FlowEditorScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();
  final ValueNotifier<double> _viewportScale = ValueNotifier<double>(1.0);
  final Size _canvasSize = const Size(2400, 1600);

  final List<FlowNode> _nodes = [];
  final List<FlowConnection> _connections = [];

  int _lastScaleSyncUs = 0;
  String? _selectedNodeId;
  String? _connectionFromNodeId;
  bool _showGrid = true;
  String? _editingNodeId;
  final TextEditingController _inlineEditController = TextEditingController();
  final FocusNode _inlineEditFocusNode = FocusNode();
  OverlayEntry? _spawnMenuEntry;

  int _nodeCounter = 1;
  int _connectionCounter = 1;
  String? _draggingNodeId;
  Offset? _lastScenePosition;
  String? _resizingNodeId;
  ResizeHandlePosition? _resizeHandle;

  @override
  void initState() {
    super.initState();
    _inlineEditFocusNode.addListener(() {
      if (!_inlineEditFocusNode.hasFocus) {
        _endInlineEdit();
      }
    });
    _loadDiagram(widget.diagram);
  }

  @override
  void dispose() {
    _removeSpawnMenu();
    _transformController.dispose();
    _viewportScale.dispose();
    _inlineEditController.dispose();
    _inlineEditFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FlowEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagram != widget.diagram) {
      _loadDiagram(widget.diagram);
    }
  }

  void _removeSpawnMenu() {
    _spawnMenuEntry?.remove();
    _spawnMenuEntry = null;
  }

  void _loadDiagram(FlowDiagram diagram) {
    _endInlineEdit(commit: false);
    _removeSpawnMenu();
    _nodes
      ..clear()
      ..addAll(diagram.nodes.map((node) => node.copy()));
    _connections
      ..clear()
      ..addAll(diagram.connections.map((connection) => connection.copy()));
    _nodeCounter = _nextIndex('node_', _nodes.map((n) => n.id));
    _connectionCounter = _nextIndex('conn_', _connections.map((n) => n.id));
    _selectedNodeId = _nodes.isNotEmpty ? _nodes.first.id : null;
    _connectionFromNodeId = null;
    _transformController.value = Matrix4.identity();
    _viewportScale.value = 1.0;
    _lastScaleSyncUs = 0;
  }

  int _nextIndex(String prefix, Iterable<String> ids) {
    final ints = ids
        .where((id) => id.startsWith(prefix))
        .map((id) => int.tryParse(id.substring(prefix.length)))
        .whereType<int>();
    if (ints.isEmpty) return 1;
    return ints.reduce(max) + 1;
  }

  FlowNode _createNode(FlowNodeType type, {Offset? position}) {
    final style = type.style;
    return FlowNode(
      id: 'node_${_nodeCounter++}',
      type: type,
      position:
          position ??
          Offset(240 + _nodes.length * 60, 200 + _nodes.length * 40),
      size: style.defaultSize,
      text: style.defaultLabel,
    );
  }

  FlowConnection _createConnection(String fromId, String toId) {
    return FlowConnection(
      id: 'conn_${_connectionCounter++}',
      fromId: fromId,
      toId: toId,
    );
  }

  FlowNode? get _selectedNode => _selectedNodeId == null
      ? null
      : _nodes.firstWhereOrNull((n) => n.id == _selectedNodeId);

  bool get _isConnecting => _connectionFromNodeId != null;
  bool get _isNodeInteraction =>
      _draggingNodeId != null || _resizingNodeId != null;

  void _addNode(FlowNodeType type) {
    _endInlineEdit();
    _removeSpawnMenu();
    setState(() {
      final center = _viewportCenter();
      final node = _createNode(
        type,
        position: Offset(
          (center.dx - type.style.defaultSize.width / 2).clamp(
            0.0,
            _canvasSize.width - type.style.defaultSize.width,
          ),
          (center.dy - type.style.defaultSize.height / 2).clamp(
            0.0,
            _canvasSize.height - type.style.defaultSize.height,
          ),
        ),
      );
      _nodes.add(node);
      _selectedNodeId = node.id;
      _connectionFromNodeId = null;
    });
  }

  Offset _viewportCenter() {
    final inverted = Matrix4.copy(_transformController.value);
    final determinant = inverted.invert();
    if (determinant == 0.0) {
      return Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    }
    final viewportSize = context.size ?? const Size(800, 600);
    final vector = Vector3(viewportSize.width / 2, viewportSize.height / 2, 0);
    inverted.transform3(vector);
    return Offset(vector.x, vector.y);
  }

  void _handleNodeTap(String nodeId) {
    if (_editingNodeId != null && _editingNodeId != nodeId) {
      _endInlineEdit();
    }
    _removeSpawnMenu();
    setState(() {
      if (_connectionFromNodeId != null) {
        if (_connectionFromNodeId == nodeId) {
          _connectionFromNodeId = null;
        } else {
          _completeConnection(nodeId);
        }
      } else {
        _selectedNodeId = nodeId;
      }
    });
  }

  void _startInlineEdit(FlowNode node) {
    _endInlineEdit();
    _removeSpawnMenu();
    final text = node.text;
    _inlineEditController
      ..text = text
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
    setState(() {
      _editingNodeId = node.id;
      _selectedNodeId = node.id;
    });
    Future.microtask(() {
      if (mounted) {
        _inlineEditFocusNode.requestFocus();
      }
    });
  }

  void _updateInlineEdit(String nodeId, String value) {
    final node = _nodes.firstWhereOrNull((n) => n.id == nodeId);
    if (node == null || node.text == value) {
      return;
    }
    setState(() {
      node.text = value;
    });
  }

  void _endInlineEdit({bool commit = true}) {
    final editingId = _editingNodeId;
    if (editingId == null) return;
    final node = _nodes.firstWhereOrNull((n) => n.id == editingId);
    if (commit && node != null) {
      final value = _inlineEditController.text.trim();
      setState(() {
        node.text = value.isEmpty ? node.type.style.defaultLabel : value;
        _editingNodeId = null;
      });
    } else {
      setState(() {
        _editingNodeId = null;
      });
    }
    if (_inlineEditFocusNode.hasFocus) {
      _inlineEditFocusNode.unfocus();
    }
    _inlineEditController.clear();
  }

  void _startConnection() {
    if (_selectedNodeId == null) return;
    setState(() {
      _connectionFromNodeId = _selectedNodeId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pilih simpul tujuan untuk membuat koneksi.'),
      ),
    );
  }

  void _completeConnection(String targetId) {
    final from = _connectionFromNodeId;
    if (from == null || from == targetId) {
      setState(() => _connectionFromNodeId = null);
      return;
    }
    final exists = _connections.any(
      (connection) => connection.fromId == from && connection.toId == targetId,
    );
    if (exists) {
      setState(() {
        _connectionFromNodeId = null;
        _selectedNodeId = targetId;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sambungan sudah ada.')));
      return;
    }
    setState(() {
      _connections.add(_createConnection(from, targetId));
      _connectionFromNodeId = null;
      _selectedNodeId = targetId;
    });
  }

  void _toggleGrid() {
    setState(() => _showGrid = !_showGrid);
  }

  void _resetViewport() {
    _transformController.value = Matrix4.identity();
    _viewportScale.value = 1.0;
    _lastScaleSyncUs = 0;
  }

  void _syncViewportScale({bool force = false}) {
    final next = _transformController.value.getMaxScaleOnAxis();
    final current = _viewportScale.value;
    if ((next - current).abs() < 0.0001) {
      return;
    }
    if (!force) {
      final nowUs = DateTime.now().microsecondsSinceEpoch;
      if ((next - current).abs() < 0.01) {
        return;
      }
      if (nowUs - _lastScaleSyncUs < 33000) {
        return;
      }
      _lastScaleSyncUs = nowUs;
    }
    _viewportScale.value = next;
  }

  void _clearSelection() {
    _endInlineEdit();
    _removeSpawnMenu();
    setState(() {
      _selectedNodeId = null;
      _connectionFromNodeId = null;
    });
  }

  void _deleteSelected() {
    final selected = _selectedNode;
    if (selected == null) return;
    setState(() {
      _nodes.removeWhere((node) => node.id == selected.id);
      _connections.removeWhere(
        (connection) =>
            connection.fromId == selected.id || connection.toId == selected.id,
      );
      _selectedNodeId = null;
      _connectionFromNodeId = null;
    });
  }

  void _duplicateSelected() {
    final selected = _selectedNode;
    if (selected == null) return;
    setState(() {
      final copy = selected.copy(
        id: 'node_${_nodeCounter++}',
        position: selected.position + const Offset(80, 80),
        text: '${selected.text} (salinan)',
      );
      _nodes.add(copy);
      _selectedNodeId = copy.id;
    });
  }

  void _handleSpawnRequest(
    FlowNode origin,
    SpawnDirection direction,
    Offset globalPosition,
  ) {
    _endInlineEdit();
    _removeSpawnMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showSpawnMenu(origin, direction, globalPosition);
    });
  }

  void _showSpawnMenu(
    FlowNode origin,
    SpawnDirection direction,
    Offset globalPosition,
  ) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;
    final renderObject = overlayState.context.findRenderObject();
    if (renderObject is! RenderBox) return;
    final renderBox = renderObject;

    final overlaySize = renderBox.size;
    final Offset anchor = renderBox.globalToLocal(globalPosition);
    const double cardWidth = 220;
    const double cardHeight = 240;

    double left;
    double top;
    switch (direction) {
      case SpawnDirection.top:
        left = anchor.dx - cardWidth / 2;
        top = anchor.dy - cardHeight - 16;
        break;
      case SpawnDirection.bottom:
        left = anchor.dx - cardWidth / 2;
        top = anchor.dy + 16;
        break;
      case SpawnDirection.left:
        left = anchor.dx - cardWidth - 16;
        top = anchor.dy - cardHeight / 2;
        break;
      case SpawnDirection.right:
        left = anchor.dx + 16;
        top = anchor.dy - cardHeight / 2;
        break;
    }

    left = left.clamp(16.0, overlaySize.width - cardWidth - 16.0);
    top = top.clamp(16.0, overlaySize.height - cardHeight - 16.0);

    final entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeSpawnMenu,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: _SpawnMenuCard(
                origin: origin,
                onSelect: (type) {
                  _removeSpawnMenu();
                  _spawnNodeFrom(origin, type, direction);
                },
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(entry);
    _spawnMenuEntry = entry;
  }

  void _spawnNodeFrom(
    FlowNode origin,
    FlowNodeType type,
    SpawnDirection direction,
  ) {
    final Size size = type.style.defaultSize;
    const double gap = 72;

    double x = origin.position.dx + (origin.size.width / 2) - (size.width / 2);
    double y =
        origin.position.dy + (origin.size.height / 2) - (size.height / 2);

    switch (direction) {
      case SpawnDirection.top:
        y = origin.position.dy - gap - size.height;
        break;
      case SpawnDirection.bottom:
        y = origin.position.dy + origin.size.height + gap;
        break;
      case SpawnDirection.left:
        x = origin.position.dx - gap - size.width;
        break;
      case SpawnDirection.right:
        x = origin.position.dx + origin.size.width + gap;
        break;
    }

    final double maxX = _canvasSize.width - size.width;
    final double maxY = _canvasSize.height - size.height;

    x = x.clamp(0.0, maxX);
    y = y.clamp(0.0, maxY);

    final FlowNode newNode = _createNode(type, position: Offset(x, y));

    setState(() {
      _nodes.add(newNode);
      _connections.add(_createConnection(origin.id, newNode.id));
      _selectedNodeId = newNode.id;
      _connectionFromNodeId = null;
    });
  }

  void _exportDiagram() {
    final diagram = FlowDiagram(nodes: _nodes, connections: _connections);
    final encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert(diagram.toJson());
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _appWhite,
          title: const Text('Data diagram (JSON)'),
          content: SizedBox(width: 480, child: SelectableText(encoded)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(widget.title),
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        actions: [
          IconButton(
            tooltip: _showGrid ? 'Sembunyikan grid' : 'Tampilkan grid',
            onPressed: _toggleGrid,
            icon: Icon(_showGrid ? Icons.grid_off : Icons.grid_on),
          ),
          IconButton(
            tooltip: 'Reset tampilan',
            onPressed: _resetViewport,
            icon: const Icon(Icons.center_focus_strong),
          ),
          IconButton(
            tooltip: 'Ekspor diagram (JSON)',
            onPressed: _exportDiagram,
            icon: const Icon(Icons.ios_share),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          EditorRail(
            selectedNodeExists: _selectedNode != null,
            isConnecting: _isConnecting,
            onAddNode: _addNode,
            onStartConnection: _startConnection,
            onDuplicate: _duplicateSelected,
            onDelete: _deleteSelected,
            onEdit: () {
              final node = _selectedNode;
              if (node != null) {
                _startInlineEdit(node);
              }
            },
          ),
          Expanded(child: _buildCanvas()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNode(FlowNodeType.process),
        label: const Text('Tambah simpul'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCanvas() {
    return GestureDetector(
      onTap: _clearSelection,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: const Color(0xFFF8FAFF),
        child: InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(800),
          minScale: 0.4,
          maxScale: 2.8,
          panEnabled: !_isNodeInteraction,
          scaleEnabled: _resizingNodeId == null,
          onInteractionUpdate: (_) => _syncViewportScale(),
          onInteractionEnd: (_) => _syncViewportScale(force: true),
          child: SizedBox(
            key: _canvasKey,
            width: _canvasSize.width,
            height: _canvasSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_showGrid)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _viewportScale,
                        builder: (context, scale, _) {
                          return CustomPaint(
                            painter: FlowGridPainter(scale: scale),
                          );
                        },
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: ConnectionPainter(
                        nodes: _nodes,
                        connections: _connections,
                        highlightFrom: _connectionFromNodeId,
                      ),
                    ),
                  ),
                ),
                for (final node in _nodes)
                  Positioned(
                    left: node.position.dx,
                    top: node.position.dy,
                    child: FlowNodeWidget(
                      node: node,
                      isSelected: node.id == _selectedNodeId,
                      isConnectionSource: node.id == _connectionFromNodeId,
                      onTap: _handleNodeTap,
                      onDragStart: _onNodeDragStart,
                      onDragUpdate: _onNodeDragUpdate,
                      onDragEnd: _onNodeDragEnd,
                      onRequestEdit: _startInlineEdit,
                      isEditing: node.id == _editingNodeId,
                      editController: node.id == _editingNodeId
                          ? _inlineEditController
                          : null,
                      editFocusNode: node.id == _editingNodeId
                          ? _inlineEditFocusNode
                          : null,
                      onTextChanged: (value) =>
                          _updateInlineEdit(node.id, value),
                      onEditingComplete: _endInlineEdit,
                    ),
                  ),
                if (_selectedNode != null)
                  _SelectionOverlay(
                    node: _selectedNode!,
                    onResizeStart: (handle, position) =>
                        _onResizeStart(_selectedNodeId!, handle, position),
                    onResizeUpdate: _onResizeUpdate,
                    onResizeEnd: _onResizeEnd,
                    onEditRequested: () => _startInlineEdit(_selectedNode!),
                    onDuplicateRequested: _duplicateSelected,
                    onDeleteRequested: _deleteSelected,
                    onConnectRequested: _startConnection,
                    onSpawnRequested: (node, direction, position) =>
                        _handleSpawnRequest(node, direction, position),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onNodeDragStart(String nodeId, Offset globalPosition) {
    final scene = _globalToScene(globalPosition);
    if (scene == null) return;
    _draggingNodeId = nodeId;
    _lastScenePosition = scene;
  }

  void _onNodeDragUpdate(String nodeId, Offset globalPosition) {
    if (_draggingNodeId != nodeId) return;
    final scene = _globalToScene(globalPosition);
    final previous = _lastScenePosition;
    final node = _nodes.firstWhereOrNull((n) => n.id == nodeId);
    if (scene == null || previous == null || node == null) return;
    final delta = scene - previous;
    if (delta.distanceSquared < 0.0004) {
      _lastScenePosition = scene;
      return;
    }
    setState(() {
      final next = node.position + delta;
      final clampedX = next.dx.clamp(0.0, _canvasSize.width - node.size.width);
      final clampedY = next.dy.clamp(
        0.0,
        _canvasSize.height - node.size.height,
      );
      node.position = Offset(clampedX, clampedY);
      _selectedNodeId = nodeId;
    });
    _lastScenePosition = scene;
  }

  void _onNodeDragEnd(String nodeId) {
    if (_draggingNodeId == nodeId) {
      _draggingNodeId = null;
      _lastScenePosition = null;
    }
  }

  Offset? _globalToScene(Offset globalPosition) {
    final renderObject = _canvasKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    final local = renderObject.globalToLocal(globalPosition);
    return _transformController.toScene(local);
  }

  void _onResizeStart(
    String nodeId,
    ResizeHandlePosition handle,
    Offset globalPosition,
  ) {
    final scene = _globalToScene(globalPosition);
    if (scene == null) return;
    _resizingNodeId = nodeId;
    _resizeHandle = handle;
    _lastScenePosition = scene;
  }

  void _onResizeUpdate(Offset globalPosition) {
    final nodeId = _resizingNodeId;
    final handle = _resizeHandle;
    final node = _nodes.firstWhereOrNull((n) => n.id == nodeId);
    final previous = _lastScenePosition;
    final scene = _globalToScene(globalPosition);
    if (nodeId == null ||
        handle == null ||
        node == null ||
        scene == null ||
        previous == null) {
      return;
    }

    final delta = scene - previous;
    if (delta.distanceSquared < 0.0004) {
      _lastScenePosition = scene;
      return;
    }
    double left = node.position.dx;
    double top = node.position.dy;
    double right = left + node.size.width;
    double bottom = top + node.size.height;
    const minSize = 80.0;

    switch (handle) {
      case ResizeHandlePosition.topLeft:
        left = (left + delta.dx).clamp(0.0, right - minSize);
        top = (top + delta.dy).clamp(0.0, bottom - minSize);
        break;
      case ResizeHandlePosition.topRight:
        right = (right + delta.dx).clamp(left + minSize, _canvasSize.width);
        top = (top + delta.dy).clamp(0.0, bottom - minSize);
        break;
      case ResizeHandlePosition.bottomLeft:
        left = (left + delta.dx).clamp(0.0, right - minSize);
        bottom = (bottom + delta.dy).clamp(top + minSize, _canvasSize.height);
        break;
      case ResizeHandlePosition.bottomRight:
        right = (right + delta.dx).clamp(left + minSize, _canvasSize.width);
        bottom = (bottom + delta.dy).clamp(top + minSize, _canvasSize.height);
        break;
    }

    final width = max(minSize, right - left);
    final height = max(minSize, bottom - top);

    setState(() {
      final clampedLeft = left.clamp(0.0, _canvasSize.width - minSize);
      final clampedTop = top.clamp(0.0, _canvasSize.height - minSize);
      node.position = Offset(clampedLeft, clampedTop);
      node.size = Size(
        min(width, _canvasSize.width - clampedLeft),
        min(height, _canvasSize.height - clampedTop),
      );
    });

    _lastScenePosition = scene;
  }

  void _onResizeEnd() {
    _resizingNodeId = null;
    _resizeHandle = null;
    _lastScenePosition = null;
  }
}

class EditorRail extends StatelessWidget {
  const EditorRail({
    super.key,
    required this.selectedNodeExists,
    required this.isConnecting,
    required this.onAddNode,
    required this.onStartConnection,
    required this.onDuplicate,
    required this.onDelete,
    required this.onEdit,
  });

  final bool selectedNodeExists;
  final bool isConnecting;
  final void Function(FlowNodeType type) onAddNode;
  final VoidCallback onStartConnection;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      margin: const EdgeInsets.only(left: 12, top: 20, bottom: 20),
      decoration: BoxDecoration(
        color: _appWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(vertical: 16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final type in FlowNodeType.values)
                _RailButton(
                  icon: type.icon,
                  tooltip: 'Tambah ${type.shortLabel.toLowerCase()}',
                  onTap: () => onAddNode(type),
                ),
              const _RailDivider(),
              _RailButton(
                icon: Icons.mode_edit_outline,
                tooltip: 'Edit simpul',
                onTap: selectedNodeExists ? onEdit : null,
              ),
              _RailButton(
                icon: Icons.merge_type,
                tooltip: isConnecting ? 'Pilih simpul tujuan' : 'Buat koneksi',
                highlighted: isConnecting,
                onTap: selectedNodeExists ? onStartConnection : null,
              ),
              _RailButton(
                icon: Icons.copy,
                tooltip: 'Duplikasi simpul',
                onTap: selectedNodeExists ? onDuplicate : null,
              ),
              _RailButton(
                icon: Icons.delete_outline,
                tooltip: 'Hapus simpul',
                destructive: true,
                onTap: selectedNodeExists ? onDelete : null,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.highlighted = false,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final Color accent = destructive
        ? const Color(0xFFE11D48)
        : highlighted
        ? _matchaDeep
        : _matchaInk;
    final Color background = highlighted
        ? _matchaSoft.withOpacity(0.45)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: enabled ? onTap : null,
            icon: Icon(icon),
            color: enabled ? accent : const Color(0xFFCFC8A9),
            disabledColor: const Color(0xFFD1D5DB),
            splashRadius: 28,
          ),
        ),
      ),
    );
  }
}
