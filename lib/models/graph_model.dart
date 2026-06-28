import 'package:flutter/material.dart';

class GraphNode {
  final String id;
  Offset position;
  GraphNode({required this.id, required this.position});
}

class GraphEdge {
  final String from, to;
  final int weight;
  const GraphEdge({required this.from, required this.to, required this.weight});
}

enum StepType { init, visit, update, path, done, reject, add }
enum EditMode { view, addNode, addEdge, deleteItem }

class AlgoStep {
  final StepType type;
  final Map<String, int> dist;
  final Map<String, String?> prev;
  final Set<String> visited, mstNodes, mstEdges;
  final String? activeEdge, activeNode;
  final List<String>? path;
  final String log;
  final Color logColor;
  final List<TableRowData> tableRows;

  const AlgoStep({
    required this.type,
    required this.dist,
    required this.prev,
    required this.visited,
    required this.log,
    required this.logColor,
    required this.tableRows,
    this.mstNodes = const {},
    this.mstEdges = const {},
    this.activeEdge,
    this.activeNode,
    this.path,
  });
}

class TableRowData {
  final String step, visitedNode;
  final Map<String, String> distMap;
  final Map<String, String>? prevMap;

  const TableRowData({
    required this.step,
    required this.visitedNode,
    required this.distMap,
    this.prevMap,
  });
}