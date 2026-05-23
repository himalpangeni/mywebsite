import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DiceComponent extends PositionComponent with HasGameReference {


  int value = 1;
  bool isRolling = false;
  double _rollTime = 0;
  final Random _rng = Random();

  DiceComponent() : super(size: Vector2(100, 100), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    _drawDice(canvas, value, isRolling);
  }

  void roll() {
    isRolling = true;
    _rollTime = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isRolling) {
      _rollTime += dt;
      if (_rollTime > 0.8) {
        isRolling = false;
      } else {
        value = _rng.nextInt(6) + 1;
      }
    }
  }

  void _drawDice(Canvas canvas, int val, bool rolling) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);


    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          rect.shift(const Offset(6, 8)), const Radius.circular(16)));
    canvas.drawShadow(shadowPath, Colors.black, 10, true);


    final paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.4, -0.4),
        colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
        stops: [0.0, 0.4, 1.0],
      ).createShader(rect);

    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)), paint);


    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.0)
        ],
      ).createShader(rect.deflate(4));
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(12)),
        highlightPaint);


    final dotPaint = Paint()..color = const Color(0xFF212121);
    final dotHighlight = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final q1 = size.x * 0.25;
    final q3 = size.x * 0.75;
    final m = size.x * 0.5;

    final dotPos = {
      1: [Offset(m, m)],
      2: [Offset(q1, q1), Offset(q3, q3)],
      3: [Offset(q1, q1), Offset(m, m), Offset(q3, q3)],
      4: [Offset(q1, q1), Offset(q3, q1), Offset(q1, q3), Offset(q3, q3)],
      5: [
        Offset(q1, q1),
        Offset(q3, q1),
        Offset(m, m),
        Offset(q1, q3),
        Offset(q3, q3)
      ],
      6: [
        Offset(q1, q1),
        Offset(q3, q1),
        Offset(q1, m),
        Offset(q3, m),
        Offset(q1, q3),
        Offset(q3, q3)
      ],
    }[val]!;

    for (final pos in dotPos) {

      canvas.drawCircle(pos, 8, dotPaint);
      canvas.drawCircle(pos.translate(1, 1), 8, dotHighlight);
    }

    if (rolling) {

      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)),
          Paint()..color = Colors.white.withValues(alpha: 0.3));
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(_rollTime * 10);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero, width: size.x, height: size.y),
              const Radius.circular(16)),
          Paint()..color = Colors.white.withValues(alpha: 0.2));
      canvas.restore();
    }
  }
}
