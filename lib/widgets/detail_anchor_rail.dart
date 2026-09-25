import 'package:flutter/material.dart';

class DetailAnchorRail extends StatefulWidget {
  final ScrollController controller;
  final List<String> labels;

  const DetailAnchorRail({
    super.key,
    required this.controller,
    required this.labels,
  });

  @override
  State<DetailAnchorRail> createState() => _DetailAnchorRailState();
}

class _DetailAnchorRailState extends State<DetailAnchorRail> {
  int _active = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  void _sync() {
    if (!widget.controller.hasClients || widget.labels.length < 2) return;
    final max = widget.controller.position.maxScrollExtent;
    final next = max <= 0
        ? 0
        : ((widget.controller.offset / max) * (widget.labels.length - 1))
              .round()
              .clamp(0, widget.labels.length - 1);
    if (next != _active && mounted) setState(() => _active = next);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '详情分区导航',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.labels.length, (index) {
            final selected = index == _active;
            return Tooltip(
              message: widget.labels[index],
              child: InkWell(
                onTap: () {
                  if (!widget.controller.hasClients) return;
                  final max = widget.controller.position.maxScrollExtent;
                  final target = widget.labels.length == 1
                      ? 0.0
                      : max * index / (widget.labels.length - 1);
                  widget.controller.animateTo(
                    target,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                  );
                },
                child: SizedBox(
                  width: 28,
                  height: 27,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: selected ? 14 : 7,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected ? cs.primary : cs.outline,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
