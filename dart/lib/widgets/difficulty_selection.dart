import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/difficulty.dart';

class DifficultySelection extends StatelessWidget {
  final Function(GameDifficulty) onSelected;
  final String gameTitle;

  const DifficultySelection({
    super.key,
    required this.onSelected,
    required this.gameTitle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10 * value, sigmaY: 10 * value),
                  child: Container(color: Colors.black.withValues(alpha: 0.5 * value)),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SELECT DIFFICULTY',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            gameTitle.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 15)],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.cyanAccent.withValues(alpha: 0.8), size: 16),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'HOW TO PLAY',
                                      style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getRules(gameTitle),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildDifficultyButton(
                            context,
                            GameDifficulty.easy,
                            Colors.greenAccent,
                            'Relaxed and slow',
                          ),
                          const SizedBox(height: 16),
                          _buildDifficultyButton(
                            context,
                            GameDifficulty.medium,
                            Colors.orangeAccent,
                            'Balanced challenge',
                          ),
                          const SizedBox(height: 16),
                          _buildDifficultyButton(
                            context,
                            GameDifficulty.hard,
                            Colors.redAccent,
                            'Extreme speed',
                          ),
                          const SizedBox(height: 16),
                          _buildDifficultyButton(
                            context,
                            GameDifficulty.veryHard,
                            Colors.purpleAccent,
                            'Impossible challenge',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyButton(
    BuildContext context,
    GameDifficulty difficulty,
    Color color,
    String description,
  ) {
    return GestureDetector(
      onTap: () => onSelected(difficulty),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bolt, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    difficulty.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }
  String _getRules(String title) {
    switch (title.toLowerCase()) {
      case 'space strike': return 'Tap and drag to move. Tap to shoot enemies and survive!';
      case 'neon snake': return 'Swipe to steer. Eat food to grow. Don\'t hit walls or yourself!';
      case 'paddle clash': return 'Drag your paddle to block the ball and score points!';
      case 'baby crossing': return 'Tap or swipe up to hop! Avoid the rushing traffic to reach the goal.';
      case 'piano tiles': return 'Tap the dark ink tiles as they reach the yellow line. Don\'t miss!';
      case 'stack builder': return 'Tap to drop blocks. Align them perfectly to build the highest tower!';
      case 'cucumber cut': return 'Swipe to slice the vegetables as they pass the neon zone!';
      case 'bread cut': return 'Down-swipe to slice the bread when it perfectly aligns with the blade!';
      case 'ludo master':
      case 'ludo club': return 'Roll the dice and move your pieces. Reach home first to win!';
      case 'uno rush': return 'Match cards by color or number. Empty your hand first to be the champion!';
      case 'car parking': return 'Draw paths for cars to guide them into their matching parking spots.';
      case 'island jump': return 'Hold the screen to charge your jump. Release to hop between islands!';
      case 'color galaxy': return 'Swipe to move. Capture territory by returning to your color. Avoid trails!';
      default: return 'Use on-screen controls to play and reach the high score!';
    }
  }
}
