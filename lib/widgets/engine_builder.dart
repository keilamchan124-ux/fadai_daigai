import 'package:flutter/material.dart';

import '../engine/game_engine.dart';

class EngineBuilder extends StatefulWidget {
  final GameEngine engine;
  final Widget Function(BuildContext context, Widget? child) builder;

  const EngineBuilder({
    super.key,
    required this.engine,
    required this.builder,
  });

  @override
  State<EngineBuilder> createState() => _EngineBuilderState();
}

class _EngineBuilderState extends State<EngineBuilder> {
  void _onEngineChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onEngineChanged);
  }

  @override
  void didUpdateWidget(covariant EngineBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      oldWidget.engine.removeListener(_onEngineChanged);
      widget.engine.addListener(_onEngineChanged);
    }
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngineChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, null);
  }
}
