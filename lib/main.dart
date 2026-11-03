import 'package:flutter/material.dart';

import 'engine/game_engine.dart';
import 'screens/main_game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FadaiDaigaiApp());
}

class FadaiDaigaiApp extends StatefulWidget {
  final GameEngine? customEngine;
  final bool enablePeriodicTimer;

  const FadaiDaigaiApp({
    super.key,
    this.customEngine,
    this.enablePeriodicTimer = true,
  });

  @override
  State<FadaiDaigaiApp> createState() => _FadaiDaigaiAppState();
}

class _FadaiDaigaiAppState extends State<FadaiDaigaiApp> {
  late final GameEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = widget.customEngine ?? GameEngine();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '發達大計',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF140E0B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MainGameScreen(
        engine: _engine,
        enablePeriodicTimer: widget.enablePeriodicTimer,
      ),
    );
  }
}
