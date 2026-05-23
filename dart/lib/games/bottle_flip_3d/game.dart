
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

class BottleFlip3DGame extends FlameGame with TapCallbacks {

  final GameDifficulty difficulty;
  int score = 0;
  double bottleRotation = 0;
  double bottleY = 0;
  double velocityY = 0;
  double rotationVelocity = 0;
  bool isFlipping = false;
  double platformX = 0;
  late ScreenShake shaker;
  late Sprite logoSprite;

  BottleFlip3DGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFFEFEBE9);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
      if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    shaker = ScreenShake();
    add(shaker);
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    score = 0;
    bottleY = size.y - 150;
    velocityY = 0;
    rotationVelocity = 0;
    bottleRotation = 0;
    isFlipping = false;
    platformX = size.x / 2;

    add(_BottleRenderer());


    add(TextComponent(
      text: 'BOTTLE FLIP 3D',
      position: Vector2(size.x / 2, size.y * 0.45),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.black.withValues(alpha: 0.05), fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: 8)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 45, 45),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.15),
    ));

    resumeEngine();
  }

  void resumeGame() {
    bottleY = size.y - 150;
    velocityY = 0;
    rotationVelocity = 0;
    bottleRotation = 0;
    isFlipping = false;
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (overlays.isActive('GameOver')) return;
    super.update(dt);

    if (isFlipping) {
      velocityY += 1200 * dt;
      bottleY += velocityY * dt;
      bottleRotation += rotationVelocity * dt;

      if (bottleY >= size.y - 150) {
        bottleY = size.y - 150;
        isFlipping = false;
        velocityY = 0;


        final rotDeg = (bottleRotation * 180 / pi) % 360;
        if (rotDeg.abs() < 20 || rotDeg.abs() > 340) {
          score++;
          platformX = 100 + Random().nextDouble() * (size.x - 200);
        } else {
          _gameOver();
        }
        bottleRotation = 0;
      }
    }
  }

  void _gameOver() {
    shaker.shake(duration: 0.5, intensity: 8);
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isFlipping) {
      isFlipping = true;
      velocityY = -800;
      rotationVelocity = pi * 4;
      shaker.shake(duration: 0.2, intensity: 3);
    }
  }
}

class _BottleRenderer extends Component with HasGameReference<BottleFlip3DGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    final bgP = _p
      ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD)])
          .createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgP);


    canvas.drawRect(Rect.fromLTWH(0, h - 110, w, 110),
        _p..color = Colors.brown.shade800);
    canvas.drawRect(Rect.fromLTWH(0, h - 110, w, 10),
        _p..color = Colors.brown.shade600);


    final platP = _p..color = Colors.deepOrangeAccent;
    final pRect = Rect.fromCenter(
        center: Offset(g.platformX, h - 120), width: 100, height: 20);
    canvas.drawRRect(
        RRect.fromRectAndRadius(pRect, const Radius.circular(5)), platP);


    canvas.save();
    canvas.translate(g.platformX, g.bottleY);
    canvas.rotate(g.bottleRotation);

    const bottleRect = Rect.fromLTWH(-15, -40, 30, 80);
    final bottlePaint = _p
      ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.5),
            Colors.blue.withValues(alpha: 0.3)
          ]).createShader(bottleRect);

    canvas.drawRRect(
        RRect.fromRectAndRadius(bottleRect, const Radius.circular(8)),
        bottlePaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bottleRect, const Radius.circular(8)),
        _p
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);


    canvas.drawRect(const Rect.fromLTWH(-15, -10, 30, 20),
        _p..color = Colors.blue.shade800);

    canvas.drawRect(const Rect.fromLTWH(-8, -45, 16, 10),
        _p..color = Colors.blue.shade900);

    canvas.restore();

    final tp = TextPainter(
        text: TextSpan(
            text: 'SCORE: ${g.score}',
            style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, 100));
  }
}
