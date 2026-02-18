import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../../core/services/app_data_portability_service.dart';
import '../../core/services/app_locale_service.dart';
import '../../core/services/plan_template_bridge.dart';
import '../mentor/presentation/mentor_chat_popup_dialog.dart';
import '../shell/presentation/youneka_home_shell.dart';

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
        ? const Color(0xFF4F46E5)
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
                ? const Color(0x224F46E5)
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
        color: Colors.white,
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
      color: Colors.white,
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
                    color: const Color(0xFFEFF2FF),
                    border: Border.all(
                      color: const Color(0xFF4F46E5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.subdirectory_arrow_right,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tambah  serupa',
                        style: const TextStyle(
                          color: Color(0xFF312E81),
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
    final Color border = isPrimary
        ? const Color(0xFF4F46E5)
        : const Color(0xFFE2E8F0);
    final Color iconColor = isPrimary
        ? const Color(0xFF4F46E5)
        : const Color(0xFF1F2937);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.2),
          color: Colors.white,
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
      ..color = const Color(0xFFD7DDF3).withValues(alpha: opacityFactor)
      ..strokeWidth = 1;
    final Paint majorPaint = Paint()
      ..color = const Color(0xFFCBD5F5).withValues(alpha: (opacityFactor + 0.1))
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
      ..color = const Color(0xFFCBD5F5);

    final Paint highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF4F46E5);

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
    previewColor: const Color(0xFFF1F5F9),
    previewBuilder: _BlankPreview.new,
    buildDiagram: FlowDiagram.blank,
  );

  static final List<DiagramTemplate> presets = [
    DiagramTemplate(
      id: 'focus_sprint',
      title: 'Sesi fokus 25 menit',
      description:
          'Mulai cepat, lindungi fokus, lalu tutup dengan review singkat.',
      previewColor: const Color(0xFFE6F7F4),
      previewBuilder: () => const _TemplatePreview(
        nodes: [
          _PreviewNodeData(
            position: Offset(0.08, 0.15),
            size: Size(0.28, 0.24),
            color: Color(0xFF34D399),
            borderRadius: 32,
            label: 'Mulai fokus',
          ),
          _PreviewNodeData(
            position: Offset(0.45, 0.15),
            size: Size(0.34, 0.24),
            color: Color(0xFF4F46E5),
            borderRadius: 22,
            label: '1 target',
          ),
          _PreviewNodeData.diamond(
            position: Offset(0.23, 0.52),
            size: Size(0.36, 0.3),
            color: Color(0xFFFBBF24),
            label: 'Terdistraksi?',
          ),
          _PreviewNodeData(
            position: Offset(0.63, 0.55),
            size: Size(0.28, 0.24),
            color: Color(0xFF38BDF8),
            borderRadius: 20,
            label: 'Kembali fokus',
          ),
        ],
        connections: [
          _PreviewConnectionData(0, 1, Color(0xFF4F46E5)),
          _PreviewConnectionData(1, 2, Color(0xFF4F46E5)),
          _PreviewConnectionData(2, 3, Color(0xFF4F46E5)),
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
      previewColor: const Color(0xFFEFF6FF),
      previewBuilder: () => const _TemplatePreview(
        nodes: [
          _PreviewNodeData(
            position: Offset(0.12, 0.18),
            size: Size(0.3, 0.22),
            color: Color(0xFF34D399),
            borderRadius: 30,
            label: 'Catat tugas',
          ),
          _PreviewNodeData(
            position: Offset(0.48, 0.12),
            size: Size(0.32, 0.24),
            color: Color(0xFF60A5FA),
            borderRadius: 24,
            label: 'Kelompokkan',
          ),
          _PreviewNodeData.diamond(
            position: Offset(0.28, 0.5),
            size: Size(0.34, 0.32),
            color: Color(0xFFF9A8D4),
            label: 'Prioritas?',
          ),
          _PreviewNodeData(
            position: Offset(0.68, 0.5),
            size: Size(0.28, 0.24),
            color: Color(0xFF2DD4BF),
            borderRadius: 22,
            label: 'Blok waktu',
          ),
        ],
        connections: [
          _PreviewConnectionData(0, 1, Color(0xFF0284C7)),
          _PreviewConnectionData(1, 2, Color(0xFF0284C7)),
          _PreviewConnectionData(2, 3, Color(0xFF0284C7)),
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
      previewColor: const Color(0xFFFFF1E6),
      previewBuilder: () => const _TemplatePreview(
        nodes: [
          _PreviewNodeData(
            position: Offset(0.1, 0.15),
            size: Size(0.28, 0.24),
            color: Color(0xFFF97316),
            borderRadius: 22,
            label: 'Pemicu',
          ),
          _PreviewNodeData(
            position: Offset(0.44, 0.15),
            size: Size(0.32, 0.24),
            color: Color(0xFF4F46E5),
            borderRadius: 22,
            label: 'Tarik napas',
          ),
          _PreviewNodeData(
            position: Offset(0.72, 0.18),
            size: Size(0.32, 0.24),
            color: Color(0xFF22D3EE),
            borderRadius: 22,
            label: 'Mulai 5m',
          ),
          _PreviewNodeData.parallelogram(
            position: Offset(0.28, 0.55),
            size: Size(0.32, 0.26),
            color: Color(0xFFFB7185),
            label: 'Checkpoint',
          ),
          _PreviewNodeData(
            position: Offset(0.64, 0.56),
            size: Size(0.28, 0.24),
            color: Color(0xFF34D399),
            borderRadius: 24,
            label: 'Rayakan',
          ),
        ],
        connections: [
          _PreviewConnectionData(0, 1, Color(0xFFF97316)),
          _PreviewConnectionData(1, 2, Color(0xFF4F46E5)),
          _PreviewConnectionData(1, 3, Color(0xFF4F46E5)),
          _PreviewConnectionData(3, 4, Color(0xFF34D399)),
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
                color: Colors.white,
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
                color: Colors.white,
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
                color: Colors.white,
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
    fillColor: Color(0xFF34D399),
    borderColor: Color(0xFF059669),
    shape: FlowShape.stadium,
    textColor: Colors.white,
    borderRadius: 32,
  ),
  FlowNodeType.process: FlowNodeStyle(
    defaultSize: Size(220, 120),
    defaultLabel: 'Langkah proses',
    fillColor: Color(0xFFEEF2FF),
    borderColor: Color(0xFF4F46E5),
    shape: FlowShape.rounded,
    textColor: Color(0xFF1F2937),
    borderRadius: 24,
  ),
  FlowNodeType.decision: FlowNodeStyle(
    defaultSize: Size(200, 200),
    defaultLabel: 'Keputusan?',
    fillColor: Color(0xFFFDE68A),
    borderColor: Color(0xFFF59E0B),
    shape: FlowShape.diamond,
    textColor: Color(0xFF92400E),
    borderRadius: 20,
  ),
  FlowNodeType.data: FlowNodeStyle(
    defaultSize: Size(220, 120),
    defaultLabel: 'Data / IO',
    fillColor: Color(0xFFBFDBFE),
    borderColor: Color(0xFF2563EB),
    shape: FlowShape.parallelogram,
    textColor: Color(0xFF1E3A8A),
    borderRadius: 20,
  ),
  FlowNodeType.terminator: FlowNodeStyle(
    defaultSize: Size(160, 72),
    defaultLabel: 'Selesai',
    fillColor: Color(0xFFFECACA),
    borderColor: Color(0xFFDC2626),
    shape: FlowShape.stadium,
    textColor: Color(0xFF881337),
    borderRadius: 32,
  ),
  FlowNodeType.note: FlowNodeStyle(
    defaultSize: Size(220, 140),
    defaultLabel: 'Catatan penting',
    fillColor: Color(0xFFFFF7ED),
    borderColor: Color(0xFFF97316),
    shape: FlowShape.rectangle,
    textColor: Color(0xFF92400E),
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
                  border: Border.all(
                    color: const Color(0xFF4F46E5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(
                    style.shape == FlowShape.stadium
                        ? node.size.height
                        : style.borderRadius + 4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x244F46E5),
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
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F46E5), width: 1.6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A4F46E5),
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
                  color: Color(0xFF4F46E5),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4F46E5), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x224F46E5),
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

const Color _andrewInk = Color(0xFF0F172A);
const Color _andrewTeal = Color(0xFF0F766E);
const Color _andrewCream = Color(0xFFF8F6F2);
const Color _andrewSoftTeal = Color(0xFFCCFBF1);

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
            backgroundColor: Colors.white,
            foregroundColor: _andrewInk,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIconColor: const Color(0xFF94A3B8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: _andrewTeal,
              foregroundColor: Colors.white,
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
            backgroundColor: Colors.white,
            indicatorColor: _andrewSoftTeal,
            height: 72,
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              final base =
                  textTheme.labelSmall ?? const TextStyle(fontSize: 12);
              final color = states.contains(MaterialState.selected)
                  ? _andrewTeal
                  : const Color(0xFF94A3B8);
              return base.copyWith(fontWeight: FontWeight.w600, color: color);
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              final color = states.contains(MaterialState.selected)
                  ? _andrewTeal
                  : const Color(0xFF94A3B8);
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
  static const List<Widget> _pages = [
    _AndrewHomePage(),
    _AndrewPlanPage(),
    _AndrewCoachPage(),
    _AndrewProgressPage(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return YounekaHomeShell(
      pages: _pages,
      initialIndex: 1,
      onSidebarAction: _handleSidebarAction,
      onMentorTap: () => _openMentorChatPopup(),
    );
  }
}

class _AndrewHomePage extends StatelessWidget {
  const _AndrewHomePage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDF8F2), Color(0xFFE8F3F1)],
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
                  color: Colors.white,
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
                        color: const Color(0xFF475569),
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
                color: Color(0xFF0F766E),
              ),
              _QuickChip(
                icon: Icons.account_tree_rounded,
                label: 'Pecah tugas',
                color: Color(0xFFF97316),
              ),
              _QuickChip(
                icon: Icons.calendar_today_rounded,
                label: 'Rapikan jadwal',
                color: Color(0xFF2563EB),
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
          color: Colors.white,
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
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                    ),
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
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF475569),
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
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
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

class _AndrewPlanPageState extends State<_AndrewPlanPage> {
  static const int _gridStartHour = 1;
  static const int _gridEndHour = 23;
  static const double _hourRowHeight = 56;

  late DateTime _selectedDate;
  final List<_PlanSheetResultData> _plans = <_PlanSheetResultData>[];
  int _lastTemplateToken = -1;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    PlanTemplateBridge.selectionNotifier.addListener(_onTemplateSelected);
  }

  @override
  void dispose() {
    PlanTemplateBridge.selectionNotifier.removeListener(_onTemplateSelected);
    super.dispose();
  }

  void _onTemplateSelected() {
    final payload = PlanTemplateBridge.selectionNotifier.value;
    if (payload == null || payload.token == _lastTemplateToken) return;
    _lastTemplateToken = payload.token;
    _openAddPlanSheet(
      initialDate: _selectedDate,
      initialStart: TimeOfDay.now(),
      initialTitle: payload.preset.title,
      initialDurationMinutes: payload.preset.durationMinutes,
    );
  }

  List<DateTime> get _visibleDays {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day - 1);
    return List<DateTime>.generate(30, (i) {
      final d = start.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  Future<void> _openAddPlanSheet({
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
    if (result == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(
        result.date.year,
        result.date.month,
        result.date.day,
      );
      _plans.add(result);
    });
  }

  void _startPomodoro() {
    final messenger = ScaffoldMessenger.of(context);
    if (_plans.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Belum ada rencana untuk memulai pomodoro.'),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Pomodoro dimulai untuk ${_plans.length} rencana.'),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayId(DateTime date) {
    const labels = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];
    return labels[date.weekday - 1];
  }

  String _hourLabel(int hour24) {
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12 $period';
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  double _blockTop(_PlanSheetResultData p) {
    final startBase = _gridStartHour * 60;
    final start = _toMinutes(p.start);
    final clamped = start < startBase ? startBase : start;
    return ((clamped - startBase) / 60) * _hourRowHeight;
  }

  double _blockHeight(_PlanSheetResultData p) {
    final duration = (_toMinutes(p.end) - _toMinutes(p.start)).clamp(
      15,
      24 * 60,
    );
    return (duration / 60) * _hourRowHeight;
  }

  @override
  Widget build(BuildContext context) {
    final visibleDays = _visibleDays;
    final selectedPlans = _plans
        .where((p) => _sameDay(p.date, _selectedDate))
        .toList();
    final totalRows = _gridEndHour - _gridStartHour + 1;
    final gridHeight = totalRows * _hourRowHeight;

    return Container(
      color: const Color(0xFFF2F5FA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFFA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFAFC5E9)),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF0F2748),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'lingga',
                          style: TextStyle(
                            fontSize: 42 / 2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101A2D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text(
                              'LV 1',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5E6E87),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCE5F3),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: 0.48,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A72B8),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      const Text(
                        'Rank',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5E6E87),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCAD6EA)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'E',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 38,
                  color: Color(0xFF2C7FDB),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Belum ada rencana',
                      style: TextStyle(
                        color: Color(0xFF6A7992),
                        fontSize: 20 / 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _startPomodoro,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A72B8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(
                      Icons.play_circle_filled_rounded,
                      size: 18,
                    ),
                    label: const Text('Mulai Pomodoro'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleDays.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final day = visibleDays[index];
                    final selected = _sameDay(day, _selectedDate);
                    return InkWell(
                      onTap: () => setState(() => _selectedDate = day),
                      onLongPress: () {
                        setState(() => _selectedDate = day);
                        _openAddPlanSheet(initialDate: day);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 54,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFDFEAFE)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _weekdayId(day),
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? const Color(0xFF4A72B8)
                                    : const Color(0xFF6E7D95),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF4A72B8)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC9D6EA),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF243348),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16 / 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: gridHeight,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 68,
                          child: Column(
                            children: List.generate(totalRows, (i) {
                              final hour = _gridStartHour + i;
                              return Container(
                                height: _hourRowHeight,
                                alignment: Alignment.topCenter,
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _hourLabel(hour),
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 28 / 2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              final selectedHour =
                                  (_gridStartHour +
                                          (details.localPosition.dy /
                                                  _hourRowHeight)
                                              .floor())
                                      .clamp(_gridStartHour, _gridEndHour);
                              _openAddPlanSheet(
                                initialDate: _selectedDate,
                                initialStart: TimeOfDay(
                                  hour: selectedHour,
                                  minute: 0,
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Column(
                                  children: List.generate(totalRows, (_) {
                                    return Container(
                                      height: _hourRowHeight,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Color(0xFFCCD6E6),
                                          ),
                                          left: BorderSide(
                                            color: Color(0xFFCCD6E6),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                ...selectedPlans.map((p) {
                                  return Positioned(
                                    left: 8,
                                    right: 8,
                                    top: _blockTop(p),
                                    child: Container(
                                      height: _blockHeight(p),
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        8,
                                        10,
                                        6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A72B8),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x223A5F9A),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 26 / 2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_two(p.start.hour)}:${_two(p.start.minute)} - ${_two(p.end.hour)}:${_two(p.end.minute)}',
                                            style: const TextStyle(
                                              color: Color(0xE6FFFFFF),
                                              fontSize: 22 / 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
    final duration = (widget.initialDurationMinutes ?? 60).clamp(5, 240);
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
          color: const Color(0xFFEFF3F8),
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
                      borderSide: BorderSide(
                        color: Color(0xFF2563EB),
                        width: 2,
                      ),
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
                          color: const Color(0xFF1D4ED8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white,
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
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
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
          color: selected ? const Color(0xFFCDE7FF) : Colors.transparent,
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

class _AndrewCoachPage extends StatelessWidget {
  const _AndrewCoachPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F5F1), Color(0xFFEAF2F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AndrewSectionHeader(
                title: 'Mentor Andrew',
                subtitle: 'Bicara langsung untuk menemukan langkah pertama.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _CoachPrompt(
                    icon: Icons.play_arrow_rounded,
                    label: 'Bantu mulai tugas',
                  ),
                  _CoachPrompt(
                    icon: Icons.psychology_rounded,
                    label: 'Redakan overthinking',
                  ),
                  _CoachPrompt(
                    icon: Icons.lightbulb_rounded,
                    label: 'Cari ide langkah kecil',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: const [
                    _CoachMessage(
                      isAndrew: true,
                      message:
                          'Halo! Ceritakan tugas yang lagi kamu tunda. Kita pecah bareng-bareng.',
                      time: '10:15',
                    ),
                    _CoachMessage(
                      isAndrew: false,
                      message:
                          'Aku harus mulai skripsi tapi bingung langkah pertama.',
                      time: '10:16',
                    ),
                    _CoachMessage(
                      isAndrew: true,
                      message:
                          'Mulai dari 1 halaman: tulis tujuan riset + 3 pertanyaan utama.',
                      time: '10:17',
                    ),
                    _CoachMessage(
                      isAndrew: false,
                      message: 'Oke, aku coba mulai 25 menit dulu.',
                      time: '10:18',
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

class _CoachMessage extends StatelessWidget {
  const _CoachMessage({
    required this.isAndrew,
    required this.message,
    required this.time,
  });

  final bool isAndrew;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    final alignment = isAndrew ? Alignment.centerLeft : Alignment.centerRight;
    final background = isAndrew
        ? Colors.white
        : _andrewSoftTeal.withOpacity(0.8);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isAndrew ? 4 : 18),
      bottomRight: Radius.circular(isAndrew ? 18 : 4),
    );
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14111827),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _andrewInk),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachPrompt extends StatelessWidget {
  const _CoachPrompt({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _andrewTeal),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _andrewInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AndrewProgressPage extends StatelessWidget {
  const _AndrewProgressPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F6F2), Color(0xFFE9F0F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _AndrewSectionHeader(
                title: 'Progress',
                subtitle: 'Pantau konsistensi kecilmu setiap hari.',
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AndrewStatCard(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Streak',
                      value: '6 hari',
                      detail: 'Naik dari minggu lalu',
                      color: Color(0xFFF97316),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _AndrewStatCard(
                      icon: Icons.timer_rounded,
                      title: 'Fokus',
                      value: '4j 20m',
                      detail: 'Total minggu ini',
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _AndrewStatCard(
                icon: Icons.check_circle_rounded,
                title: 'Tugas selesai',
                value: '14 dari 18',
                detail: '78% tercapai',
                color: Color(0xFF2563EB),
              ),
              SizedBox(height: 16),
              Text(
                'Sorotan minggu ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _andrewInk,
                ),
              ),
              SizedBox(height: 10),
              _AndrewStreakTile(
                icon: Icons.emoji_events_rounded,
                title: 'Konsisten pagi hari',
                detail: 'Sesi fokus paling sering jam 08.00.',
              ),
              _AndrewStreakTile(
                icon: Icons.bolt_rounded,
                title: 'Mulai cepat',
                detail: 'Rata-rata mulai 7 menit setelah membuka app.',
              ),
              _AndrewStreakTile(
                icon: Icons.self_improvement_rounded,
                title: 'Refleksi malam',
                detail: '4 hari berturut-turut menulis catatan.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AndrewStatCard extends StatelessWidget {
  const _AndrewStatCard({
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14111827),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _andrewInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _AndrewStreakTile extends StatelessWidget {
  const _AndrewStreakTile({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
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
                    fontWeight: FontWeight.w700,
                    color: _andrewInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
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
          color: Colors.white,
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
  final Size _canvasSize = const Size(2400, 1600);

  final List<FlowNode> _nodes = [];
  final List<FlowConnection> _connections = [];

  double _currentScale = 1.0;
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
    setState(() {
      _transformController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
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
          backgroundColor: Colors.white,
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
          onInteractionUpdate: (_) {
            setState(() {
              _currentScale = _transformController.value.getMaxScaleOnAxis();
            });
          },
          onInteractionEnd: (_) {
            setState(() {
              _currentScale = _transformController.value.getMaxScaleOnAxis();
            });
          },
          child: SizedBox(
            key: _canvasKey,
            width: _canvasSize.width,
            height: _canvasSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_showGrid)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: FlowGridPainter(scale: _currentScale),
                    ),
                  ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: ConnectionPainter(
                      nodes: _nodes,
                      connections: _connections,
                      highlightFrom: _connectionFromNodeId,
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
        color: Colors.white,
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
        ? const Color(0xFF4F46E5)
        : const Color(0xFF1F2937);
    final Color background = highlighted
        ? const Color(0xFFE0E7FF)
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
            color: enabled ? accent : const Color(0xFFCBD5F5),
            disabledColor: const Color(0xFFD1D5DB),
            splashRadius: 28,
          ),
        ),
      ),
    );
  }
}
