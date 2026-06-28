import '../models/graph_model.dart';
import 'colors.dart';

class Algorithms {
  static const inf = 999999;
  static const infStr = '∞';

  static String _lbl(int n) {
    const l = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩', '⑪', '⑫', '⑬', '⑭', '⑮', '⑯'];
    return n < l.length ? l[n] : '$n';
  }

  static List<AlgoStep> dijkstra(List<GraphNode> nodes, List<GraphEdge> edges, String src, bool isDirected) {
    final ids = nodes.map((n) => n.id).toList()..sort();
    final dist = {for (var n in ids) n: inf};
    final prev = <String, String?>{for (var n in ids) n: null};
    dist[src] = 0;
    final visited = <String>{};
    final steps = <AlgoStep>[];
    final rows = <TableRowData>[];

    String fmt(String id) {
      if (dist[id] == inf) return infStr;
      if (prev[id] == null) return '${dist[id]}';
      return '${dist[id]}(${prev[id]})';
    }

    rows.add(TableRowData(step: '#', visitedNode: 'Visit', distMap: {for (var n in ids) n: n}));
    rows.add(TableRowData(step: '0', visitedNode: src, distMap: {for (var n in ids) n: n == src ? '0' : infStr}));

    steps.add(AlgoStep(
      type: StepType.init, dist: {...dist}, prev: {...prev}, visited: {},
      log: 'Başla: $src=0, diğerleri=∞', logColor: AC.primary, tableRows: List.from(rows),
    ));

    final pq = <MapEntry<String, int>>[MapEntry(src, 0)];
    int sn = 1;

    while (pq.isNotEmpty) {
      pq.sort((a, b) => a.value.compareTo(b.value));
      final u = pq.removeAt(0).key;
      if (visited.contains(u)) continue;
      visited.add(u);

      for (final e in edges) {
        String? v;
        if (e.from == u) v = e.to;
        else if (!isDirected && e.to == u) v = e.from;

        if (v == null || visited.contains(v)) continue;

        final nd = dist[u]! + e.weight;
        if (nd < dist[v]!) {
          dist[v] = nd;
          prev[v] = u;
          pq.add(MapEntry(v, nd));
        }
      }

      rows.add(TableRowData(step: _lbl(sn), visitedNode: u, distMap: {for (var n in ids) n: fmt(n)}));
      steps.add(AlgoStep(
        type: StepType.visit, dist: {...dist}, prev: {...prev}, visited: {...visited},
        activeNode: u, log: 'Ziyaret: $u  dist=${dist[u]}', logColor: AC.primary, tableRows: List.from(rows),
      ));
      sn++;
    }

    int maxD = 0; String target = src;
    dist.forEach((k, v) { if (v > maxD && v != inf) { maxD = v; target = k; }});
    final path = <String>[];
    String? cur = target;
    while (cur != null) { path.insert(0, cur); cur = prev[cur]; }

    steps.add(AlgoStep(
      type: StepType.path, dist: {...dist}, prev: {...prev}, visited: {...visited}, path: path,
      log: 'En kısa yol: ${path.join('→')} (maliyet: $maxD)', logColor: AC.primary, tableRows: List.from(rows),
    ));
    return steps;
  }

  static List<AlgoStep> bellmanFord(List<GraphNode> nodes, List<GraphEdge> edges, String src, bool isDirected) {
    final ids = nodes.map((n) => n.id).toList()..sort();
    final dist = {for (var n in ids) n: inf};
    final prev = <String, String?>{for (var n in ids) n: null};
    dist[src] = 0;
    final steps = <AlgoStep>[];
    final rows = <TableRowData>[];

    String fd(String id) => dist[id] == inf ? infStr : '${dist[id]}';
    String fp(String id) => prev[id] == null ? '-1' : prev[id]!;

    rows.add(TableRowData(step: 'iter', visitedNode: 'kenar', distMap: {for (var n in ids) n: n}, prevMap: {for (var n in ids) n: n}));
    rows.add(TableRowData(step: '0', visitedNode: '-', distMap: {for (var n in ids) n: n == src ? '0' : infStr}, prevMap: {for (var n in ids) n: '-1'}));

    steps.add(AlgoStep(
      type: StepType.init, dist: {...dist}, prev: {...prev}, visited: {},
      log: 'Başla: $src=0, diğerleri=∞', logColor: AC.primary, tableRows: List.from(rows),
    ));

    int iter = 0;
    for (int i = 0; i < ids.length - 1; i++) {
      bool updated = false;
      iter++;
      for (final e in edges) {
        for (int d = 0; d < (isDirected ? 1 : 2); d++) {
          final u = d == 0 ? e.from : e.to;
          final v = d == 0 ? e.to : e.from;
          final w = e.weight;

          if (dist[u] != inf && dist[u]! + w < dist[v]!) {
            dist[v] = dist[u]! + w;
            prev[v] = u;
            updated = true;

            rows.add(TableRowData(step: '$iter', visitedNode: '$u→$v', distMap: {for (var n in ids) n: fd(n)}, prevMap: {for (var n in ids) n: fp(n)}));
            steps.add(AlgoStep(
              type: StepType.update, dist: {...dist}, prev: {...prev}, visited: {},
              activeEdge: '$u-$v', activeNode: v, log: 'Relax $u→$v: dist[$v]=${dist[v]}', logColor: AC.primary, tableRows: List.from(rows),
            ));
          }
        }
      }
      if (!updated) break;
    }

    int maxD = 0; String target = src;
    dist.forEach((k, v) { if (v > maxD && v != inf) { maxD = v; target = k; }});
    final path = <String>[];
    String? cur = target;
    while (cur != null) { path.insert(0, cur); cur = prev[cur]; }

    steps.add(AlgoStep(
      type: StepType.path, dist: {...dist}, prev: {...prev}, visited: {}, path: path,
      log: 'Tamamlandı: ${path.join('→')} (maliyet: $maxD)', logColor: AC.primary, tableRows: List.from(rows),
    ));
    return steps;
  }

