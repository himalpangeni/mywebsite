
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';

class Pipe {
  double x;
  final double gapCenter;
  final double gapSize;
  Pipe({required this.x, required this.gapCenter, required this.gapSize});
}

class FlappyBirdGame extends FlameGame with TapCallbacks {

  final GameDifficulty difficulty;
  double birdY = 0;
  double birdVy = 0;
  double birdAngle = 0;
  final List<Pipe> pipes = [];
  double spawnT = 0;
  double _time = 0;

  int score = 0;
  bool isGameOver = false;
  late TextComponent scoreText;
  late ScreenShake shaker;
  late Sprite logoSprite;

  FlappyBirdGame({required this.difficulty}) : super();

  @override
  Color backgroundColor() => const Color(0xFF4EC0CA);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
      if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    birdY = size.y / 2;
    birdVy = 0;
    birdAngle = 0;
    pipes.clear();
    score = 0;
    isGameOver = false;
    spawnT = 2.0;

    scoreText = TextComponent(
      text: '0',
      position: Vector2(size.x / 2, 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 80,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black26, offset: Offset(4, 4), blurRadius: 10)
          ],
        ),
      ),
    );
    add(scoreText);


    add(TextComponent(
      text: 'FLAPPY BIRD',
      position: Vector2(size.x / 2, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 6)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 40, 40),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.3),
    ));

    add(CinematicOverlay());
    shaker = ScreenShake();
    add(shaker);
    add(_BirdRenderer());
    resumeEngine();
  }

  void resumeGame() {
    isGameOver = false;
    birdY = size.y / 2;
    birdVy = 0;
    birdAngle = 0;
    pipes.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;
    _time += dt;

    birdVy += 1200 * dt;
    birdY += birdVy * dt;
    birdAngle = (birdVy / 1000).clamp(-0.5, 0.8);

    if (birdY < 0 || birdY > size.y) {
      gameOver();
    }

    spawnT += dt;
    if (spawnT > 1.5 / difficulty.speedMultiplier) {
      spawnT = 0;
      final gapSize = 180.0 / difficulty.speedMultiplier;
      final gapCenter = 150 + Random().nextDouble() * (size.y - 300);
      pipes.add(Pipe(x: size.x, gapCenter: gapCenter, gapSize: gapSize));
    }

    for (int i = pipes.length - 1; i >= 0; i--) {
      pipes[i].x -= 200 * dt * difficulty.speedMultiplier;


      if (pipes[i].x < 100 && pipes[i].x > 20) {
        if (birdY < pipes[i].gapCenter - pipes[i].gapSize / 2 ||
            birdY > pipes[i].gapCenter + pipes[i].gapSize / 2) {
          gameOver();
        }
      }


      if (pipes[i].x < 50 && pipes[i].x > 50 - 5) {

      }

      if (pipes[i].x < -100) {
        pipes.removeAt(i);
        score++;
        scoreText.text = '$score';
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    birdVy = -450;
    shaker.shake(duration: 0.1, intensity: 3);
  }

  void gameOver() {
    if (isGameOver) return;
    SensoryService.heavyImpact();
    isGameOver = true;
    shaker.shake(duration: 0.5, intensity: 12);
    pauseEngine();
    overlays.add('GameOver');
  }
}

class _BirdRenderer extends Component with HasGameReference<FlappyBirdGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    for (int i = 0; i < 5; i++) {
      final cx = (i * 200.0 - g._time * 30.0 * (i + 1)) % (w + 200.0) - 100.0;
      final cy = 100.0 + i * 60.0;
      canvas.drawCircle(Offset(cx, cy), 30.0,
          _p..color = Colors.white.withValues(alpha: 0.2));
      canvas.drawCircle(Offset(cx + 25.0, cy + 10.0), 25.0,
          _p..color = Colors.white.withValues(alpha: 0.2));
    }


    final pipePaint = _p..color = const Color(0xFF73BF2E);
    final borderPaint = _p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF2E5310);
    final capPaint = _p..color = const Color(0xFF88D63B);

    for (final p in g.pipes) {
      final tRect = Rect.fromLTWH(p.x, 0, 70, p.gapCenter - p.gapSize / 2);
      final bRect = Rect.fromLTWH(p.x, p.gapCenter + p.gapSize / 2, 70,
          h - (p.gapCenter + p.gapSize / 2));

      canvas.drawRect(tRect, pipePaint);
      canvas.drawRect(tRect, borderPaint);
      canvas.drawRect(bRect, pipePaint);
      canvas.drawRect(bRect, borderPaint);


      canvas.drawRect(
          Rect.fromLTWH(p.x - 5, p.gapCenter - p.gapSize / 2 - 30, 80, 30),
          capPaint);
      canvas.drawRect(
          Rect.fromLTWH(p.x - 5, p.gapCenter - p.gapSize / 2 - 30, 80, 30),
          borderPaint);
      canvas.drawRect(
          Rect.fromLTWH(p.x - 5, p.gapCenter + p.gapSize / 2, 80, 30),
          capPaint);
      canvas.drawRect(
          Rect.fromLTWH(p.x - 5, p.gapCenter + p.gapSize / 2, 80, 30),
          borderPaint);
    }


    canvas.save();
    canvas.translate(65, g.birdY);
    canvas.rotate(g.birdAngle);
    _drawBird(canvas);
    canvas.restore();
  }

  void _drawBird(Canvas canvas) {
    final bodyPaint = Paint()..color = const Color(0xFFF7D10D);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 45, height: 35), bodyPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 45, height: 35),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 2);


    canvas.drawCircle(
        const Offset(10.0, -5.0), 6.0, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(10.0, -5.0),
        6.0,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 1.5);
    canvas.drawCircle(
        const Offset(12.0, -5.0), 2.5, Paint()..color = Colors.black);


    final beakPaint = Paint()..color = const Color(0xFFF06543);
    final beakPath = Path()
      ..moveTo(20, -2)
      ..lineTo(35, 2)
      ..lineTo(20, 6)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
    canvas.drawPath(
        beakPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 1.5);


    canvas.drawOval(const Rect.fromLTWH(-15, 0, 20, 12),
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawOval(
        const Rect.fromLTWH(-15, 0, 20, 12),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 1);
  }
}
