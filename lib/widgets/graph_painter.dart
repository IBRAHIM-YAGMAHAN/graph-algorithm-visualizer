import 'dart:math';
import 'package:flutter/material.dart';
import '../models/graph_model.dart';
import '../utils/colors.dart';
import '../utils/algorithms.dart';

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final AlgoStep? step;
  final Color algoColor;
  final String algo;
  final String? selectedNode;
  final EditMode editMode;
  final bool isDirected;

  const GraphPainter({
    required this.nodes, required this.edges, required this.step, required this.algoColor,
    required this.algo, this.selectedNode, required this.editMode, required this.isDirected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _grid(canvas, size);
    for (final e in edges) _edge(canvas, e);
    for (final n in nodes) _node(canvas, n);
    _hint(canvas, size);
  }

  void _grid(Canvas canvas, Size size) {
    const gridSize = 25.0;

    // Kareli defter icin
    final gridPaint = Paint()
      ..color = const Color(0xFF80A0D0).withOpacity(0.5)
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  Color _edgeColor(GraphEdge e) {
    final k1 = '${e.from}-${e.to}', k2 = '${e.to}-${e.from}';
    if (step?.activeEdge == k1 || step?.activeEdge == k2) return algoColor;
    if (step?.mstEdges.contains(k1) == true || step?.mstEdges.contains(k2) == true) return algoColor;
    if (step?.path != null) {
      final p = step!.path!;
      for (int i = 0; i < p.length - 1; i++) {
        if ((p[i] == e.from && p[i + 1] == e.to) || (p[i] == e.to && p[i + 1] == e.from)) return AC.primary;
      }
    }
    return AC.text2.withOpacity(0.3);
  }

  void _edge(Canvas canvas, GraphEdge e) {
    final fn = nodes.firstWhere((n) => n.id == e.from, orElse: () => GraphNode(id: '', position: Offset.zero));
    final tn = nodes.firstWhere((n) => n.id == e.to, orElse: () => GraphNode(id: '', position: Offset.zero));
    if (fn.id.isEmpty || tn.id.isEmpty) return;

    final color = _edgeColor(e);
    final active = color != AC.text2.withOpacity(0.3);
    const r = 22.0;
    final dx = tn.position.dx - fn.position.dx, dy = tn.position.dy - fn.position.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len == 0) return;

    final ux = dx / len, uy = dy / len;
    // Normal vektörü (Çizgiye dik olan yön, sağa-sola kaydırmak için)
    final nx = -uy, ny = ux;
    // Gidiş-dönüş (Karşılıklı) kenar var mı kontrolü
    bool hasReciprocal = isDirected && edges.any((e2) => e2.from == e.to && e2.to == e.from);
    // Varsa çizgiyi gidiş yönünün sağına doğru 8 piksel kaydır (Üst üste binmeyi engeller)
    final offset = hasReciprocal ? 8.0 : 0.0;

    final start = Offset(
        fn.position.dx + ux * r + nx * offset,
        fn.position.dy + uy * r + ny * offset
    );
    final end = Offset(
        tn.position.dx - ux * (r + (isDirected ? 6 : 0)) + nx * offset,
        tn.position.dy - uy * (r + (isDirected ? 6 : 0)) + ny * offset
    );

    final lp = Paint()..color = color..strokeWidth = active ? 3.0 : 1.5..strokeCap = StrokeCap.round;
    if (active) lp.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(start, end, lp);

    if (isDirected) {
      final angle = atan2(end.dy - start.dy, end.dx - start.dx);
      const hl = 10.0, ha = 0.5;
      final ap = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx - hl * cos(angle - ha), end.dy - hl * sin(angle - ha))
        ..moveTo(end.dx, end.dy)
        ..lineTo(end.dx - hl * cos(angle + ha), end.dy - hl * sin(angle + ha));
      canvas.drawPath(ap, Paint()..color = color..strokeWidth = active ? 2 : 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }

    final mx = (start.dx + end.dx) / 2, my = (start.dy + end.dy) / 2;

    // Yazıyı tam olarak çizginin kendi koordinatı (kaydırılmış mx ve my) üzerine basıyoruz.
    _txt(canvas, '${e.weight}', Offset(mx, my), color: active ? color : AC.text2, size: 12, bold: active, bg: true);
  }

  Color _nodeColor(GraphNode n) {
    if (n.id == selectedNode || step?.activeNode == n.id) return AC.primary;
    if (step?.path?.contains(n.id) == true) return AC.primary;
    if (step?.mstNodes.contains(n.id) == true || step?.visited.contains(n.id) == true) return algoColor;
    return const Color(0xFFE0E0E0);
  }

  void _node(Canvas canvas, GraphNode n) {
    final pos = n.position; const r = 22.0; final nc = _nodeColor(n); final active = nc != const Color(0xFFE0E0E0);

    if (active) canvas.drawCircle(pos, r + 7, Paint()..color = nc.withOpacity(.25)..style = PaintingStyle.stroke..strokeWidth = 2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    if (editMode == EditMode.deleteItem) canvas.drawCircle(pos, r, Paint()..color = const Color(0xFFFF4444).withOpacity(.12));

    canvas.drawCircle(pos, r, Paint()..color = active ? nc : const Color(0xFFE0E0E0));
    canvas.drawCircle(pos, r, Paint()..color = active ? nc : AC.text2..style = PaintingStyle.stroke..strokeWidth = active ? 2 : 1.5);
    _txt(canvas, n.id, pos, color: active ? Colors.white : AC.text, size: 15, bold: true, bg: false);

    if (step?.dist[n.id] != null && step!.dist[n.id]! != Algorithms.inf) {
      _txt(canvas, '${step!.dist[n.id]}', pos + const Offset(0, 36), color: algoColor, size: 11, bold: true, bg: true);
    }
  }

  void _hint(Canvas canvas, Size size) {
    String hint = '';
    switch (editMode) {
      case EditMode.addNode: hint = '+ Tuvale dokunarak düğüm ekleyin'; break;
      case EditMode.addEdge: hint = selectedNode != null ? '$selectedNode seçildi  →  hedef düğümü seçin' : '↔ Kaynak düğümü seçin'; break;
      case EditMode.deleteItem: hint = '✕ Düğüme dokunarak silin'; break;
      case EditMode.view: break;
    }
    if (hint.isEmpty) return;
    _txt(canvas, hint, Offset(size.width / 2, size.height - 14), color: AC.text2, size: 11, bg: false);
  }

  void _txt(Canvas canvas, String t, Offset pos, {Color color = Colors.white, double size = 12, bool bold = false, bool bg = false}) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontFamily: 'monospace')), textDirection: TextDirection.ltr)..layout();

    if (bg) {
      final rect = Rect.fromCenter(center: pos, width: tp.width + 6, height: tp.height + 4);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = AC.bg.withOpacity(0.9));
    }

    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(GraphPainter old) => true;
}