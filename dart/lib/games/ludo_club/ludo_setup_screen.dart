import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game.dart';

class LudoSetupScreen extends StatefulWidget {
  const LudoSetupScreen({super.key});

  @override
  State<LudoSetupScreen> createState() => _LudoSetupScreenState();
}

class _LudoSetupScreenState extends State<LudoSetupScreen> {
  int humanCount = 1;
  final List<Color?> selectedColors = [null, null, null, null];
  final List<Color> availableColors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A3A),
      appBar: AppBar(
        title: const Text('Ludo Club Setup',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Number of human players:',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 3, 4].map((count) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ChoiceChip(
                    label: Text('$count',
                        style: const TextStyle(color: Colors.white)),
                    selected: humanCount == count,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          humanCount = count;
                          for (int i = humanCount; i < 4; i++) {
                            selectedColors[i] = null;
                          }
                        });
                      }
                    },
                    selectedColor: Colors.orange,
                    backgroundColor: Colors.grey[800],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text('Select colors for each human player:',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 16),
            ...List.generate(humanCount, (index) => _buildColorPicker(index)),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _allColorsSelected ? _startGame : null,
              child: const Text('START GAME',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(int playerIndex) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text('Player ${playerIndex + 1}:',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(width: 20),
            ...List.generate(availableColors.length, (i) {
              final color = availableColors[i];
              final isSelected = selectedColors[playerIndex] == color;
              final isTaken = selectedColors.contains(color) &&
                  selectedColors[playerIndex] != color;
              return GestureDetector(
                onTap: isTaken
                    ? null
                    : () {
                        setState(() {
                          selectedColors[playerIndex] = color;
                        });
                      },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3),
                  ),
                  child: isTaken
                      ? const Center(
                          child:
                              Icon(Icons.block, color: Colors.white, size: 20))
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool get _allColorsSelected {
    for (int i = 0; i < humanCount; i++) {
      if (selectedColors[i] == null) return false;
    }
    return true;
  }

  void _startGame() {
    final List<PlayerSetup> playerSetups = [];
    final List<Color> allColors = [
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.blue
    ];
    final List<Color> assigned = [];
    for (int i = 0; i < humanCount; i++) {
      final col = selectedColors[i]!;
      assigned.add(col);
      playerSetups.add(PlayerSetup(color: col, isAI: false));
    }
    for (var col in allColors) {
      if (!assigned.contains(col)) {
        playerSetups.add(PlayerSetup(color: col, isAI: true));
      }
    }
    playerSetups.sort((a, b) =>
        allColors.indexOf(a.color).compareTo(allColors.indexOf(b.color)));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => GameWidget(
                game: LudoClubGame(setupPlayers: playerSetups),
                overlayBuilderMap: {
                  'RulesUI': (context, game) =>
                      _buildRulesUI(context, game as LudoClubGame),
                  'GameOver': (context, game) =>
                      _buildGameOverUI(game as LudoClubGame),
                },
                initialActiveOverlays: const ['RulesUI'],
              )),
    );
  }

  Widget _buildRulesUI(BuildContext ctx, LudoClubGame game) {
    return Positioned(
      top: 50,
      right: 20,
      child: IconButton(
        icon: const Icon(Icons.menu_book, color: Colors.white, size: 36),
        onPressed: () {
          showDialog(
            context: ctx,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text('Ludo Club Rules', style: TextStyle(color: Colors.white)),
              content: const SingleChildScrollView(
                child: Text(
                  '🎲 Rolling:\n- Tap the dice (matches your color) to roll.\n- You MUST roll a 6 to bring a token out of the yard!\n- Rolling a 6 grants an extra turn.\n- Rolling three 6s in a row cancels your move and skips your turn.\n\n⚔️ Movement & Capturing:\n- Movement is mandatory if possible.\n- Landing on an opponent sends them back to their yard!\n- Star cells are Safe Squares (no capturing aloud).\n- Stacking 2+ of your own tokens creates a Block; opponents cannot pass or land on your block.\n\n🏁 Winning:\nFirst to move all 4 tokens exactly into the center wins!',
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('GOT IT'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameOverUI(LudoClubGame game) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME OVER',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Winner: Player ${(game.winnerIdx ?? 0) + 1}',
                style: const TextStyle(color: Colors.yellow, fontSize: 20)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LudoSetupScreen()));
              },
              child: const Text('PLAY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}
