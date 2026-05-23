import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import 'package:flame/particles.dart';
import 'dart:math';

class TinyRoyaleGame extends FlameGame with TapCallbacks {

  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;

  final List<Enemy> enemies = [];
  double spawnT = 0;
  
  double stormRadius = 500;
  double _time = 0;

  TinyRoyaleGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF03001E);

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

    gameOver = false;
    score = 0;
    enemies.clear();
    spawnT = 1.0;
    stormRadius = size.x > size.y ? size.x * 0.8 : size.y * 0.8;
    _time = 0;

    hud = TextComponent(
      text: 'ELIMINATIONS: 0', 
      position: Vector2(20, 40), 
      textRenderer: TextPaint(style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, shadows: [Shadow(color: Colors.cyan, blurRadius: 10)]))
    );
    add(hud);
    add(_GridBackground());
    add(_RoyaleRenderer());
    add(TextComponent(
      text: 'Tap enemies quickly before the storm closes in',
      position: Vector2(size.x / 2, size.y - 70),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white70, fontSize: 16)),
    ));
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    enemies.clear();
    stormRadius = (stormRadius + 100).clamp(100.0, 1000.0);
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
    _time += dt;


    stormRadius -= (18 + enemies.length * 2) * difficulty.speedMultiplier * dt;
    if (stormRadius < 80) stormRadius = 80;

    spawnT -= dt;
    if (spawnT <= 0) {
      spawnT = (1.2 / difficulty.speedMultiplier).clamp(0.4, 2.0);
      double angle = Random().nextDouble() * 2 * pi;
      double dist = stormRadius + 50;
      enemies.add(Enemy(
        x: size.x / 2 + cos(angle) * dist,
        y: size.y / 2 + sin(angle) * dist,
      ));
    }

    final px = size.x / 2;
    final py = size.y / 2;
    
    for (final e in enemies) {
      final dx = px - e.x;
      final dy = py - e.y;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist == 0) continue;


      if (dist < 22) {
        _lose();
        return;
      }
      final speed = (120 + score * 2) * difficulty.speedMultiplier;
      final zoneBias = dist > stormRadius ? 1.25 : 1.0;
      e.x += (dx / dist) * speed * zoneBias * dt;
      e.y += (dy / dist) * speed * zoneBias * dt;
      if (Random().nextDouble() < 0.2) {
        add(ParticleSystemComponent(
          position: Vector2(e.x, e.y),
          particle: AcceleratedParticle(speed: Vector2(-dx, -dy).normalized() * 50, lifespan: 0.3, child: CircleParticle(radius: 2, paint: Paint()..color = Colors.redAccent.withValues(alpha: 0.5))),
        ));
      }
    }
    if (Random().nextDouble() < 0.2) {
        add(ParticleSystemComponent(
          position: Vector2(px, py),
          particle: AcceleratedParticle(speed: Vector2.random() * 50, lifespan: 0.3, child: CircleParticle(radius: 2, paint: Paint()..color = Colors.cyanAccent.withValues(alpha: 0.5))),
        ));
    }
    





  }


  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) return;
    final tx = event.localPosition.x;
    final ty = event.localPosition.y;
    
    for (int i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      final dx = tx - e.x;
      final dy = ty - e.y;
      if (sqrt(dx * dx + dy * dy) < 40) {
        enemies.removeAt(i);
        score++;
        hud.text = 'Eliminations: $score';
        add(SparkEmitter(position: Vector2(e.x, e.y), color: Colors.orangeAccent, count: 10));
        return;
      }
    }
  }
}

class Enemy {
  double x, y;
  Enemy({required this.x, required this.y});
}

class _RoyaleRenderer extends Component with HasGameReference<TinyRoyaleGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final px = g.size.x / 2;
    final py = g.size.y / 2;
    

    final stormPaint = _p
      ..color = Colors.purpleAccent.withValues(alpha: 0.3 + 0.1 * sin(g._time * 5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(px, py), g.stormRadius, stormPaint);
    

    final outerPaint = _p
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.deepPurple.withValues(alpha: 0.5)],
        stops: const [0.8, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(px, py), radius: g.stormRadius + 100));
    canvas.drawRect(g.size.toRect(), outerPaint);


    _drawFighter(canvas, Offset(px, py), Colors.cyanAccent, g._time, 0);
    

    for (final e in g.enemies) {
      final dx = px - e.x;
      final dy = py - e.y;
      double angle = atan2(dy, dx) + pi/2;
      _drawFighter(canvas, Offset(e.x, e.y), Colors.redAccent, g._time + e.x, angle);
    }
  }

  void _drawFighter(Canvas canvas, Offset pos, Color color, double time, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final glowPaint = Paint()..color = color.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    

    canvas.drawCircle(Offset.zero, 18, glowPaint);
    

    final path = Path()
      ..moveTo(0, -18)
      ..lineTo(12, 12)
      ..lineTo(0, 6)
      ..lineTo(-12, 12)
      ..close();
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
    

    if (sin(time * 20) > 0) {
        canvas.drawCircle(const Offset(0, 10), 4, Paint()..color = Colors.orangeAccent);
    }
    
    canvas.restore();
  }
}

class _GridBackground extends Component with HasGameReference<TinyRoyaleGame> {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  @override
  void render(Canvas canvas) {
    final g = game;
    final paint = _p..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1;
    const spacing = 50.0;
    
    final offset = (g._time * 20) % spacing;
    
    for (double x = offset; x < g.size.x; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, g.size.y), paint);
    }
    for (double y = offset; y < g.size.y; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(g.size.x, y), paint);
    }
    

    final scanPaint = _p..color = Colors.cyanAccent.withValues(alpha: 0.02)..strokeWidth = 2;
    for (int i = 0; i < 10; i++) {
        double y = (g._time * 100 + i * g.size.y / 10) % g.size.y;
        canvas.drawLine(Offset(0, y), Offset(g.size.x, y), scanPaint);
    }
  }
}

