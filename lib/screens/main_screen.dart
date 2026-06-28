import 'dart:async';
import 'package:flutter/material.dart';
import '../models/graph_model.dart';
import '../utils/colors.dart';
import '../utils/algorithms.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/graph_painter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  String _algo = 'dijkstra';
  String _source = 'A';
  bool _isDirected = true;

  List<AlgoStep> _steps = [];
  int _stepIdx = 0;
  Timer? _timer;
  bool _running = false;

  double _speed = 1.0;
  double _panelHeight = 220.0;

  late TabController _tabCtrl;

  List<GraphNode> _nodes = [];
  List<GraphEdge> _edges = [];

  EditMode _editMode = EditMode.addNode;
  String? _selectedNode;
  int _nodeCounter = 0;
  static const _names = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final _algos = ['dijkstra', 'bellman', 'prim', 'kruskal'];
  final _algoNames = { 'dijkstra': 'DIJKSTRA', 'bellman': 'BELLMAN-FORD', 'prim': 'PRIM', 'kruskal': 'KRUSKAL' };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _algo = _algos[_tabCtrl.index];
          _resetViz();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _clearGraph() {
    setState(() {
      _nodes = [];
      _edges = [];
      _nodeCounter = 0;
      _selectedNode = null;
      _source = 'A'; // Kaynağı da başa sarıyoruz
      _resetViz();
    });
  }

  // Sadece animasyon sifirla
  void _resetViz() {
    _timer?.cancel();
    _running = false;
    _steps = [];
    _stepIdx = 0;
  }

  void _runAlgo() {
    if (_nodes.isEmpty) return;

    setState(() {
      _resetViz();
      switch (_algo) {
        case 'dijkstra': _steps = Algorithms.dijkstra(_nodes, _edges, _source, _isDirected); break;
        case 'bellman': _steps = Algorithms.bellmanFord(_nodes, _edges, _source, _isDirected); break;
        case 'prim': _steps = Algorithms.prim(_nodes, _edges, _source); break;
        case 'kruskal': _steps = Algorithms.kruskal(_nodes, _edges, _source); break;
      }
      _running = true;
    });
    _animate();
  }

  void _animate() {
    if (_stepIdx >= _steps.length) { setState(() => _running = false); return; }
    setState(() => _stepIdx++);
    int delayMs = (400 / _speed).round();
    _timer = Timer(Duration(milliseconds: delayMs), _animate);
  }

  AlgoStep? get _curStep => _stepIdx > 0 && _steps.isNotEmpty ? _steps[_stepIdx - 1] : null;

  String? _nodeAt(Offset p) {
    for (final n in _nodes) {
      if ((n.position - p).distance < 45) return n.id;
    }
    return null;
  }

  void _handleTap(Offset pos) {
    if (_running) return;
    switch (_editMode) {
      case EditMode.addNode:
        final t = _nodeAt(pos);
        if (t == null) {
          if (_nodeCounter < _names.length) {
            setState(() {
              final id = _names[_nodeCounter];
              _nodeCounter++;
              _nodes = [..._nodes, GraphNode(id: id, position: pos)];
              if (_nodes.length == 1) _source = id;
              _resetViz();
            });
          }
        } else {
          _renameNodeDialog(t);
        }
        break;
      case EditMode.addEdge:
        final t = _nodeAt(pos);
        if (t == null) { setState(() => _selectedNode = null); return; }
        if (_selectedNode == null) { setState(() => _selectedNode = t); }
        else if (_selectedNode != t) {
          final from = _selectedNode!;
          setState(() => _selectedNode = null);
          _weightDialog(from, t);
        }
        break;
      case EditMode.deleteItem:
        final t = _nodeAt(pos);
        if (t != null) {
          setState(() {
            _nodes = _nodes.where((n) => n.id != t).toList();
            _edges = _edges.where((e) => e.from != t && e.to != t).toList();
            if (_source == t && _nodes.isNotEmpty) _source = _nodes.first.id;
            _resetViz();
          });
        }
        break;
      case EditMode.view:
        break;
    }
  }

  void _renameNodeDialog(String oldId) {
    final ctrl = TextEditingController(text: oldId);
    final ac = AC.forAlgo(_algo);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AC.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: ac, width: 1)),
        title: Text('Düğümü Yeniden Adlandır', style: TextStyle(color: ac, fontSize: 13, fontFamily: 'monospace', letterSpacing: 1)),
        content: TextField(
          controller: ctrl, autofocus: true, style: const TextStyle(color: AC.text, fontSize: 18),
          decoration: InputDecoration(
            filled: true, fillColor: AC.bg, border: const OutlineInputBorder(borderSide: BorderSide(color: AC.border)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ac, width: 2)),
            hintText: 'Yeni İsim', hintStyle: const TextStyle(color: AC.text2),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: AC.text2))),
          TextButton(
            onPressed: () {
              final newId = ctrl.text.trim();
              if (newId.isNotEmpty && newId != oldId && !_nodes.any((n) => n.id == newId)) {
                setState(() {
                  final nodeIndex = _nodes.indexWhere((n) => n.id == oldId);
                  final nodePos = _nodes[nodeIndex].position;
                  _nodes[nodeIndex] = GraphNode(id: newId, position: nodePos);

                  _edges = _edges.map((e) {
                    return GraphEdge(
                        from: e.from == oldId ? newId : e.from,
                        to: e.to == oldId ? newId : e.to,
                        weight: e.weight
                    );
                  }).toList();

                  if (_source == oldId) _source = newId;
                  _resetViz();
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('Kaydet', style: TextStyle(color: ac, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  void _weightDialog(String from, String to) {
    final ctrl = TextEditingController(text: '10');
    final ac = AC.forAlgo(_algo);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AC.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: ac, width: 1)),
        title: Text('$from ${_isDirected ? '→' : '↔'} $to Ağırlık', style: TextStyle(color: ac, fontSize: 13, fontFamily: 'monospace', letterSpacing: 1)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          autofocus: true,
          style: const TextStyle(color: AC.text, fontSize: 18),
          decoration: InputDecoration(
            filled: true, fillColor: AC.bg, border: const OutlineInputBorder(borderSide: BorderSide(color: AC.border)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ac, width: 2)),
            hintText: 'Ağırlık', hintStyle: const TextStyle(color: AC.text2),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: AC.text2))),
          TextButton(
            onPressed: () {
              final w = int.tryParse(ctrl.text) ?? 1;
              Navigator.pop(ctx);
              setState(() {
                _edges.removeWhere((e) => e.from == from && e.to == to);
                if (!_isDirected) {
                  _edges.removeWhere((e) => e.from == to && e.to == from);
                }
                _edges.add(GraphEdge(from: from, to: to, weight: w));
                _resetViz();
              });
            },
            child: Text('Ekle', style: TextStyle(color: ac, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: SafeArea(
        child: Column(children: [
          _header(),
          Expanded(
            child: LayoutBuilder(builder: (ctx, c) {
              return c.maxWidth > 700
                  ? Row(children: [ Expanded(flex: 3, child: _canvas()), SizedBox(width: 380, child: _sidePanel()), ])
                  : Column(children: [
                Expanded(child: _canvas()),
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _panelHeight -= details.delta.dy;
                      const double minPanelHeight = 200.0;
                      if (_panelHeight < minPanelHeight) _panelHeight = minPanelHeight;

                      final maxH = c.maxHeight * 0.8;
                      if (_panelHeight > maxH) _panelHeight = maxH;
                    });
                  },
                  child: Container(
                    height: 16, width: double.infinity, color: AC.bg2, alignment: Alignment.center,
                    child: Container(width: 50, height: 4, decoration: BoxDecoration(color: AC.text2.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                  ),
                ),
                SizedBox(height: _panelHeight, child: _sidePanel()),
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _header() {
    final ac = AC.forAlgo(_algo);
    return Container(
      decoration: BoxDecoration(color: AC.bg2, border: Border(bottom: BorderSide(color: ac, width: 1))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('I.O.Y Algoritmalar Odevi', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w900, color: ac, letterSpacing: 2)),
              const Text('KISA YOL & MST', style: TextStyle(fontSize: 9, color: AC.text2, letterSpacing: 1.5)),
            ]),
            const Spacer(),
            if (_nodes.isNotEmpty) ...[
              const Text('Kaynak: ', style: TextStyle(color: AC.text2, fontSize: 11)),
              DropdownButton<String>(
                value: _nodes.any((n) => n.id == _source) ? _source : _nodes.first.id,
                dropdownColor: AC.bg, style: TextStyle(color: ac, fontSize: 14, fontWeight: FontWeight.bold), underline: const SizedBox(),
                items: _nodes.map((n) => DropdownMenuItem(value: n.id, child: Text(n.id))).toList(),
                onChanged: (v) { if (v != null) setState(() { _source = v; _resetViz(); }); },
              ),
            ],
          ]),
        ),
        TabBar(
          controller: _tabCtrl, indicatorColor: ac, indicatorWeight: 2, labelColor: ac, unselectedLabelColor: AC.text2,
          isScrollable: true, tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold),
          tabs: _algos.map((a) => Tab(text: _algoNames[a])).toList(),
        ),
      ]),
    );
  }

  Widget _canvas() {
    return Container(
      color: AC.bg,
      child: Column(children: [
        _toolbar(),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _handleTap(d.localPosition),
            child: _nodes.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.touch_app_outlined, color: AC.text2, size: 38), const SizedBox(height: 8),
              Text(_editMode == EditMode.addNode ? '↑ Tuvale dokunarak düğüm ekleyin' : '"DÜĞÜM" modunu seçip tuvale dokunun', style: const TextStyle(color: AC.text2, fontSize: 12)),
            ]))
                : CustomPaint(
              painter: GraphPainter(nodes: _nodes, edges: _edges, step: _curStep, algoColor: AC.forAlgo(_algo), algo: _algo, selectedNode: _selectedNode, editMode: _editMode, isDirected: _isDirected),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _toolbar() {
    final ac = AC.forAlgo(_algo);
    return Container(
      height: 44, color: AC.bg3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(children: [
          ModeBtn(icon: Icons.visibility_outlined, label: 'GÖR', mode: EditMode.view, cur: _editMode, ac: ac, onTap: () => setState(() { _editMode = EditMode.view; _selectedNode = null; })),
          ModeBtn(icon: Icons.add_circle_outline, label: 'DÜĞÜM', mode: EditMode.addNode, cur: _editMode, ac: ac, onTap: () => setState(() { _editMode = EditMode.addNode; _selectedNode = null; })),
          ModeBtn(icon: Icons.linear_scale, label: 'KENAR', mode: EditMode.addEdge, cur: _editMode, ac: ac, onTap: () => setState(() { _editMode = EditMode.addEdge; _selectedNode = null; })),
          ModeBtn(icon: Icons.delete_outline, label: 'SİL', mode: EditMode.deleteItem, cur: _editMode, ac: ac, onTap: () => setState(() { _editMode = EditMode.deleteItem; _selectedNode = null; })),

          Container(width: 1, height: 20, color: AC.border, margin: const EdgeInsets.symmetric(horizontal: 6)),
          InkWell(
            onTap: () => setState((){ _isDirected = !_isDirected; _resetViz(); }),
            borderRadius: BorderRadius.circular(3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: _isDirected ? ac.withOpacity(.15) : Colors.transparent, border: Border.all(color: _isDirected ? ac : AC.border), borderRadius: BorderRadius.circular(3)),
              child: Row(children: [
                Icon(_isDirected ? Icons.arrow_right_alt : Icons.sync_alt, size: 14, color: _isDirected ? ac : AC.text2),
                const SizedBox(width: 4),
                Text(_isDirected ? 'YÖNLÜ' : 'YÖNSÜZ', style: TextStyle(color: _isDirected ? ac : AC.text2, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              ]),
            ),
          ),

          if (_editMode == EditMode.addEdge && _selectedNode != null)
            Padding(padding: const EdgeInsets.only(left: 12), child: Text('$_selectedNode → ?', style: const TextStyle(color: AC.primary, fontSize: 12, fontFamily: 'monospace'))),
        ]),
      ),
    );
  }

  Widget _sidePanel() {
    final ac = AC.forAlgo(_algo);
    return Container(
      color: AC.bg2,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AC.border), bottom: BorderSide(color: AC.border))),
          child: Column(children: [
            Row(children: [
              Expanded(child: FuturisticButton(label: _running ? '⏸ DURDUR' : 'ÇALIŞTIR', color: AC.primary, onTap: _running ? () { _timer?.cancel(); setState(() => _running = false); } : _runAlgo)),
              const SizedBox(width: 8),
              Expanded(child: FuturisticButton(label: '↺ SIFIRLA', color: AC.red, onTap: _clearGraph)),

            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('HIZ', style: TextStyle(color: AC.text2, fontSize: 10)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(activeTrackColor: ac, thumbColor: ac, inactiveTrackColor: AC.border, trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                  child: Slider(
                    value: _speed,
                    min: 0.25, max: 2.0, divisions: 7,
                    onChanged: (v) => setState(() => _speed = v),
                  ),
                ),
              ),
              Text('${_speed.toStringAsFixed(2)}x', style: TextStyle(color: ac, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
        Expanded(child: _table()),
      ]),
    );
  }

  Widget _table() {
    if (_curStep == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.table_chart_outlined, color: AC.text2, size: 32), const SizedBox(height: 8),
        Text(_steps.isEmpty ? 'ÇALIŞTIR\'a basın' : 'Animasyon bitti', style: const TextStyle(color: AC.text2, fontSize: 12)),
        const Text('Adım tablosu burada görünür', style: TextStyle(color: AC.border, fontSize: 10)),
      ]));
    }
    final step = _curStep!; final rows = step.tableRows;
    if (rows.isEmpty) return const SizedBox();
    final isMST = _algo == 'prim' || _algo == 'kruskal'; final isBF = _algo == 'bellman'; final ac = AC.forAlgo(_algo);

    return Container(
      color: AC.bg3, padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: ac, boxShadow: [BoxShadow(color: ac, blurRadius: 6)])),
          const SizedBox(width: 6),
          Text(isMST ? 'MST ADIM TABLOSU' : isBF ? 'BELLMAN-FORD TABLOSU' : 'DİJKSTRA MESAFE TABLOSU', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: ac, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('$_stepIdx/${_steps.length}', style: const TextStyle(color: AC.text2, fontSize: 9)),
        ]),
        const SizedBox(height: 6),
        Expanded(child: isMST ? _mstTable(rows) : isBF ? _bfTable(rows) : _djTable(rows)),
        Container(
          margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: step.logColor, width: 2)), color: step.logColor.withOpacity(.05)),
          child: Text(step.log, style: TextStyle(color: step.logColor, fontSize: 10, fontFamily: 'monospace')),
        ),
      ]),
    );
  }

  Widget _djTable(List<TableRowData> rows) {
    final ids = _nodes.map((n) => n.id).toList()..sort();
    final ac = AC.forAlgo(_algo);
    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: AC.border, width: .5), defaultColumnWidth: const IntrinsicColumnWidth(),
        children: rows.asMap().entries.map((e) {
          final i = e.key; final row = e.value; final isHdr = i == 0; final isCur = i == _stepIdx - 1 && !isHdr;
          return TableRow(
            decoration: BoxDecoration(color: isHdr ? AC.bg3 : isCur ? ac.withOpacity(.12) : i % 2 == 0 ? AC.bg2 : AC.bg),
            children: [
              _c(row.step, isHdr ? ac : AC.text2, isHdr), _c(row.visitedNode, isHdr ? ac : ac, isHdr, bold: isCur),
              ...ids.map((id) {
                final v = row.distMap[id] ?? Algorithms.infStr; final isInf = v == Algorithms.infStr;
                Color col = isHdr ? ac : isInf ? AC.text2.withOpacity(.4) : AC.text;
                if (isCur && !isInf) col = ac; return _c(v, col, isHdr, bold: isCur && !isInf);
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _bfTable(List<TableRowData> rows) {
    final ids = _nodes.map((n) => n.id).toList()..sort(); final ac = AC.forAlgo(_algo);
    TableRow buildLeft(int i, TableRowData row) {
      final isHdr = i == 0; final isCur = i == _stepIdx - 1 && !isHdr;
      return TableRow(
        decoration: BoxDecoration(color: isHdr ? AC.bg3 : isCur ? ac.withOpacity(.12) : i % 2 == 0 ? AC.bg2 : AC.bg),
        children: [
          _c(row.step, isHdr ? ac : AC.text2, isHdr), _c(row.visitedNode, isHdr ? ac : ac.withOpacity(.8), isHdr),
          ...ids.map((id) {
            final v = row.distMap[id] ?? Algorithms.infStr; final isInf = v == Algorithms.infStr;
            Color col = isHdr ? ac : isInf ? AC.text2.withOpacity(.35) : AC.text;
            if (isCur && !isInf) col = ac; return _c(v, col, isHdr, bold: isCur && !isInf);
          }),
        ],
      );
    }
    TableRow buildRight(int i, TableRowData row) {
      final isHdr = i == 0; final isCur = i == _stepIdx - 1 && !isHdr; final pm = row.prevMap ?? {};
      return TableRow(
        decoration: BoxDecoration(color: isHdr ? AC.bg3 : isCur ? ac.withOpacity(.12) : i % 2 == 0 ? AC.bg2 : AC.bg),
        children: ids.map((id) {
          final v = isHdr ? id : (pm[id] ?? '-1'); final isNone = v == '-1';
          Color col = isHdr ? ac : isNone ? AC.text2.withOpacity(.35) : AC.primary;
          if (isCur && !isNone) col = ac; return _c(v, col, isHdr, bold: isCur && !isNone);
        }).toList(),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Flexible(flex: 6, child: Column(children: [ Container(padding: const EdgeInsets.symmetric(vertical: 4), color: AC.bg3, child: Center(child: Text('MESAFE', style: TextStyle(color: ac, fontSize: 8, fontFamily: 'monospace', letterSpacing: 1.5)))), Table(border: TableBorder.all(color: AC.border, width: .5), defaultColumnWidth: const IntrinsicColumnWidth(), children: rows.asMap().entries.map((e) => buildLeft(e.key, e.value)).toList()) ])),
        Container(width: 2, color: ac.withOpacity(.6), margin: const EdgeInsets.only(top: 0)),
        Flexible(flex: 4, child: Column(children: [ Container(padding: const EdgeInsets.symmetric(vertical: 4), color: AC.bg3, child: Center(child: Text('EBEVEYN', style: TextStyle(color: ac, fontSize: 8, fontFamily: 'monospace', letterSpacing: 1.5)))), Table(border: TableBorder.all(color: AC.border, width: .5), defaultColumnWidth: const IntrinsicColumnWidth(), children: rows.asMap().entries.map((e) => buildRight(e.key, e.value)).toList()) ])),
      ]),
    );
  }

  Widget _mstTable(List<TableRowData> rows) {
    final ac = AC.forAlgo(_algo); const cols = ['kenar', 'agirlik', 'toplam'];
    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: AC.border, width: .5), defaultColumnWidth: const IntrinsicColumnWidth(),
        children: rows.asMap().entries.map((e) {
          final i = e.key; final row = e.value; final isHdr = i == 0; final isCur = i == _stepIdx - 1 && !isHdr; final isRej = row.visitedNode.contains('✗');
          return TableRow(
            decoration: BoxDecoration(color: isHdr ? AC.bg3 : isRej ? AC.red.withOpacity(.08) : isCur ? ac.withOpacity(.1) : i % 2 == 0 ? AC.bg2 : AC.bg),
            children: [
              _c(row.step, isHdr ? ac : AC.text2, isHdr), _c(row.visitedNode, isRej ? AC.red : ac, isHdr, bold: true),
              ...cols.map((col) => _c(row.distMap[col] ?? '-', isHdr ? ac : isRej ? AC.text2 : AC.text, isHdr)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _c(String text, Color color, bool isHdr, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'monospace', fontSize: isHdr ? 8 : 10, color: color, fontWeight: bold || isHdr ? FontWeight.bold : FontWeight.normal, letterSpacing: .3)),
    );
  }
}