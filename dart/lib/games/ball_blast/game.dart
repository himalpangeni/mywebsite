
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';

class BallBlastGame extends FlameGame with DragCallbacks {
  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  double cannonX = 0;
  final List<FallingBall> balls = [];
  final List<Bullet> bullets = [];
  final List<FloatingText> texts = [];
  double lastShot = 0;
  int powerUpLevel = 0;
  late ScreenShake shaker;
  final List<Ripple> ripples = [];

  BallBlastGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF1A237E);

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

    score = 0;
    cannonX = size.x / 2;
    balls.clear();
    bullets.clear();
    texts.clear();
    ripples.clear();
    lastShot = 0;
    powerUpLevel = 0;

    add(_BattlefieldRenderer());
    resumeEngine();
  }

  void resumeGame() {
    balls.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (overlays.isActive('GameOver')) return;
    super.update(dt);

    for (int i = texts.length - 1; i >= 0; i--) {
      texts[i].life -= dt * 2;
      texts[i].pos.y -= 80 * dt;
      if (texts[i].life <= 0) texts.removeAt(i);
    }

    lastShot += dt;
    if (lastShot > 0.1) {
      if (powerUpLevel == 0) {
        bullets.add(Bullet(pos: Vector2(cannonX, size.y - 120)));
      } else if (powerUpLevel == 1) {
        bullets.add(Bullet(pos: Vector2(cannonX - 15, size.y - 120)));
        bullets.add(Bullet(pos: Vector2(cannonX + 15, size.y - 120)));
      } else {
        bullets.add(Bullet(pos: Vector2(cannonX - 25, size.y - 120)));
        bullets.add(Bullet(pos: Vector2(cannonX, size.y - 130)));
        bullets.add(Bullet(pos: Vector2(cannonX + 25, size.y - 120)));
      }
      lastShot = 0;
    }


    if (_random.nextDouble() < 0.01 + difficulty.index * 0.005) {
      final isPowerUp = _random.nextDouble() < 0.08;
      balls.add(FallingBall(
        pos: Vector2(_random.nextDouble() * size.x, -50),
        hp: isPowerUp ? 20 : 10 + _random.nextInt(50),
        type: isPowerUp ? BallType.powerup : BallType.normal,
        size: isPowerUp ? 2 : 3,
        vel: Vector2(_random.nextDouble() * 200 - 100, 100),
      ));
    }


    for (int i = bullets.length - 1; i >= 0; i--) {
      bullets[i].pos.y -= 1000 * dt;
      if (bullets[i].pos.y < 0) {
        bullets.removeAt(i);
      } else {
        bool hit = false;
        for (int j = balls.length - 1; j >= 0; j--) {
          if (bullets[i].pos.distanceTo(balls[j].pos) < balls[j].radius + 15) {
            balls[j].hp--;
            bullets.removeAt(i);
            score += 1;

            if (balls[j].hp <= 0) {
              _onBallDestroyed(balls[j]);
              balls.removeAt(j);
            } else {
              texts.add(FloatingText(
                  pos: balls[j].pos.clone() +
                      Vector2(_random.nextDouble() * 20 - 10,
                          _random.nextDouble() * 20 - 10),
                  text: "+1",
                  scale: 0.8,
                  color: Colors.yellowAccent));
            }
            hit = true;
            break;
          }
        }
        if (hit) continue;
      }
    }


    for (int i = balls.length - 1; i >= 0; i--) {
      final b = balls[i];

      b.velocity.y += 400 * dt;
      b.pos += b.velocity * dt;


      if (b.pos.x < b.radius || b.pos.x > size.x - b.radius) {
        b.velocity.x *= -1;
        b.pos.x = b.pos.x.clamp(b.radius, size.x - b.radius);
      }
      

      if (b.pos.y > size.y - 120 - b.radius) {

        double bouncePower = 350 + (4 - b.size) * 50 + _random.nextDouble() * 100;
        b.velocity.y = -bouncePower;
        

        if (_random.nextDouble() < 0.3) {
            b.velocity.x += (_random.nextDouble() * 100 - 50);
            b.velocity.x = b.velocity.x.clamp(-250.0, 250.0);
        }
        
        b.pos.y = size.y - 120 - b.radius;

        ripples.add(Ripple(pos: b.pos.clone(), radius: b.radius));
        SensoryService.lightImpact();
      }


      if ((b.pos.x - cannonX).abs() < b.radius + 30 && b.pos.y > size.y - 150) {
         _gameOver();
      }
      
      if (b.pos.y < -200) balls.removeAt(i);
    }
  }

  void _onBallDestroyed(FallingBall b) {
    shaker.shake(duration: 0.15, intensity: 5);
    add(SparkEmitter(position: b.pos, color: b.type == BallType.powerup ? Colors.cyanAccent : Colors.redAccent, count: 12));
    
    if (b.type == BallType.powerup) {
       powerUpLevel++;
       texts.add(FloatingText(pos: b.pos.clone(), text: "UPGRADE!", scale: 2.0, color: Colors.cyanAccent));
       return;
    }

    score += 10;
    texts.add(FloatingText(pos: b.pos.clone(), text: "BOOM!", scale: 1.2, color: Colors.orange));


    if (b.size > 1) {
       int newSize = b.size - 1;
       int newHp = (b.size * 5).clamp(5, 50);
       balls.add(FallingBall(pos: b.pos.clone(), hp: newHp, size: newSize, vel: Vector2(-150, -200)));
       balls.add(FallingBall(pos: b.pos.clone(), hp: newHp, size: newSize, vel: Vector2(150, -200)));
    }
  }

  void _gameOver() {
    shaker.shake(duration: 0.5, intensity: 20);
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    cannonX += event.localDelta.x;
    cannonX = cannonX.clamp(40, size.x - 40);
  }
}

