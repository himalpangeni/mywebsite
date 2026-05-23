import 'dart:ui';
import 'package:flutter/material.dart';

class UniversalGameOver extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final Future<void> Function()? onContinue;
  final VoidCallback? onNextLevel;
  final bool isVictory;
  final String gameTitle;
  final String scoreLabel;
  final String? victoryTitleOverride;

  const UniversalGameOver({
    super.key,
    required this.score,
    required this.onRestart,
    required this.onHome,
    this.onContinue,
    this.onNextLevel,
    required this.gameTitle,
    this.isVictory = false,
    this.scoreLabel = 'SCORE',
    this.victoryTitleOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Container(color: Colors.black87),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: isVictory ? Colors.greenAccent : Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: (isVictory ? Colors.green : Colors.black).withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gameTitle.toUpperCase(),
                      style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isVictory ? (victoryTitleOverride ?? 'VICTORY') : 'GAME OVER',
                      style: TextStyle(color: isVictory ? Colors.greenAccent : Colors.redAccent, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2, shadows: [Shadow(color: isVictory ? Colors.green : Colors.red, blurRadius: 20)]),
                    ),
                    if (isVictory) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'CONGRATULATIONS!',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                    ],
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        '$scoreLabel: $score',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyan, blurRadius: 10)]),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        if (onContinue != null)
                          _buildNeonButton(icon: Icons.play_circle_fill, label: 'WATCH AD', color: Colors.yellowAccent, onTap: () async {
                            await onContinue!();
                            FocusManager.instance.primaryFocus?.unfocus();
                          }),
                        if (isVictory && onNextLevel != null)
                          _buildNeonButton(icon: Icons.play_arrow, label: 'NEXT', color: Colors.greenAccent, onTap: () {
                            onNextLevel!();
                            FocusManager.instance.primaryFocus?.unfocus();
                          })
                        else
                          _buildNeonButton(icon: Icons.refresh, label: 'RESTART', color: Colors.cyanAccent, onTap: () {
                            onRestart();
                            FocusManager.instance.primaryFocus?.unfocus();
                          }),
                        _buildNeonButton(icon: Icons.home, label: 'HOME', color: Colors.white, onTap: () {
                          onHome();
                          FocusManager.instance.primaryFocus?.unfocus();
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
