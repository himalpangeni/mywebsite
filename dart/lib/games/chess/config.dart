import 'package:flutter/material.dart';
import '../../models/difficulty.dart';

class ChessConfigScreen extends StatefulWidget {
  final void Function(bool vsBot, bool playWhite, GameDifficulty difficulty) onStart;
  const ChessConfigScreen({super.key, required this.onStart});

  @override
  State<ChessConfigScreen> createState() => _ChessConfigScreenState();
}

class _ChessConfigScreenState extends State<ChessConfigScreen> {
  bool vsBot = true;
  bool playWhite = true;
  GameDifficulty difficulty = GameDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111820),
      appBar: AppBar(
        title: const Text('CHESS SETUP'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SELECT MODE',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _modeButton('1 PLAYER', true),
                  const SizedBox(width: 16),
                  _modeButton('2 PLAYERS', false),
                ],
              ),
              const SizedBox(height: 40),
              if (vsBot) ...[
                const Text(
                  'CHOOSE COLOR',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _sideButton('WHITE', true),
                    const SizedBox(width: 16),
                    _sideButton('BLACK', false),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'BOT DIFFICULTY',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _difficultyButton('EASY', GameDifficulty.easy),
                    _difficultyButton('MED', GameDifficulty.medium),
                    _difficultyButton('HARD', GameDifficulty.hard),
                    _difficultyButton('VERY HARD', GameDifficulty.veryHard),
                  ],
                ),
              ],
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () {
                  widget.onStart(vsBot, playWhite, difficulty);
                },
                child: const Text('START GAME', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String label, bool isBotMode) {
    final selected = vsBot == isBotMode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => vsBot = isBotMode),
      child: Container(
        width: 140,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? Colors.cyanAccent.withValues(alpha: 0.25) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.cyanAccent : Colors.white24, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white60, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _sideButton(String label, bool white) {
    final selected = playWhite == white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => playWhite = white),
      child: Container(
        width: 120,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.white : Colors.white24, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white60, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _difficultyButton(String label, GameDifficulty diff) {
    final selected = difficulty == diff;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => difficulty = diff),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 42,
        decoration: BoxDecoration(
          color: selected ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.cyanAccent : Colors.white24, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white60, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
