
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flame/particles.dart';
import '../../models/difficulty.dart';
import '../../services/sensory.dart';

enum GravityDir { down, left, up, right }

class GravityBallGame extends FlameGame with TapCallbacks, HasCollisionDetection {


  late Ball ball;
  late Goal goal;
  int level = 1;
  bool isGameOver = false;
  late TextComponent levelText;
  late TextComponent gravityText;
  late Sprite logoSprite;
  
  final GameDifficulty difficulty;
  double speedMultiplier = 1.0;
  double _progressionTimer = 0;
  GravityDir gravityDir = GravityDir.down;

  GravityBallGame({required this.difficulty}) : super() {
    speedMultiplier = difficulty.speedMultiplier;
  }

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

    level = 1;
    isGameOver = false;
    _progressionTimer = 0;
    speedMultiplier = difficulty.speedMultiplier;
    gravityDir = GravityDir.down;

    ball = Ball();
    add(ball);
    ball.position = size / 2;
    ball.velocity = Vector2.zero();

    _generateLevel();

    levelText = TextComponent(
      text: 'Level: 1',
      position: Vector2(20, 50),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.purpleAccent, fontSize: 24, fontWeight: FontWeight.bold)),
    );
    add(levelText);

    gravityText = TextComponent(
      text: 'Gravity: DOWN',
      position: Vector2(20, 80),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
    );
    add(gravityText);

    add(TextComponent(
      text: 'Tap to rotate gravity and guide the ball to the goal.',
      position: Vector2(size.x / 2, size.y - 60),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white70, fontSize: 16)),
    ));


    add(TextComponent(
      text: 'GRAVITY BALL',
      position: Vector2(size.x / 2, size.y * 0.45),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.05), fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: 8)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 50, 50),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.cyanAccent.withValues(alpha: 0.25),
    ));

    resumeEngine();
  }

  void resumeGame() {
    isGameOver = false;
    ball.position = size / 2;
    ball.velocity = Vector2.zero();

    overlays.remove('GameOver');
    resumeEngine();
  }

  void _generateLevel() {

    for (final child in children.toList()) {
        if (child is Wall || child is Spike || child is Goal) child.removeFromParent();
    }

    final random = Random();
    final startPos = size / 2;
    ball.position = startPos;
    ball.velocity = Vector2.zero();


    add(Wall(position: Vector2(size.x / 2, 10), size: Vector2(size.x, 20)));
    add(Wall(position: Vector2(size.x / 2, size.y - 10), size: Vector2(size.x, 20)));
    add(Wall(position: Vector2(10, size.y / 2), size: Vector2(20, size.y)));
    add(Wall(position: Vector2(size.x - 10, size.y / 2), size: Vector2(20, size.y)));


    int wallCount = (8 + level * 2).clamp(10, 25);
    for (int i = 0; i < wallCount; i++) {
        Vector2 position;
        do {
          position = Vector2(random.nextDouble() * (size.x - 140) + 70, random.nextDouble() * (size.y - 240) + 120);
        } while (position.distanceTo(startPos) < 180);
        add(Wall(position: position, size: Vector2(80, 20)));
    }


    if (difficulty != GameDifficulty.easy) {
        for (int i = 0; i < level; i++) {
            Vector2 pos;
            do {
              pos = Vector2(random.nextDouble() * (size.x - 120) + 60, random.nextDouble() * (size.y - 120) + 60);
            } while (pos.distanceTo(startPos) < 160);
            add(Spike(position: pos));
        }
    }

    goal = Goal();
    do {
      goal.position = Vector2(random.nextDouble() * (size.x - 100) + 50, random.nextDouble() * (size.y - 100) + 50);
    } while (goal.position.distanceTo(startPos) < 220);
    add(goal);
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    _progressionTimer += dt;
    if (_progressionTimer >= 15.0) {
      _progressionTimer = 0;
      speedMultiplier += 0.2;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;

    int next = (gravityDir.index + 1) % (difficulty == GameDifficulty.easy ? 2 : 4);
    gravityDir = GravityDir.values[next];
    gravityText.text = 'Gravity: ${gravityDir.name.toUpperCase()}';
  }

  void nextLevel() {
      level++;
      levelText.text = 'Level: $level';
      _generateLevel();
      ball.position = size / 2;
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }
}

