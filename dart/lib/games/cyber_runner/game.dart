
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';

class CyberRunnerGame extends FlameGame with PanDetector, HasCollisionDetection {

  final GameDifficulty difficulty;
  late CyberHumanRunner player;
  double _spawnTimer = 0;
  int score = 0;
  double _scoreAccumulator = 0;
  bool isGameOver = false;
  late TextComponent scoreText;
  double speedMultiplier = 1.0;
  late ScreenShake shaker;
  late Sprite logoSprite;

  CyberRunnerGame({required this.difficulty}) : super();

  @override
  Color backgroundColor() => const Color(0xFF020208);

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

    score = 0;
    _scoreAccumulator = 0;
    isGameOver = false;
    speedMultiplier = difficulty.speedMultiplier;

    shaker = ScreenShake();
    add(shaker);

    player = CyberHumanRunner();
    add(player);

    add(CinematicOverlay());
    add(_CyberGrid());

    add(TextComponent(
      text: 'SWIPE LEFT/RIGHT • STAY CENTERED',
      position: Vector2(size.x / 2, size.y - 120),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2)),
    ));

    scoreText = TextComponent(
      text: '0',
      position: Vector2(size.x / 2, 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.pinkAccent, blurRadius: 20)],
        ),
      ),
    );
    add(scoreText);


    add(TextComponent(
      text: 'CYBER RUNNER',
      position: Vector2(size.x / 2, size.y * 0.45),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.white.withValues(alpha: 0.05), fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: 8)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 50, 50),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.25),
    ));

    resumeEngine();
  }

  void resumeGame() {
    isGameOver = false;
    for (var c in children.whereType<CyberObstacle>().toList()) {
      c.removeFromParent();
    }
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    _scoreAccumulator += dt * 20 * speedMultiplier;
    score = _scoreAccumulator.floor();
    scoreText.text = '$score';
    speedMultiplier += dt * 0.05;


    if (Random().nextDouble() < 0.2) {
       add(ParticleSystemComponent(
           particle: Particle.generate(count: 2, lifespan: 0.6, generator: (i) => CircleParticle(radius: 2, paint: Paint()..color = Colors.cyanAccent)),
           position: player.position + Vector2(0, 40),
       ));
    }

    _spawnTimer += dt;
    if (_spawnTimer > (1.2 / speedMultiplier).clamp(0.4, 1.2)) {
      _spawnTimer = 0;
      add(CyberObstacle());
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver) return;
    player.targetX = (player.targetX + info.delta.global.x).clamp(50.0, size.x - 50.0);
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    shaker.shake(duration: 0.6, intensity: 15);
    pauseEngine();
    overlays.add('GameOver');
  }
}

class CyberHumanRunner extends PositionComponent with HasGameReference<CyberRunnerGame>, CollisionCallbacks {


  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  double targetX = 0;
  final List<Vector2> _trail = [];

  CyberHumanRunner() : super(size: Vector2(60, 100), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {


    position = Vector2(game.size.x / 2, game.size.y - 150);
    targetX = position.x;
    add(RectangleHitbox(size: Vector2(30, 80), anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = lerpDouble(position.x, targetX, 0.2)!;
    
    _trail.add(position.clone());
    if (_trail.length > 10) _trail.removeAt(0);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final t = DateTime.now().millisecondsSinceEpoch / 200;


    for (int i = 0; i < _trail.length; i++) {
        final op = (i / _trail.length) * 0.2;
        canvas.drawCircle(Offset(_trail[i].x - position.x + w/2, _trail[i].y - position.y + h/2), 15, _p..color = Colors.cyanAccent.withValues(alpha: op));
    }


    final bodyPaint = _p..color = Colors.cyanAccent..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
    final rimPaint = _p..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
    

    canvas.drawCircle(Offset(w / 2, 10 + sin(t) * 2), 10, bodyPaint);
    canvas.drawCircle(Offset(w / 2, 10 + sin(t) * 2), 10, rimPaint);
    

    final torsoPath = Path()
        ..moveTo(w * 0.35, 25)
        ..lineTo(w * 0.65, 25)
        ..lineTo(w * 0.7, 60)
        ..lineTo(w * 0.3, 60)
        ..close();
    canvas.drawPath(torsoPath, bodyPaint);
    canvas.drawPath(torsoPath, rimPaint);
    

    final legL = sin(t * 2) * 15;
    final legR = cos(t * 2) * 15;
    
    canvas.drawLine(Offset(w * 0.4, 60), Offset(w * 0.3 + legL, 95), rimPaint);
    canvas.drawLine(Offset(w * 0.6, 60), Offset(w * 0.7 + legR, 95), rimPaint);
    

    canvas.drawLine(Offset(w * 0.35, 35), Offset(10, 50 + sin(t) * 10), rimPaint);
    canvas.drawLine(Offset(w * 0.65, 35), Offset(w - 10, 50 + cos(t) * 10), rimPaint);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is CyberObstacle) {
      game.gameOver();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class CyberObstacle extends PositionComponent with HasGameReference<CyberRunnerGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  late final Random _random;
  CyberObstacle() : super(size: Vector2(60, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _random = Random();
    final lane = Random().nextInt(3);
    position = Vector2((lane + 0.5) * (game.size.x / 3), -50);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 500 * dt * game.speedMultiplier;
    if (position.y > game.size.y + 100) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRect(rect, _p..color = Colors.pinkAccent..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12));
    canvas.drawRect(rect, _p..color = Colors.pinkAccent);

    if (_random.nextDouble() < 0.1) {
        canvas.drawRect(Rect.fromLTWH(-10, 5, size.x + 20, 2), _p..color = Colors.white);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is CyberHumanRunner) {
      game.gameOver();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class _CyberGrid extends Component with HasGameReference<CyberRunnerGame> {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    final paint = _p
      ..color = Colors.pinkAccent.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    double offset = (g.score * 5) % 100.0;
    for (double y = offset; y < h; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
    for (double x = 0; x <= w; x += w / 3) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
    }
  }
}
