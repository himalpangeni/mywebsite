
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';

class VampireJobGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
  final GameDifficulty difficulty;
  late Vampire vampire;
  int coffeeCount = 0;
  int lives = 3;
  bool isGameOver = false;
  late TextComponent scoreText;
  late TextComponent statusText;
  late ScreenShake shaker;
  late Sprite logoSprite;

  double speedMultiplier = 1.0;
  double _progressionTimer = 0;
  double _spawnTimer = 0;

  VampireJobGame({required this.difficulty}) : super() {
    speedMultiplier = difficulty.speedMultiplier;
  }

  @override
  Color backgroundColor() => const Color(0xFF0F0510);

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

    coffeeCount = 0;
    lives = 3;
    isGameOver = false;
    _progressionTimer = 0;
    speedMultiplier = difficulty.speedMultiplier;


    for (int i = 0; i < 5; i++) {
      add(Desk(
          position: Vector2(Random().nextDouble() * (size.x - 120) + 60,
              Random().nextDouble() * (size.y - 120) + 60)));
    }

    vampire = Vampire();
    add(vampire);

    scoreText = TextComponent(
      text: 'COFFEE: 0  LIVES: $lives',
      position: Vector2(size.x / 2, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2)),
    );
    add(scoreText);


    add(TextComponent(
      text: 'VAMPIRE JOB',
      position: Vector2(size.x / 2, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.white.withValues(alpha: 0.05), fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 8)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 50, 50),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.25),
    ));

    statusText = TextComponent(
      text: 'STATUS: SAFE',
      position: Vector2(size.x / 2, size.y - 60),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5)),
    );
    add(statusText);

    add(Sunbeam());
    spawnCoffee();
    resumeEngine();
  }

  void resumeGame() {
    isGameOver = false;
    vampire.invulnerabilityTimer = 1.5;
    vampire.isAtDesk = true;
    for (var c in children.whereType<Sunbeam>().toList()) {
      c.removeFromParent();
    }
    overlays.remove('GameOver');
    resumeEngine();
  }

  void spawnCoffee() {
    add(Coffee(
        position: Vector2(Random().nextDouble() * (size.x - 60) + 30,
            Random().nextDouble() * (size.y - 60) + 30)));
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    _progressionTimer += dt;
    if (_progressionTimer >= 15.0) {
      _progressionTimer = 0;
      speedMultiplier += 0.15;
    }

    _spawnTimer += dt;
    if (_spawnTimer > 12 / speedMultiplier) {
      _spawnTimer = 0;
      add(Sunbeam());
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    vampire.moveTo(event.localPosition);
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    shaker.shake(duration: 0.6, intensity: 15);
    pauseEngine();
    overlays.add('GameOver');
  }

  void addScore() {
    coffeeCount++;
    scoreText.text = 'COFFEE: $coffeeCount  LIVES: $lives';
    shaker.shake(duration: 0.1, intensity: 4);
    spawnCoffee();
  }

  @override
  void render(Canvas canvas) {

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0xFF1B0821), Color(0xFF0F0510)])
              .createShader(rect));


    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;
    for (double i = 0; i < size.x; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.y), gridPaint);
    }
    for (double i = 0; i < size.y; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.x, i), gridPaint);
    }

    super.render(canvas);
  }
}

