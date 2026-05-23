
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';

class AngryWeaponGame extends FlameGame with PanDetector, HasCollisionDetection {
  final GameDifficulty difficulty;
  final Random _random;
  int score = 0;
  int missCount = 0;
  bool isGameOver = false;
  
  late ScreenShake shaker;
  late Slingshot slingshot;
  double _enemySpawnTimer = 0;
  double _time = 0;
  late Sprite logoSprite;

  AngryWeaponGame({required this.difficulty}) : _random = Random();

  @override
  Color backgroundColor() => const Color(0xFF0F0C29);

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

    score = 0;
    missCount = 0;
    isGameOver = false;
    _time = 0;

    add(CinematicOverlay());
    add(_Starfield());
    
    slingshot = Slingshot();
    slingshot.reset();
    add(slingshot);


    add(TextComponent(
      text: 'ANGRY WEAPON',
      position: Vector2(size.x / 2, size.y * 0.4),
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

    add(TextComponent(
      text: 'DRAG & RELEASE TO BLAST',
      position: Vector2(size.x / 2, size.y - 60),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3, shadows: [Shadow(color: Colors.cyan, blurRadius: 10)])),
    ));

    resumeEngine();
  }

  void resumeGame() {
    isGameOver = false;
    for (var c in children.whereType<_EnemyMalice>().toList()) {
      c.removeFromParent();
    }
    slingshot.reset();
    overlays.remove('GameOver');
    resumeEngine();
  }



  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);
    _time += dt;

    _enemySpawnTimer += dt;

    double interval = (3.5 / difficulty.speedMultiplier).clamp(2.0, 5.0);
    if (_enemySpawnTimer >= interval) {
      _enemySpawnTimer = 0;
      _spawnWave();
    }
  }

  void _spawnWave() {
    int count = (difficulty == GameDifficulty.hard) ? 3 + _random.nextInt(3) : 2;
    

    int pattern = _random.nextInt(3);
    for (int i = 0; i < count; i++) {
      double offset = (i - (count - 1) / 2) * 60.0;
      Vector2 pos;
      if (pattern == 0) {
           pos = Vector2(size.x / 2 + offset, -50 - (i.abs() * 20.0));
      } else if (pattern == 1) {
           pos = Vector2(size.x + 50, 100 + i * 80.0);
      } else {
           pos = Vector2(_random.nextDouble() * size.x, -50);
      }
      add(_EnemyMalice(_random, pos));
    }
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    shaker.shake(duration: 0.6, intensity: 15);
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (isGameOver) return;
    slingshot.startDrag(info.eventPosition.global);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver) return;
    slingshot.updateDrag(info.eventPosition.global);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (isGameOver) return;
    slingshot.endDrag();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );

    textPaint.render(canvas, 'SCORE: $score', Vector2(20, 20));
    textPaint.render(
      canvas,
      'MISSES: $missCount/5',
      Vector2(20, 50),
      anchor: Anchor.topLeft,
    );
  }
}