class Ball extends PositionComponent with HasGameReference<GravityBallGame>, CollisionCallbacks {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  Ball() : super(size: Vector2(30, 30), anchor: Anchor.center);
  Vector2 velocity = Vector2.zero();

  @override
  Future<void> onLoad() async {
    position = game.size / 2;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;

    Vector2 gravity = Vector2.zero();
    switch (game.gravityDir) {
      case GravityDir.down: gravity = Vector2(0, 1000); break;
      case GravityDir.left: gravity = Vector2(-1000, 0); break;
      case GravityDir.up: gravity = Vector2(0, -1000); break;
      case GravityDir.right: gravity = Vector2(1000, 0); break;
    }

    velocity += gravity * dt * game.speedMultiplier;
    position += velocity * dt;
    velocity *= 0.98;


    const margin = 35.0;
    if (position.x < margin) {
      position.x = margin;
      if (velocity.x < 0) velocity.x = -velocity.x * 0.4;
    } else if (position.x > game.size.x - margin) {
      position.x = game.size.x - margin;
      if (velocity.x > 0) velocity.x = -velocity.x * 0.4;
    }

    if (position.y < margin) {
      position.y = margin;
      if (velocity.y < 0) velocity.y = -velocity.y * 0.4;
    } else if (position.y > game.size.y - margin) {
      position.y = game.size.y - margin;
      if (velocity.y > 0) velocity.y = -velocity.y * 0.4;
    }


    if (position.x < -100 || position.x > game.size.x + 100 || position.y < -100 || position.y > game.size.y + 100) {
      position = game.size / 2;
      velocity = Vector2.zero();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 15, _p..color = Colors.redAccent);
    canvas.drawCircle(Offset.zero, 10, _p..color = Colors.white.withValues(alpha: 0.3));
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Wall) {
      if (velocity.length > 50) {
        game.add(ParticleSystemComponent(
          position: position.clone(),
          particle: Particle.generate(
              count: 8,
              lifespan: 0.5,
              generator: (i) => CircleParticle(
                  radius: 2, paint: Paint()..color = Colors.white)),
        ));
        SensoryService.lightImpact();
      }

      final delta = position - other.position;
      if (delta.x.abs() > delta.y.abs()) {
        velocity.x = -velocity.x * 0.5;
        position.x += delta.x.sign * 5;
      } else {
        velocity.y = -velocity.y * 0.5;
        position.y += delta.y.sign * 5;
      }
    } else if (other is Spike) {
        game.add(ParticleSystemComponent(
            position: position,
            particle: Particle.generate(count: 20, lifespan: 0.8, generator: (i) => CircleParticle(radius: 3, paint: Paint()..color = Colors.redAccent)),
        ));
        game.gameOver();
    } else if (other is Goal) {
        game.add(ParticleSystemComponent(
            position: position,
            particle: Particle.generate(count: 30, lifespan: 1.0, generator: (i) => CircleParticle(radius: 4, paint: Paint()..color = Colors.greenAccent)),
        ));
        game.nextLevel();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class Wall extends PositionComponent with HasGameReference<GravityBallGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  Wall({required Vector2 position, required Vector2 size}) : super(position: position, size: size, anchor: Anchor.center);
  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _p..color = Colors.blueGrey);
    canvas.drawRect(size.toRect().deflate(2), _p..color = Colors.black45);
  }
}

class Spike extends PositionComponent with HasGameReference<GravityBallGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  Spike({required Vector2 position}) : super(position: position, size: Vector2(30, 30), anchor: Anchor.center);
  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 15, _p..color = Colors.pinkAccent);
    canvas.drawCircle(Offset.zero, 5, _p..color = Colors.white);
  }
}

class Goal extends PositionComponent with HasGameReference<GravityBallGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  Goal() : super(size: Vector2(40, 40), anchor: Anchor.center);
  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }
  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _p..color = Colors.greenAccent);
    canvas.drawRect(size.toRect().deflate(5), _p..color = Colors.white..style = PaintingStyle.stroke);
  }
}