class Vampire extends PositionComponent
    with HasGameReference<VampireJobGame>, CollisionCallbacks {
  Vampire() : super(size: Vector2(50, 50), anchor: Anchor.center);
  double invulnerabilityTimer = 0;
  bool isAtDesk = false;
  bool inSunlight = false;
  Vector2? targetPos;

  @override
  Future<void> onLoad() async {
    position = game.size / 2;
    add(CircleHitbox(radius: 20, anchor: Anchor.center));
  }

  void moveTo(Vector2 pos) {
    targetPos = pos;
    isAtDesk = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;

    if (targetPos != null) {
      final dir = (targetPos! - position).normalized();
      position += dir * 280 * dt;


      game.add(ParticleSystemComponent(
          position: position.clone(),
          particle: CircleParticle(
              radius: 12,
              lifespan: 0.15,
              paint: Paint()..color = Colors.purple.withValues(alpha: 0.3))));

      if (position.distanceTo(targetPos!) < 5) {
        targetPos = null;
      }
    }

    if (invulnerabilityTimer > 0) invulnerabilityTimer -= dt;

    if (inSunlight && !isAtDesk && invulnerabilityTimer <= 0) {
      game.lives--;
      game.scoreText.text = 'COFFEE: ${game.coffeeCount}  LIVES: ${game.lives}';
      if (game.lives <= 0) {
         game.gameOver();
      } else {
         invulnerabilityTimer = 1.5;
         game.shaker.shake(duration: 0.3, intensity: 8);
         game.statusText.text = 'SCANNED! LIVES: ${game.lives}';
         game.statusText.textRenderer = TextPaint(
             style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold));
      }
    } else if (invulnerabilityTimer <= 0) {
      game.statusText.text = isAtDesk ? 'STATUS: SAFE (DESK)' : 'STATUS: CLEAR';
      game.statusText.textRenderer = TextPaint(
          style: TextStyle(
              color: isAtDesk ? Colors.cyanAccent : Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold));
    }

    inSunlight = false;
  }

  @override
  void render(Canvas canvas) {
    if (invulnerabilityTimer > 0 && (invulnerabilityTimer * 10).toInt() % 2 == 0) return;
    canvas.save();

    final capePaint = Paint()..color = const Color(0xFF121212);
    canvas.drawPath(
        Path()
          ..moveTo(-20, -10)
          ..lineTo(0, 35)
          ..lineTo(20, -10)
          ..close(),
        capePaint);


    final bodyPaint = Paint()
      ..shader =
          const RadialGradient(colors: [Colors.purpleAccent, Color(0xFF4A148C)])
              .createShader(Rect.fromCircle(center: Offset.zero, radius: 20));
    canvas.drawCircle(Offset.zero, 18, bodyPaint);


    canvas.drawCircle(
        const Offset(-6, -4), 3, Paint()..color = Colors.redAccent);
    canvas.drawCircle(
        const Offset(6, -4), 3, Paint()..color = Colors.redAccent);

    if (invulnerabilityTimer > 0) {

      canvas.drawCircle(
          Offset.zero,
          25,
          Paint()
            ..color = Colors.white24
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    canvas.restore();
  }
}

class Desk extends PositionComponent
    with HasGameReference<VampireJobGame>, CollisionCallbacks {
  Desk({required Vector2 position})
      : super(position: position, size: Vector2(90, 60), anchor: Anchor.center);
  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {

    canvas.drawRRect(
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
        Paint()..color = const Color(0xFF3E2723));

    final monitorRect = Rect.fromLTWH(size.x / 2 - 20, 5, 40, 25);
    canvas.drawRect(monitorRect, Paint()..color = Colors.black);
    canvas.drawRect(monitorRect.deflate(2),
        Paint()..color = Colors.cyanAccent.withValues(alpha: 0.4));

    canvas.drawRect(Rect.fromLTWH(size.x / 2 - 20, 35, 40, 10),
        Paint()..color = Colors.grey[800]!);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Vampire) other.isAtDesk = true;
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Vampire) other.isAtDesk = false;
    super.onCollisionEnd(other);
  }
}

class Sunbeam extends PositionComponent
    with HasGameReference<VampireJobGame>, CollisionCallbacks {
  Sunbeam() : super(size: Vector2(120, 2500), anchor: Anchor.center);
  double speed = 120 + Random().nextDouble() * 100;

  @override
  Future<void> onLoad() async {
    position = Vector2(-300, game.size.y / 2);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;
    position.x += speed * dt * game.speedMultiplier;
    if (position.x > game.size.x + 400) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final beamPaint = Paint()
      ..shader = LinearGradient(colors: [
        Colors.yellow.withValues(alpha: 0),
        Colors.yellow.withValues(alpha: 0.3),
        Colors.yellow.withValues(alpha: 0)
      ]).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawRect(rect, beamPaint);


    canvas.drawRect(Rect.fromLTWH(size.x / 2 - 5, 0, 10, size.y),
        Paint()..color = Colors.white.withValues(alpha: 0.15));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Vampire) other.inSunlight = true;
    super.onCollision(intersectionPoints, other);
  }
}

class Coffee extends PositionComponent
    with HasGameReference<VampireJobGame>, CollisionCallbacks {
  Coffee({required Vector2 position})
      : super(position: position, size: Vector2(40, 40), anchor: Anchor.center);
  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: 20, anchor: Anchor.center));
  }

  @override
  void render(Canvas canvas) {

    final time = DateTime.now().millisecondsSinceEpoch / 400;
    for (int i = 0; i < 3; i++) {
      final offset = sin(time + i) * 5;
      canvas.drawCircle(
          Offset(offset, -20 - i * 8), 4, Paint()..color = Colors.white12);
    }

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-15, -10, 30, 25), const Radius.circular(5)),
        Paint()..color = Colors.white);

    canvas.drawRect(const Rect.fromLTWH(-10, -8, 20, 5),
        Paint()..color = const Color(0xFF4E342E));

    canvas.drawCircle(
        const Offset(15, 0),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Vampire) {
      game.addScore();
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
