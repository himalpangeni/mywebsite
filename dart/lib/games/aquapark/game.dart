import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import 'dart:math';


class AquaparkGame extends FlameGame with PanDetector {
  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;
  late ScreenShake shaker;

  double playerX = 0;
  double _time = 0;
  final List<Obstacle> obstacles = [];
  final List<Splash> splashes = [];
  double spawnT = 0;
  double laneWidth = 200;

  AquaparkGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF0077B6);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    _random = Random();
    await super.onLoad();
    shaker = ScreenShake();
    add(shaker);
    add(CinematicOverlay());
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
    _time = 0;
    playerX = size.x / 2;
    obstacles.clear();
    splashes.clear();
    spawnT = 0.4;
    laneWidth = size.x * 0.7;

    hud = TextComponent(
      text: 'SCORE: 0',
      position: Vector2(size.x / 2, 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(
        color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900,
        shadows: [Shadow(color: Colors.blue, blurRadius: 10)],
      )),
    );
    add(hud);
    add(_SlideRenderer());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    obstacles.clear();
    splashes.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _lose() {
    gameOver = true;
    shaker.shake(duration: 0.5, intensity: 15);
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    _time += dt;
    score += (dt * 20 * difficulty.speedMultiplier).round();
    hud.text = 'SCORE: $score';


    spawnT -= dt;
    if (spawnT <= 0) {
      spawnT = (0.6 / difficulty.speedMultiplier).clamp(0.25, 1.0);
      final type = Random().nextInt(3);
      double gap = size.x * 0.25;
      obstacles.add(Obstacle(
        x: gap + _random.nextDouble() * (size.x - gap * 2),
        y: -60,
        type: type,
      ));
    }


    for (int i = splashes.length - 1; i >= 0; i--) {
      splashes[i].life -= dt;
      if (splashes[i].life <= 0) splashes.removeAt(i);
    }


    final halfLane = laneWidth / 2;
    playerX = playerX.clamp(size.x / 2 - halfLane, size.x / 2 + halfLane);

    final pCenter = Offset(playerX, size.y - 180);
    const pRadius = 22.0;

    for (int i = obstacles.length - 1; i >= 0; i--) {
      final o = obstacles[i];
      o.y += (320 + score * 0.05) * difficulty.speedMultiplier * dt;

      final oCenter = Offset(o.x, o.y);
      final dist = (pCenter - oCenter).distance;

      if (dist < pRadius + o.radius - 5) {
        if (o.type == 2) {
          score += 100;
          obstacles.removeAt(i);
        } else {
          _lose();
          return;
        }
      }

      if (o.y > size.y + 80) {

        splashes.add(Splash(x: o.x, y: size.y - 80));
        obstacles.removeAt(i);
      }
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameOver) return;
    playerX += info.delta.global.x * 1.2;
  }
}

class Obstacle {
  double x, y;
  int type;
  double radius;
  Obstacle({required this.x, required this.y, required this.type})
      : radius = type == 2 ? 20 : (type == 1 ? 28 : 22);
}

class Splash {
  double x, y, life;
  Splash({required this.x, required this.y}) : life = 0.6;
}

class _SlideRenderer extends Component with HasGameReference<AquaparkGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    final cx = w / 2;
    final t = g._time;


    final leftX = cx - g.laneWidth / 2;
    final rightX = cx + g.laneWidth / 2;


    final stripePaint = _p..color = Colors.white.withValues(alpha: 0.08)..strokeWidth = 8;
    for (int i = 0; i < 12; i++) {
      double yOffset = (t * 200 + i * h / 10) % h;
      canvas.drawLine(Offset(leftX, yOffset), Offset(rightX, yOffset), stripePaint);
    }


    final edgePaint = _p..color = const Color(0xFF00B4D8)..strokeWidth = 14..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawLine(Offset(leftX, 0), Offset(leftX, h), edgePaint);
    canvas.drawLine(Offset(rightX, 0), Offset(rightX, h), edgePaint);


    for (int i = 0; i < 8; i++) {
      double by = (t * 150 + i * h / 8) % h;
      canvas.drawCircle(Offset(leftX + 10, by), 6, _p..color = Colors.white.withValues(alpha: 0.4));
      canvas.drawCircle(Offset(rightX - 10, by), 6, _p..color = Colors.white.withValues(alpha: 0.4));
    }


    for (final o in g.obstacles) {
      if (o.type == 0) {

        canvas.drawCircle(Offset(o.x, o.y), o.radius, _p..color = Colors.orange);
        canvas.drawCircle(Offset(o.x, o.y), o.radius, _p..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
        canvas.drawLine(Offset(o.x, o.y - o.radius), Offset(o.x, o.y + o.radius), _p..color = Colors.white..strokeWidth = 2);
      } else if (o.type == 1) {

        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(o.x, o.y), width: o.radius * 1.8, height: o.radius * 2.2), const Radius.circular(10)), _p..color = const Color(0xFF795548));
        for (int r = 0; r < 3; r++) {
          canvas.drawLine(Offset(o.x - o.radius * 0.9, o.y - 14 + r*14), Offset(o.x + o.radius * 0.9, o.y - 14 + r*14), _p..color = Colors.brown.shade900..strokeWidth = 4);
        }
      } else {

        canvas.drawCircle(Offset(o.x, o.y), o.radius, _p..color = Colors.yellow);
        canvas.drawCircle(Offset(o.x, o.y), o.radius, _p..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.orange);
        canvas.drawRect(Rect.fromCenter(center: Offset(o.x, o.y), width: 6, height: 16), _p..style = PaintingStyle.fill..color = Colors.orange);
      }
    }


    for (final s in g.splashes) {
      final alpha = s.life / 0.6;
      for (int i = 0; i < 8; i++) {
        double ang = i * pi / 4;
        double dist = 20 * (1 - s.life / 0.6);
        canvas.drawCircle(
          Offset(s.x + cos(ang) * dist, s.y - sin(ang) * dist * 0.5),
          4 * alpha,
          _p..color = Colors.cyan.withValues(alpha: alpha * 0.7),
        );
      }
    }


    final px = g.playerX;
    final py = h - 180;


    canvas.drawOval(Rect.fromCenter(center: Offset(px, py + 20), width: 50, height: 20), _p..color = Colors.white.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));


    canvas.drawCircle(Offset(px, py + 10), 26, _p..color = Colors.pinkAccent.withValues(alpha: 0.8));
    canvas.drawCircle(Offset(px, py + 10), 18, _p..color = Colors.transparent);


    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(px, py - 5), width: 24, height: 32), const Radius.circular(6)), _p..color = Colors.deepOrange);

    canvas.drawCircle(Offset(px, py - 28), 14, _p..color = Colors.orange.shade200);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px - 11, py - 33, 22, 9), const Radius.circular(4)), _p..color = Colors.lightBlue.withValues(alpha: 0.8));
    canvas.drawCircle(Offset(px, py - 28 + 8), 3, _p..color = Colors.white.withValues(alpha: 0.5));


    if (g.score < 30) {
      final tp = TextPainter(
        text: const TextSpan(text: 'DRAG LEFT / RIGHT TO STEER', style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 2)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, h - 80));
    }
  }
}
