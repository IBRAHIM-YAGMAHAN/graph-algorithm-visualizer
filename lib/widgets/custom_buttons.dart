import 'package:flutter/material.dart';
import '../models/graph_model.dart';
import '../utils/colors.dart';

class ModeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final EditMode mode, cur;
  final Color ac;
  final VoidCallback onTap;
  const ModeBtn({super.key, required this.icon, required this.label, required this.mode, required this.cur, required this.ac, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = mode == cur;
    final c = active ? ac : AC.text2;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
            color: active ? c.withOpacity(.15) : Colors.transparent,
            border: Border.all(color: active ? c : AC.border),
            borderRadius: BorderRadius.circular(3)
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: c), const SizedBox(width: 4),
          Text(label, style: TextStyle(color: c, fontSize: 10, fontFamily: 'monospace', fontWeight: active ? FontWeight.bold : FontWeight.normal))
        ]),
      ),
    );
  }
}

class SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const SmallBtn({super.key, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(.5)),
            borderRadius: BorderRadius.circular(3)
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace')),
      ),
    );
  }
}

class FuturisticButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const FuturisticButton({super.key, required this.label, required this.color, required this.onTap});
  @override State<FuturisticButton> createState() => _FuturisticButtonState();
}

class _FuturisticButtonState extends State<FuturisticButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap, onTapDown: (_) => setState(() => _h = true), onTapUp: (_) => setState(() => _h = false), onTapCancel: () => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
            color: _h ? widget.color : Colors.transparent,
            border: Border.all(color: widget.color),
            borderRadius: BorderRadius.circular(4)
        ),
        child: Center(
            child: Text(widget.label, style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: _h ? Colors.white : widget.color, letterSpacing: 1))
        ),
      ),
    );
  }
}