class Slingshot extends Component with HasGameReference<AngryWeaponGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  Vector2? _dragStart;
  Vector2? _dragCurrent;
  bool _isDragging = false;

  void reset() {
    _isDragging = false;
    _dragStart = null;
    _dragCurrent = null;
  }

  void startDrag(Vector2 pos) {
    if (pos.y > game.size.y - 150) return;
    _dragStart = pos;
    _dragCurrent = pos;
    _isDragging = true;
  }

  void updateDrag(Vector2 pos) {
    if (!_isDragging) return;
    _dragCurrent = pos;
  }

  void endDrag() {
    if (!_isDragging || _dragStart == null || _dragCurrent == null) return;
    
    final diff = _dragStart! - _dragCurrent!;
    if (diff.length > 20) {
      final power = diff.length.clamp(0.0, 200.0);
      final dir = diff.normalized();
      game.add(_Bullet(position: _dragStart!, velocity: dir * (power * 5 + 200)));
      game.shaker.shake(duration: 0.1, intensity: power / 20);
    }
    
    _isDragging = false;
    _dragStart = null;
    _dragCurrent = null;
  }

  @override
  void render(Canvas canvas) {
    if (!_isDragging || _dragStart == null || _dragCurrent == null) return;

    final start = _dragStart!.toOffset();
    final current = _dragCurrent!.toOffset();
    final diff = _dragStart! - _dragCurrent!;
    final dir = diff.normalized();
    final power = diff.length.clamp(0.0, 200.0);


    final neonPaint = _p
      ..shader = LinearGradient(
              colors: [Colors.cyanAccent, Colors.purpleAccent.withValues(alpha: 0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)
          .createShader(Rect.fromPoints(start, current))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
          (start.dx + current.dx) / 2, (start.dy + current.dy) / 2 + 20, 
          current.dx, current.dy);
    canvas.drawPath(path, neonPaint);
    

    canvas.drawCircle(start, 8, _p..color = Colors.cyanAccent..maskFilter = const MaskFilter.blur(BlurStyle.solid, 10));
    canvas.drawCircle(start, 4, _p..color = Colors.white);


    final dotPaint = _p..color = Colors.white.withValues(alpha: 0.6);
    int dots = (game.difficulty == GameDifficulty.easy) ? 15 : 8;
    for (int i = 1; i <= dots; i++) {
        final t = i * (1.5 / dots);

        final pos = _dragStart! + dir * (power * 5 + 200) * t;
        final alpha = (1.0 - (i/dots)).clamp(0, 1);
        canvas.drawCircle(pos.toOffset(), 3, dotPaint..color = Colors.white.withValues(alpha: alpha * 0.6));
        if (i % 2 == 0) {
            canvas.drawCircle(pos.toOffset(), 5, _p..color = Colors.cyanAccent.withValues(alpha: alpha * 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
        }
    }
  }
}

class _Starfield extends Component with HasGameReference<AngryWeaponGame> {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  final List<Vector2> stars = [];
  final List<double> speeds = [];
  final Random r = Random();

  @override
  void onLoad() {
    for (int i = 0; i < 100; i++) {
      stars.add(Vector2(r.nextDouble() * game.size.x, r.nextDouble() * game.size.y));
      speeds.add(0.2 + r.nextDouble() * 0.8);
    }
  }

  @override
  void update(double dt) {
    for (int i = 0; i < stars.length; i++) {
      stars[i].y += speeds[i] * 50 * dt;
      if (stars[i].y > game.size.y) {
        stars[i].y = -10;
        stars[i].x = r.nextDouble() * game.size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = _p..color = Colors.white;
    for (int i = 0; i < stars.length; i++) {
      paint.color = Colors.white.withValues(alpha: speeds[i] * 0.6);
      canvas.drawCircle(stars[i].toOffset(), speeds[i] * 2, paint);
    }
  }
}


class _Bullet extends PositionComponent with HasGameReference<AngryWeaponGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  Vector2 velocity;
  final List<Vector2> _trail = [];
  late final Random _random;
  _Bullet({required Vector2 position, required this.velocity}) : super(position: position, size: Vector2(12, 12), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _random = Random();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    

    _trail.add(position.clone());
    if (_trail.length > 10) _trail.removeAt(0);


    if (_random.nextDouble() < 0.3) {
      game.add(SparkParticle(position: position.clone(), velocity: Vector2.zero(), color: Colors.yellowAccent, life: 0.3));
    }
    if (position.x < -50 || position.x > game.size.x + 50 || position.y < -50 || position.y > game.size.y + 50) {
      if (!game.isGameOver) {
        game.missCount++;
        if (game.missCount >= 5) {
          game.gameOver();
        }
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {

    if (_trail.length > 2) {
      final trailPaint = _p..color = Colors.yellowAccent.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2;
      final path = Path()..moveTo(0, 0);
      for (int i = 0; i < _trail.length; i++) {
          final relPos = _trail[i] - position;
          path.lineTo(relPos.x, relPos.y);
      }
      canvas.drawPath(path, trailPaint);
    }


    canvas.drawCircle(Offset.zero, 8, _p..color = Colors.yellowAccent.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset.zero, 6, _p..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(Offset.zero, 4, _p..color = Colors.yellowAccent);
  }
}

class _EnemyMalice extends PositionComponent with HasGameReference<AngryWeaponGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  Vector2 velocity = Vector2.zero();
  final Random rand;
  double _hp = 1.0;
  bool _isDying = false;

  _EnemyMalice(this.rand, Vector2 startPos) : super(position: startPos, size: Vector2(45, 45), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver || _isDying) return;


    if (game.difficulty == GameDifficulty.hard) {
      final bullets = game.children.whereType<_Bullet>();
      for (final b in bullets) {
        if (position.distanceTo(b.position) < 150) {

           Vector2 dodgeDir = Vector2(-b.velocity.y, b.velocity.x).normalized();
           position += dodgeDir * 100 * dt;
        }
      }
    }


    final target = game.size / 2;
    Vector2 dir = (target - position).normalized();
    velocity.lerp(dir * 100 * game.difficulty.speedMultiplier, 0.05);
    position += velocity * dt;


    scale = Vector2.all(1.0 + 0.05 * sin(game._time * 5));
  }

  @override
  void render(Canvas canvas) {
    final color = _isDying ? Colors.white : Colors.purpleAccent;
    final r = 20.0 * scale.x;
    

    final glitch = (sin(game._time * 20) + 1.0) / 2.0;


    final spikePaint = _p
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
    
    for (int i=0; i<8; i++) {
        double angle = i * pi / 4 + game._time * 2;
        double sLen = r + 12 + 5 * sin(game._time * 10 + i);
        canvas.drawLine(Offset.zero, Offset(cos(angle) * sLen, sin(angle) * sLen), spikePaint);

        canvas.drawCircle(Offset(cos(angle) * sLen, sin(angle) * sLen), 2, _p..color = Colors.white);
    }


    canvas.drawCircle(Offset.zero, r + 5, _p
      ..color = color.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
    
    final corePaint = _p
      ..shader = RadialGradient(
        colors: [color, color.darken(0.5)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, corePaint);
    

    final accentPaint = _p..color = Colors.cyanAccent.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawCircle(Offset.zero, r * 0.7, accentPaint);


    final eyeColor = Colors.redAccent.withValues(alpha: 0.7 + 0.3 * glitch);
    final eyePaint = _p..color = eyeColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(const Offset(-10, -6), 5, eyePaint);
    canvas.drawCircle(const Offset(10, -6), 5, eyePaint);
    canvas.drawCircle(const Offset(-10, -6), 2, _p..color = Colors.white);
    canvas.drawCircle(const Offset(10, -6), 2, _p..color = Colors.white);
  }


  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is _Bullet) {
      _hit();
      other.removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _hit() {
    _hp -= 1.0;
    if (_hp <= 0) {
      _explode();
    }
  }

  void _explode() {
    _isDying = true;
    game.score += 10;
    game.shaker.shake(duration: 0.2, intensity: 5);
    game.add(SparkEmitter(position: position.clone(), color: Colors.purpleAccent, count: 12));
    game.add(SparkEmitter(position: position.clone(), color: Colors.white, count: 5));
    removeFromParent();
  }
}
