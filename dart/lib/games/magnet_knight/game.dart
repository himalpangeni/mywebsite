
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../services/sensory.dart';

enum Polarity { north, south }

class MagnetKnightGame extends FlameGame with TapCallbacks, HasCollisionDetection {



  late Knight knight;
  int score = 0;
  bool isGameOver = false;
  late TextComponent scoreText;
  
  final GameDifficulty difficulty;
  double speedMultiplier = 1.0;
  double _progressionTimer = 0;
  double _obstacleTimer = 0;

  MagnetKnightGame({required this.difficulty}) : super() {
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
    isGameOver = false;
    _progressionTimer = 0;
    speedMultiplier = difficulty.speedMultiplier;

    add(PolarizedSurface(isCeiling: true, color: Colors.redAccent, polarity: Polarity.north));
    add(PolarizedSurface(isCeiling: false, color: Colors.blueAccent, polarity: Polarity.south));

    knight = Knight();
    add(knight);

    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 50),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 24)),
    );
    add(scoreText);

    resumeEngine();
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    _progressionTimer += dt;
    if (_progressionTimer >= 15.0) {
      _progressionTimer = 0;
      _increaseSpeed();
    }

    _obstacleTimer += dt;
    double spawnInterval = (3.0 / speedMultiplier).clamp(0.8, 4.0);
    if (_obstacleTimer >= spawnInterval) {
      _obstacleTimer = 0;
      add(MagnetObstacle());
    }
    
    score += (dt * 10).toInt();
    scoreText.text = 'Score: $score';
  }

  void _increaseSpeed() {
    speedMultiplier += 0.2;
    final prompt = TextComponent(
      text: 'POLARITY SHIFT!',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.yellowAccent, fontSize: 32, fontWeight: FontWeight.bold)),
    );
    add(prompt);
    Future.delayed(const Duration(seconds: 1), () => prompt.removeFromParent());
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    knight.togglePolarity();
  }

  void resumeGame() {
    isGameOver = false;
    knight.position = size / 2;
    knight.velocityY = 0;
    _obstacleTimer = 0;
    overlays.remove('GameOver');
    resumeEngine();
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }
}

class Knight extends PositionComponent with HasGameReference<MagnetKnightGame>, CollisionCallbacks {


  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  Knight() : super(size: Vector2(40, 60), anchor: Anchor.center);
  Polarity polarity = Polarity.north;
  double velocityY = 0;
  final double jumpForce = 400;
  
  @override
  Future<void> onLoad() async {


    position = game.size / 2;
    add(RectangleHitbox());
  }

  void togglePolarity() {
    polarity = (polarity == Polarity.north) ? Polarity.south : Polarity.north;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;




    if (polarity == Polarity.north) {
      velocityY += 1000 * dt;
    } else {
      velocityY -= 1000 * dt;
    }

    position.y += velocityY * dt;


    if (position.y > game.size.y - 50) {
      position.y = game.size.y - 50;
      velocityY = 0;
    }
    if (position.y < 50) {
      position.y = 50;
      velocityY = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = _p..color = (polarity == Polarity.north) ? Colors.redAccent : Colors.blueAccent;
    canvas.drawRect(size.toRect(), paint);

    final glow = _p..color = paint.color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(size.toRect(), glow);
  }
}

class PolarizedSurface extends PositionComponent with HasGameReference<MagnetKnightGame> {


  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  final bool isCeiling;
  final Color color;
  final Polarity polarity;

  PolarizedSurface({required this.isCeiling, required this.color, required this.polarity}) : super();

  @override
  Future<void> onLoad() async {


    size = Vector2(game.size.x, 30);
    position = isCeiling ? Vector2(0, 0) : Vector2(0, game.size.y - 30);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _p..color = color);

    final textPaint = TextPaint(style: const TextStyle(color: Colors.white24, fontSize: 12));
    for (double i = 0; i < size.x; i += 50) {
      textPaint.render(canvas, polarity == Polarity.north ? 'N' : 'S', Vector2(i + 20, 10));
    }
  }
}

class MagnetObstacle extends PositionComponent with HasGameReference<MagnetKnightGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();

  MagnetObstacle() : super(size: Vector2(30, 100), anchor: Anchor.center);
  @override
  Future<void> onLoad() async {

    position = Vector2(game.size.x + 50, Random().nextDouble() * (game.size.y - 200) + 100);
    add(RectangleHitbox());
  }
  @override
  void update(double dt) {
    super.update(dt);
    position.x -= 250 * dt * game.speedMultiplier;
    if (position.x < -50) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _p..color = Colors.grey);
  }
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Knight) game.gameOver();
    super.onCollisionStart(intersectionPoints, other);
  }
}
