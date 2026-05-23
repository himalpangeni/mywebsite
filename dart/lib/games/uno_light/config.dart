import 'package:flutter/material.dart';
import '../../models/difficulty.dart';

class UnoConfigScreen extends StatefulWidget {
  final void Function(int totalPlayers, GameDifficulty difficulty) onStart;

  const UnoConfigScreen({super.key, required this.onStart});

  @override
  State<UnoConfigScreen> createState() => _UnoConfigScreenState();
}

class _UnoConfigScreenState extends State<UnoConfigScreen> {
  int totalPlayers = 4;
  GameDifficulty difficulty = GameDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A52),
      appBar: AppBar(
        title: const Text('UNO SETUP'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'HOW MANY PLAYERS?',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _playerButton(2),
                    const SizedBox(width: 12),
                    _playerButton(3),
                    const SizedBox(width: 12),
                    _playerButton(4),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'You + ${totalPlayers - 1} bot${totalPlayers == 2 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 36),
                const Text(
                  'DIFFICULTY',
                  style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _difficultyButton('EASY', GameDifficulty.easy),
                    const SizedBox(width: 12),
                    _difficultyButton('MED', GameDifficulty.medium),
                    const SizedBox(width: 12),
                    _difficultyButton('HARD', GameDifficulty.hard),
                  ],
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () {
                    widget.onStart(totalPlayers, difficulty);
                  },
                  child: const Text('START UNO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playerButton(int players) {
    final selected = totalPlayers == players;
    return GestureDetector(
      onTap: () => setState(() => totalPlayers = players),
      child: Container(
        width: 64,
        height: 56,
        decoration: BoxDecoration(
          color: selected ? Colors.cyanAccent.withValues(alpha: 0.22) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.cyanAccent : Colors.white24, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          '$players',
          style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _difficultyButton(String label, GameDifficulty diff) {
    final selected = difficulty == diff;
    return GestureDetector(
      onTap: () => setState(() => difficulty = diff),
      child: Container(
        width: 80,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.cyanAccent : Colors.white24, width: 1.6),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
