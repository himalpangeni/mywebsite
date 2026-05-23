import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';



class AssetFailSafe {
  static Future<Sprite?> loadSpriteSafe(
    FlameGame game,
    String path, {
    Vector2? srcPosition,
    Vector2? srcSize,
  }) async {
    try {
      return await game.loadSprite(path, srcPosition: srcPosition, srcSize: srcSize);
    } catch (e) {
      debugPrint('ASSET_ERROR: Missing $path. Using procedural fallback.');
      return null;
    }
  }


  static void renderFallback(Canvas canvas, Vector2 size, Color color, {bool isCircle = false}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    if (isCircle) {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);

      canvas.drawCircle(Offset(size.x * 0.35, size.y * 0.35), size.x * 0.1, Paint()..color = Colors.white.withValues(alpha: 0.3));
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(8)), paint);
    }
  }
}
