import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import 'dart:math';

class CrazyRunGame extends FlameGame with PanDetector, TapCallbacks {

  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;

  double pY = 0;
  double pVy = 0;
  final List<double> blocks = [];
  double spawnT = 0;

  CrazyRunGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF102218);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    await super.onLoad();
    restart();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    gameOver = false;
    score = 0;
    pY = size.y - 120;
    pVy = 0;
    blocks.clear();
    spawnT = 1.0;

    hud = TextComponent(
        text: 'Score: 0',
        position: Vector2(20, 40),
        textRenderer: TextPaint(
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)));
    add(hud);
    add(_RunRenderer());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    pY = size.y - 120;
    pVy = -700;
    blocks.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _lose() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void _jump() {
    if (gameOver) return;
    if (pY >= size.y - 121) {
      pVy = -700;
    } else if (pY > size.y - 250 && pVy > -200) {

      pVy = -600;
    }
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);

    score++;
    hud.text = 'Score: ${score ~/ 10}';

    pVy += 1800 * dt;
    pY += pVy * dt;
    if (pY > size.y - 120) {
      pY = size.y - 120;
      pVy = 0;
    }

    spawnT -= dt;
    if (spawnT <= 0) {
      spawnT = (Random().nextDouble() * 1.4 + 0.6) / difficulty.speedMultiplier;
      blocks.add(size.x);
    }

    for (int i = blocks.length - 1; i >= 0; i--) {
      blocks[i] -= 350 * difficulty.speedMultiplier * dt;

      final bLeft = blocks[i] - 20;
      final bRight = blocks[i] + 20;
      const pRight = 75.0;
      const pLeft = 25.0;

      if (bLeft < pRight && bRight > pLeft && pY > size.y - 160) {
        _lose();
      }

      if (blocks[i] < -100) blocks.removeAt(i);
    }
  }

  @override
  void onTapDown(TapDownEvent event) => _jump();

  @override
  void onPanDown(DragDownInfo info) => _jump();

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (info.delta.global.y < -5) _jump();
  }
}

class _RunRenderer extends Component with HasGameReference<CrazyRunGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    canvas.drawRect(Rect.fromLTWH(0, h - 120, w, 120),
        _p..color = const Color(0xFF1B1B2F));
    canvas.drawLine(
        Offset(0, h - 120),
        Offset(w, h - 120),
        _p
          ..color = Colors.cyanAccent.withValues(alpha: 0.5)
          ..strokeWidth = 3);


    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(50, g.pY - 25), width: 45, height: 50),
            const Radius.circular(8)),
        _p
          ..color = Colors.redAccent
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(50, g.pY - 25), width: 45, height: 50),
            const Radius.circular(8)),
        _p..color = Colors.redAccent);


    for (final b in g.blocks) {
      final rect =
          Rect.fromCenter(center: Offset(b, h - 145), width: 40, height: 50);
      canvas.drawRect(
          rect,
          _p
            ..color = Colors.cyanAccent
            ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 5));
      canvas.drawRect(
          rect,
          _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white);
    }
  }
}
