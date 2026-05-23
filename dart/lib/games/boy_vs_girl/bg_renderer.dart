import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'game.dart';

class DarkBgRenderer extends Component with HasGameReference<BoyVsGirlGame> {
  @override
  void render(Canvas canvas) {
    final rect = game.size.toRect();
    const gradient = RadialGradient(
      center: Alignment(0.3, -0.3),
      colors: [
        Color(0xFF1A0033),
        Color(0xFF0A0A1A),
        Color(0xFF000011),
      ],
      stops: [0.0, 0.5, 1.0],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    

    final ringPaint = Paint()
      ..shader = const LinearGradient(colors: [Colors.purpleAccent, Colors.cyanAccent]).createShader(Rect.fromLTWH(0, 0, game.size.x, game.size.y * 0.8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(game.size.toOffset() / 2, game.size.y * 0.35, ringPaint);
  }
}
