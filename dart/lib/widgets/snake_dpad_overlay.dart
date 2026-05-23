import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import '../games/neon_snake/game.dart';


class SnakeDpadOverlay extends StatelessWidget {
  final NeonSnakeGame game;

  const SnakeDpadOverlay({super.key, required this.game});

  void _dir(double x, double y) {
    game.trySetDirection(Vector2(x, y));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _arrow(Icons.keyboard_arrow_up, () => _dir(0, -1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _arrow(Icons.keyboard_arrow_left, () => _dir(-1, 0)),
                  const SizedBox(width: 56),
                  _arrow(Icons.keyboard_arrow_right, () => _dir(1, 0)),
                ],
              ),
              _arrow(Icons.keyboard_arrow_down, () => _dir(0, 1)),
              const SizedBox(height: 4),
              Text(
                'Tap arrows or swipe',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.greenAccent, size: 36),
        ),
      ),
    );
  }
}
