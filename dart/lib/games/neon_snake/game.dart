
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import 'package:flame/particles.dart';
import '../../models/difficulty.dart';
import '../../services/sensory.dart';


class HudText extends TextComponent {
  HudText({
    required super.text,
    required super.position,
    required super.anchor,
    required super.textRenderer,
  });

  @override
  bool containsPoint(Vector2 point) => false;
}

class NeonSnakeGame extends FlameGame with PanDetector, TapCallbacks {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;

  static const double gridSize = 20.0;
  late Snake snake;
  late Food food;
  double _moveTimer = 0;
  double _progressionTimer = 0;

  final GameDifficulty difficulty;
  double speedMultiplier = 1.0;
  double _targetSpeed = 1.0;

  Vector2 direction = Vector2(1, 0);
  Vector2 nextDirection = Vector2(1, 0);
  bool isGameOver = false;
  int score = 0;
  late HudText scoreText;

  NeonSnakeGame({required this.difficulty}) : super() {
    speedMultiplier = difficulty.speedMultiplier;
  }

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


    speedMultiplier = difficulty.speedMultiplier;
    _progressionTimer = 0;
    _moveTimer = 0;
    direction = Vector2(1, 0);
    nextDirection = Vector2(1, 0);

    snake = Snake();
    add(snake);
    spawnFood();

    score = 0;
    scoreText = HudText(
      text: 'Score: 0',
      position: Vector2(20, 20),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.green, blurRadius: 10)],
        ),
      ),
    );
    add(scoreText);

    isGameOver = false;
    overlays.remove('GameOver');
    resumeEngine();
  }

  void resumeGame() {
    isGameOver = false;

    _targetSpeed = (speedMultiplier * 0.8).clamp(1.0, 4.0);
    speedMultiplier = _targetSpeed;
    _moveTimer = 0;
    overlays.remove('GameOver');
    resumeEngine();
  }


  void trySetDirection(Vector2 dir) {
    if (isGameOver) return;
    final nx = dir.x.sign.toDouble();
    final ny = dir.y.sign.toDouble();
    if (nx != 0 && ny != 0) {

      if (nx.abs() >= ny.abs()) {
        if (direction.x == -nx) return;
        nextDirection = Vector2(nx, 0);
      } else {
        if (direction.y == -ny) return;
        nextDirection = Vector2(0, ny);
      }
      return;
    }
    if (nx != 0) {
      if (direction.x == -nx) return;
      nextDirection = Vector2(nx, 0);
    } else if (ny != 0) {
      if (direction.y == -ny) return;
      nextDirection = Vector2(0, ny);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    final lp = event.localPosition;
    final cx = size.x / 2;
    final cy = size.y / 2;
    final dx = lp.x - cx;
    final dy = lp.y - cy;
    if (dx.abs() < 8 && dy.abs() < 8) return;
    if (dx.abs() > dy.abs()) {
      trySetDirection(Vector2(dx.sign, 0));
    } else {
      trySetDirection(Vector2(0, dy.sign));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final gridPaint = _p
      ..color = Colors.white10
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.x; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y < size.y; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }

  void spawnFood() {
    final cols = (size.x / gridSize).floor();
    final rows = (size.y / gridSize).floor();
    if (cols <= 0 || rows <= 0) return;

    final snakeCells = snake.segments.map((p) => '${p.x.toInt()},${p.y.toInt()}').toSet();
    final freeCells = <Vector2>[];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (!snakeCells.contains('$x,$y')) {
          freeCells.add(Vector2(x.toDouble(), y.toDouble()));
        }
      }
    }
    if (freeCells.isEmpty) {
      gameOver();
      return;
    }

    final cell = freeCells[Random().nextInt(freeCells.length)];
    final px = cell.x * gridSize + gridSize / 2;
    final py = cell.y * gridSize + gridSize / 2;
    food = Food(position: Vector2(px, py));
    add(food);
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    if (_progressionTimer >= 15.0 || score > (_targetSpeed - difficulty.speedMultiplier) * 50 + 10) {
      _progressionTimer = 0;
      _increaseSpeed();
    }


    if (speedMultiplier < _targetSpeed) {
        speedMultiplier = (speedMultiplier + 0.5 * dt).clamp(1.0, _targetSpeed);
    }

    _moveTimer += dt;
    double moveInterval = (0.15 / speedMultiplier).clamp(0.05, 0.2);
    if (_moveTimer >= moveInterval) {
      _moveTimer = 0;
      direction = nextDirection;
      snake.move(direction);
    }
  }

  void _increaseSpeed() {
    if (_targetSpeed > 4.0) return;
    _targetSpeed += 0.2;
    final prompt = TextComponent(
      text: 'SPEED UP!',
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.green, blurRadius: 20)],
        ),
      ),
    );
    add(prompt);
    Future.delayed(const Duration(seconds: 1), () => prompt.removeFromParent());
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver) return;
    final d = info.delta.global;
    if (d.length2 < 4) return;
    if (d.x.abs() > d.y.abs()) {
      trySetDirection(Vector2(d.x.sign, 0));
    } else {
      trySetDirection(Vector2(0, d.y.sign));
    }
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }
}

class Snake extends PositionComponent with HasGameReference<NeonSnakeGame> {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  final List<Vector2> segments = [Vector2(5, 5), Vector2(4, 5), Vector2(3, 5)];

  @override
  bool containsPoint(Vector2 point) => false;

  void move(Vector2 dir) {
    final head = segments.first + dir;
    segments.insert(0, head);

    final foodCell =
        (game.food.position - Vector2.all(NeonSnakeGame.gridSize / 2)) /
            NeonSnakeGame.gridSize;
    if (head.distanceTo(foodCell) < 0.1) {
      game.score++;
      game.scoreText.text = 'Score: ${game.score}';
      game.food.removeFromParent();
      game.spawnFood();
      SensoryService.heavyImpact();
      game.add(ParticleSystemComponent(
        particle: Particle.generate(
          count: 8,
          lifespan: 0.4,
          generator: (i) => CircleParticle(
            radius: 24,
            paint: Paint()..color = Colors.redAccent.withValues(alpha: 0.25),
          ),
        ),
        position: head * NeonSnakeGame.gridSize,
      ));
    } else {
      segments.removeLast();
      SensoryService.lightImpact();
    }

    if (head.x < 0 ||
        head.y < 0 ||
        head.x >= game.size.x / NeonSnakeGame.gridSize ||
        head.y >= game.size.y / NeonSnakeGame.gridSize) {
      game.gameOver();
    }

    for (int i = 1; i < segments.length; i++) {
      if (head.distanceTo(segments[i]) < 0.1) {
        game.gameOver();
      }
    }
  }

  @override
  void render(Canvas canvas) {


    for (int i = 0; i < segments.length; i++) {
      final paint = _p
        ..color = i == 0 ? Colors.greenAccent : Colors.greenAccent.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      final rect = Rect.fromLTWH(
        segments[i].x * NeonSnakeGame.gridSize + 2,
        segments[i].y * NeonSnakeGame.gridSize + 2,
        NeonSnakeGame.gridSize - 4,
        NeonSnakeGame.gridSize - 4,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        _p
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }


}

class Food extends PositionComponent {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  Food({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(NeonSnakeGame.gridSize),
          anchor: Anchor.center,
        );

  @override
  bool containsPoint(Vector2 point) => false;

  @override
  void render(Canvas canvas) {
    final paint = _p
      ..color = Colors.redAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 3, paint);
    canvas.drawCircle(
        Offset(size.x / 2, size.y / 2), size.x / 5, _p..color = Colors.white);
  }
}