enum BallType { normal, powerup }

class FallingBall {
  Vector2 pos;
  Vector2 velocity;
  int hp;
  double radius;
  int size;
  BallType type;
  
  FallingBall({required this.pos, required this.hp, this.type = BallType.normal, this.size = 3, Vector2? vel})
      : velocity = vel ?? Vector2(0, 0),
        radius = 15.0 + (size * 12.0);
}

class Bullet {
  Vector2 pos;
  Bullet({required this.pos});
}

class FloatingText {


  Vector2 pos;
  String text;
  double life = 1.0;
  double scale;
  Color color;
  FloatingText(
      {required this.pos,
      required this.text,
      this.scale = 1.0,
      required this.color});
}

class _BattlefieldRenderer extends Component
    with HasGameReference<BallBlastGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    final g = game;

    _drawText(
        canvas, 'SCORE: ${g.score}', Offset(g.size.x / 2, 60), 32, Colors.white,
        bold: true);


    canvas.drawRect(
        Rect.fromLTWH(0, g.size.y - 100, g.size.x, 100),
        _p
          ..shader = LinearGradient(colors: [
            Colors.transparent,
            Colors.cyan.withValues(alpha: 0.2)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(const Rect.fromLTWH(0, 0, 100, 100)));


    final cannonP = _p..color = Colors.cyanAccent;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(g.cannonX, g.size.y - 50),
                width: 60,
                height: 40),
            const Radius.circular(10)),
        _p..color = Colors.indigo);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(g.cannonX, g.size.y - 80),
                width: 30,
                height: 60),
            const Radius.circular(5)),
        cannonP);


    canvas.drawCircle(Offset(g.cannonX - 25, g.size.y - 40), 15,
        _p..color = Colors.grey.shade300);
    canvas.drawCircle(Offset(g.cannonX + 25, g.size.y - 40), 15,
        _p..color = Colors.grey.shade300);


    for (final bul in g.bullets) {
      canvas.drawCircle(
          bul.pos.toOffset(),
          6,
          _p
            ..color = Colors.yellowAccent
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
    }


    for (final b in g.balls) {
      final ballColor =
          b.type == BallType.powerup ? Colors.cyanAccent : Colors.redAccent;
      canvas.drawCircle(b.pos.toOffset(), b.radius, _p..color = ballColor);
      canvas.drawCircle(b.pos.toOffset() + const Offset(-5, -5), b.radius * 0.3,
          _p..color = Colors.white.withValues(alpha: 0.3));

      if (b.type == BallType.powerup) {
        canvas.drawCircle(
            b.pos.toOffset(),
            b.radius,
            _p
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }

      final tp = TextPainter(
          text: TextSpan(
              text: '${b.hp}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(b.pos.x - tp.width / 2, b.pos.y - tp.height / 2));
    }


    for (final r in g.ripples) {
      final alpha = r.life.clamp(0.0, 1.0);
      final radius = r.radius + (1.0 - r.life) * 100;
      canvas.drawCircle(r.pos.toOffset(), radius, _p..color = Colors.white.withValues(alpha: alpha * 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
    }


    for (final t in g.texts) {
      double alpha = t.life.clamp(0.0, 1.0);
      final tp = TextPainter(
          text: TextSpan(
              text: t.text,
              style: TextStyle(
                  color: t.color.withValues(alpha: alpha),
                  fontSize: 24 * t.scale,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: alpha))
                  ])),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(t.pos.x - tp.width / 2, t.pos.y - tp.height / 2));
    }
  }

  void _drawText(
      Canvas canvas, String text, Offset pos, double size, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: color,
                fontSize: size,
                fontWeight: bold ? FontWeight.w900 : FontWeight.normal)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }
}
class Ripple {
  Vector2 pos;
  double radius;
  double life = 1.0;
  Ripple({required this.pos, required this.radius});
}
