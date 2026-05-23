import 'package:flutter/material.dart';
import 'game.dart';
import '../../models/difficulty.dart';

class TicTacToeConfigScreen extends StatefulWidget {
  final Function(CellState, bool, GameDifficulty) onStart;
  const TicTacToeConfigScreen({super.key, required this.onStart});

  @override
  State<TicTacToeConfigScreen> createState() => _TicTacToeConfigScreenState();
}

class _TicTacToeConfigScreenState extends State<TicTacToeConfigScreen> {
  CellState selectedSide = CellState.x;
  bool isVsBot = true;
  GameDifficulty difficulty = GameDifficulty.medium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      appBar: AppBar(title: const Text('Tic-Tac-Toe Setup'), backgroundColor: Colors.transparent),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('CHOOSE YOUR SIDE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _choiceCard('X', CellState.x, Colors.cyanAccent),
                const SizedBox(width: 30),
                _choiceCard('O', CellState.o, Colors.pinkAccent),
              ],
            ),
            const SizedBox(height: 50),
            const Text('OPPONENT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _opponentBtn('BOT', true),
                const SizedBox(width: 20),
                _opponentBtn('LOCAL', false),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _diffBtn('EASY', GameDifficulty.easy),
                const SizedBox(width: 10),
                _diffBtn('MED', GameDifficulty.medium),
                const SizedBox(width: 10),
                _diffBtn('HARD', GameDifficulty.hard),
              ],
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(200, 50)),
              onPressed: () => widget.onStart(selectedSide, isVsBot, difficulty),
              child: const Text('PLAY NOW'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diffBtn(String label, GameDifficulty diff) {
      bool isSelected = difficulty == diff;
      return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white10),
          onPressed: () => setState(() => difficulty = diff),
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 12)),
      );
  }

  Widget _choiceCard(String label, CellState side, Color color) {
    bool isSelected = selectedSide == side;
    return GestureDetector(
      onTap: () => setState(() => selectedSide = side),
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.white24, width: 3),
        ),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? color : Colors.white38, fontSize: 48, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _opponentBtn(String label, bool vsBot) {
      bool isSelected = isVsBot == vsBot;
      return ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
          onPressed: () => setState(() => isVsBot = vsBot),
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white38)),
      );
  }
}
