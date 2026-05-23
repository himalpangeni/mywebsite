import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import 'dart:math';

class StackBuilderGame extends FlameGame with TapCallbacks {

  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;

  final List<Block> stackBlocks = [];
  Block? movingBlock;

  double towerY = 0;
  final double blockH = 30;
  int dir = 1;

  StackBuilderGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF2C3E50);

  @override
  Future<void> onLoad() async {

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
    stackBlocks.clear();


    final h = size.y;
    final w = size.x;
    final gameH = min(h, w * 1.8);
    final topMargin = (h - gameH) / 2;
    towerY = topMargin + gameH - 120;


    stackBlocks.add(Block(x: size.x / 2, y: towerY, w: 220));
    add(_Pedestal(y: towerY + 15));

    _spawnNext();

    hud = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 60),
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
    );
    add(hud);
    add(_Pedestal(y: towerY + 15));
    add(_StackRenderer());
    resumeEngine();
  }

  void _spawnNext() {
    if (gameOver) return;
    final top = stackBlocks.last;
    movingBlock = Block(x: 0, y: top.y - blockH, w: top.w);
    dir = Random().nextBool() ? 1 : -1;
    movingBlock!.x = dir > 0 ? -top.w : size.x + top.w;
  }

  void resumeGame() {
    gameOver = false;
    _spawnNext();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _lose() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);

    if (movingBlock != null) {
      final speed =
          (200 + score * 15 * difficulty.speedMultiplier).clamp(200.0, 600.0);
      movingBlock!.x += dir * speed * dt;
      if (dir > 0 && movingBlock!.x > size.x + movingBlock!.w) dir = -1;
      if (dir < 0 && movingBlock!.x < -movingBlock!.w) dir = 1;
    }


    if (stackBlocks.last.y < size.y / 2) {
      final delta = (size.y / 2 - stackBlocks.last.y) * 5 * dt;
      for (final b in stackBlocks) {
        b.y += delta;
      }
      if (movingBlock != null) movingBlock!.y += delta;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver || movingBlock == null) return;

    final top = stackBlocks.last;
    final m = movingBlock!;

    final overlap = min(m.x + m.w / 2, top.x + top.w / 2) -
        max(m.x - m.w / 2, top.x - top.w / 2);

    if (overlap <= 0) {
      _lose();
      return;
    }


    if ((m.x - top.x).abs() < 5) {
      m.x = top.x;
      score += 2;
    } else {
      m.w = overlap;
      m.x = max(m.x - m.w / 2, top.x - top.w / 2) + overlap / 2;
      score += 1;
    }

    stackBlocks.add(m);
    hud.text = 'Score: $score';
    movingBlock = null;

    _spawnNext();
  }
}

class Block {
  double x, y, w;
  Block({required this.x, required this.y, required this.w});
}

class _StackRenderer extends Component with HasGameReference<StackBuilderGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;

    for (int i = 0; i < g.stackBlocks.length; i++) {
      final b = g.stackBlocks[i];
      final r = Rect.fromCenter(
          center: Offset(b.x, b.y), width: b.w, height: g.blockH);
      final baseColor =
          HSVColor.fromAHSV(1, (i * 15.0) % 360, 0.7, 0.9).toColor();

      canvas.drawRect(r, _p..color = baseColor);

      canvas.drawRect(
          r,
          _p
            ..shader = LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.2)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(r));
      canvas.drawRect(
          r,
          _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.black26);
    }

    if (g.movingBlock != null) {
      final m = g.movingBlock!;
      final r = Rect.fromCenter(
          center: Offset(m.x, m.y), width: m.w, height: g.blockH);
      final baseColor =
          HSVColor.fromAHSV(1, (g.stackBlocks.length * 15.0) % 360, 0.7, 0.9)
              .toColor();

      canvas.drawRect(r, _p..color = baseColor);
      canvas.drawRect(
          r,
          _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Colors.white70);
    }
  }
}

class _Pedestal extends Component with HasGameReference<StackBuilderGame> {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  final double y;
  _Pedestal({required this.y});

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(game.size.x / 2 - 120, y, 240, 200);
    final paint = _p
      ..shader = const LinearGradient(
        colors: [Color(0xFF34495E), Color(0xFF2C3E50)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);


    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.cyanAccent.withValues(alpha: 0.5));
  }
}
