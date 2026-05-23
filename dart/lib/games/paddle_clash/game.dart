
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../services/sensory.dart';

class PaddleClashGame extends FlameGame with PanDetector, HasCollisionDetection {



  late Paddle paddle;
  late Ball ball;
  int score = 0;
  bool _isGameOver = false;
  late TextComponent scoreText;
  
  final GameDifficulty difficulty;
  double speedMultiplier = 1.0;
  double _progressionTimer = 0;

  PaddleClashGame({required this.difficulty}) : super() {
    speedMultiplier = difficulty.speedMultiplier;
  }

  @override
  Future<void> onLoad() async {

    restart();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    score = 0;
    _isGameOver = false;
    _progressionTimer = 0;
    speedMultiplier = difficulty.speedMultiplier;

    paddle = Paddle();
    add(paddle);

    ball = Ball();
    add(ball);

    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.blue, blurRadius: 10)],
        ),
      ),
    );
    add(scoreText);

    resumeEngine();
  }

  @override
  void update(double dt) {
    if (_isGameOver) return;
    super.update(dt);

    _progressionTimer += dt;
    if (_progressionTimer >= 15.0) {
      _progressionTimer = 0;
      _increaseSpeed();
    }
  }

  void _increaseSpeed() {
    speedMultiplier += 0.2;
    final prompt = TextComponent(
      text: 'SPEED UP!',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.blue, blurRadius: 20)],
        ),
      ),
    );
    add(prompt);
    Future.delayed(const Duration(seconds: 1), () => prompt.removeFromParent());
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_isGameOver) return;
    paddle.position.x += info.delta.global.x;
    paddle.position.x = paddle.position.x.clamp(paddle.width / 2, size.x - paddle.width / 2);
  }

  void resumeGame() {
    _isGameOver = false;
    ball.position = size / 2;
    ball.velocity = Vector2(250, -250);
    overlays.remove('GameOver');
    resumeEngine();
  }

  void gameOver() {
    SensoryService.heavyImpact();
    _isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void incrementScore() {
    score++;
    scoreText.text = 'Score: $score';
  }
}

class Paddle extends PositionComponent with HasGameReference<PaddleClashGame>, CollisionCallbacks {


  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  Paddle() : super(size: Vector2(100, 20), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {


    position = Vector2(game.size.x / 2, game.size.y - 50);
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    

    canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(4, 4)), const Radius.circular(8)), _p..color = Colors.black45..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));


    final paint = _p
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blueAccent, Colors.blueAccent.darken(0.4)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);


    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(6)),
        _p
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), _p..color = Colors.blueAccent.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10));
  }
}

class Ball extends PositionComponent with HasGameReference<PaddleClashGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();

  final double radius = 10;
  Ball() : super(size: Vector2.all(20), anchor: Anchor.center);

  Vector2 velocity = Vector2(250, -250);

  @override
  Future<void> onLoad() async {

    position = game.size / 2;
    add(CircleHitbox(radius: radius));
  }
  
  @override
  void render(Canvas canvas) {
      final center = Offset(size.x / 2, size.y / 2);

      canvas.drawCircle(center, radius + 5, _p..color = Colors.blueAccent.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

      canvas.drawCircle(center, radius, _p..color = Colors.white);

      canvas.drawCircle(center - const Offset(3, 3), 3, _p..color = Colors.white70);
  }


  @override
  void update(double dt) {
    super.update(dt);
    if (game._isGameOver) return;

    position += velocity * dt * game.speedMultiplier;

    if (position.x < radius || position.x > game.size.x - radius) {
      velocity.x *= -1;
    }
    if (position.y < radius) {
      velocity.y *= -1;
    }

    if (position.y > game.size.y) {
      game.gameOver();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Paddle) {
      velocity.y *= -1;
      velocity.x += (Random().nextDouble() - 0.5) * 100;
      game.incrementScore();
    }
  }
}