  static List<AlgoStep> prim(List<GraphNode> nodes, List<GraphEdge> edges, String src) {
    final ids = nodes.map((n) => n.id).toList()..sort();
    final inMST = <String>{src};
    final mstE = <String>{};
    final rows = <TableRowData>[];
    final steps = <AlgoStep>[];
    int total = 0;

    rows.add(TableRowData(step: '#', visitedNode: 'Eklenen', distMap: {'kenar': 'Kenar', 'agirlik': 'Ağırlık', 'toplam': 'MST Toplamı'}));
    steps.add(AlgoStep(type: StepType.init, dist: {}, prev: {}, visited: {}, mstNodes: {src}, log: 'Prim başlıyor: $src', logColor: AC.primary, tableRows: List.from(rows)));

    int sn = 1;
    while (inMST.length < ids.length) {
      GraphEdge? best;
      int bw = inf;
      for (final e in edges) {
        final aIn = inMST.contains(e.from), bIn = inMST.contains(e.to);
        if ((aIn && !bIn || bIn && !aIn) && e.weight < bw) { bw = e.weight; best = e; }
      }
      if (best == null) break;
      final nw = inMST.contains(best.from) ? best.to : best.from;
      inMST.add(nw);
      mstE.addAll(['${best.from}-${best.to}', '${best.to}-${best.from}']);
      total += bw;

      rows.add(TableRowData(step: _lbl(sn), visitedNode: nw, distMap: {'kenar': '${best.from}-${best.to}', 'agirlik': '$bw', 'toplam': '$total'}));
      steps.add(AlgoStep(
        type: StepType.add, dist: {}, prev: {}, visited: Set.from(inMST), mstNodes: Set.from(inMST), mstEdges: Set.from(mstE),
        activeNode: nw, activeEdge: '${best.from}-${best.to}', log: 'MST\'ye ekle: ${best.from}-${best.to} (w=$bw)', logColor: AC.primary, tableRows: List.from(rows),
      ));
      sn++;
    }
    steps.add(AlgoStep(type: StepType.done, dist: {}, prev: {}, visited: Set.from(inMST), mstNodes: Set.from(inMST), mstEdges: Set.from(mstE), log: 'MST tamamlandı! Toplam: $total', logColor: AC.primary, tableRows: List.from(rows)));
    return steps;
  }

  static List<AlgoStep> kruskal(List<GraphNode> nodes, List<GraphEdge> edges, String src) {
    final ids = nodes.map((n) => n.id).toList()..sort();
    final sorted = [...edges]..sort((a, b) => a.weight.compareTo(b.weight));
    final par = {for (var n in ids) n: n};
    final mstE = <String>{}, mstN = <String>{};
    final rows = <TableRowData>[];
    final steps = <AlgoStep>[];
    int total = 0;

    String find(String x) { if (par[x] != x) par[x] = find(par[x]!); return par[x]!; }
    void union(String x, String y) { par[find(x)] = find(y); }

    rows.add(TableRowData(step: '#', visitedNode: 'Durum', distMap: {'kenar': 'Kenar', 'agirlik': 'Ağırlık', 'toplam': 'MST Toplamı'}));
    steps.add(AlgoStep(type: StepType.init, dist: {}, prev: {}, visited: {}, log: 'Kruskal: ağırlığa göre sıralandı', logColor: AC.primary, tableRows: List.from(rows)));

    int sn = 1;
    for (final e in sorted) {
      if (find(e.from) != find(e.to)) {
        union(e.from, e.to);
        mstE.addAll(['${e.from}-${e.to}', '${e.to}-${e.from}']);
        mstN.addAll([e.from, e.to]);
        total += e.weight;

        rows.add(TableRowData(step: _lbl(sn), visitedNode: '✓ Ekle', distMap: {'kenar': '${e.from}-${e.to}', 'agirlik': '${e.weight}', 'toplam': '$total'}));
        steps.add(AlgoStep(
          type: StepType.add, dist: {}, prev: {}, visited: Set.from(mstN), mstNodes: Set.from(mstN), mstEdges: Set.from(mstE),
          activeEdge: '${e.from}-${e.to}', log: '✓ Ekle: ${e.from}-${e.to} (w=${e.weight})', logColor: AC.primary, tableRows: List.from(rows),
        ));
      } else {
        rows.add(TableRowData(step: _lbl(sn), visitedNode: '✗ Ret', distMap: {'kenar': '${e.from}-${e.to}', 'agirlik': '${e.weight}', 'toplam': '$total'}));
        steps.add(AlgoStep(
          type: StepType.reject, dist: {}, prev: {}, visited: Set.from(mstN), mstNodes: Set.from(mstN), mstEdges: Set.from(mstE),
          activeEdge: '${e.from}-${e.to}', log: '✗ Döngü oluşturur: ${e.from}-${e.to} reddedildi', logColor: AC.red, tableRows: List.from(rows),
        ));
      }
      sn++;
    }
    steps.add(AlgoStep(type: StepType.done, dist: {}, prev: {}, visited: Set.from(mstN), mstNodes: Set.from(mstN), mstEdges: Set.from(mstE), log: 'MST tamamlandı! Toplam: $total', logColor: AC.primary, tableRows: List.from(rows)));
    return steps;
  }
}