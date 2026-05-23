import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'game.dart';

class TurnIndicatorComponent extends PositionComponent
    with HasGameReference<LudoClubGame> {
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  Future<void> onLoad() async {
    position = Vector2(game.size.x / 2, game.boardOffset.y - 120);
    size = Vector2(game.cell * 4, game.cell * 1.5);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    final p = game.players[game.currentPlayerIdx];
    final paint = Paint()
      ..color = p.color.withValues(alpha: 0.3 + 0.3 * sin(_time * 4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(20)),
      paint,
    );
    final text = TextPainter(
      text: TextSpan(
        text: 'PLAYER ${game.currentPlayerIdx + 1} TURN',
        style: TextStyle(
          color: Colors.white,
          fontSize: game.cell * 0.6,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: p.color, blurRadius: 10)]
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
        canvas,
        Offset(
          size.x / 2 - text.width / 2,
          size.y / 2 - text.height / 2,
        ));
  }
}
