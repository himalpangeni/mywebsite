import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import 'dart:math';
import '../../services/sensory.dart';


class ZombieRescueGame extends FlameGame {
  final GameDifficulty difficulty;
  late final Random _random;
  int score = 0;
  int ammo = 30;
  bool gameOver = false;
  late TextComponent hud;
  late ScreenShake shaker;
  late Sprite logoSprite;

  final List<Zombie> zombies = [];
  final List<Survivor> survivors = [];
  final List<Bullet> bullets = [];
  double zombieSpawnT = 0;
  double survivorSpawnT = 0;
  double _time = 0;

  ZombieRescueGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF0A0F0A);
  
  Vector2 gunPos = Vector2.zero();
  double _dashCooldown = 0;

  @override
  Future<void> onLoad() async {
    _random = Random();
    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
      if (child is! CameraComponent) {
        child.removeFromParent();
      }
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    gameOver = false;
    score = 0;
    ammo = 30;
    _time = 0;
    zombies.clear();
    survivors.clear();
    bullets.clear();
    zombieSpawnT = 1.0;
    survivorSpawnT = 2.0;
    gunPos = Vector2(size.x / 2, size.y - 60);
    _dashCooldown = 0;

    shaker = ScreenShake();
    add(shaker);
    add(_TouchHandler()..size = size);
    add(_WorldRenderer());
    add(_HUD());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    ammo = 15;
    zombies.clear();
    bullets.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _lose() {
    gameOver = true;
    shaker.shake(duration: 0.8, intensity: 15);
    pauseEngine();
    overlays.add('GameOver');
  }

  void _processTap(Vector2 tp) {

    for (int i = survivors.length - 1; i >= 0; i--) {
      if (tp.distanceTo(survivors[i].pos) < 35) {
        score += 50;
        survivors[i].saved = true;
        survivors.removeAt(i);
        shaker.shake(duration: 0.08, intensity: 3);
        return;
      }
    }


    if (ammo > 0) {
      ammo--;
      bullets.add(Bullet(Vector2(gunPos.x, size.y - 120)));
      shaker.shake(duration: 0.03, intensity: 1);
    }

    if (ammo <= 0 && zombies.isNotEmpty) {
      _lose();
    }
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    _time += dt;
    if (_dashCooldown > 0) _dashCooldown -= dt;


    zombieSpawnT -= dt;
    if (zombieSpawnT <= 0) {
      double baseSpawn = (difficulty == GameDifficulty.easy) ? 2.0 : 1.2;
      zombieSpawnT = (baseSpawn / difficulty.speedMultiplier).clamp(0.3, 2.5);
      zombies.add(Zombie(Vector2(_random.nextDouble() * (size.x - 60) + 30, -40), _random));
    }


    survivorSpawnT -= dt;
    if (survivorSpawnT <= 0) {
      double baseSpawn = (difficulty == GameDifficulty.easy) ? 4.0 : 3.0;
      survivorSpawnT = (baseSpawn / difficulty.speedMultiplier).clamp(1.5, 6.0);
      survivors.add(Survivor(Vector2(_random.nextDouble() * (size.x - 80) + 40, -40)));
    }


    for (int i = bullets.length - 1; i >= 0; i--) {
      bullets[i].pos.y -= 700 * dt;
      if (bullets[i].pos.y < -20) bullets.removeAt(i);
    }


    final shelterY = size.y - 100;
    for (int i = zombies.length - 1; i >= 0; i--) {
      if (zombies[i].isRemoved) { zombies.removeAt(i); continue; }
      
      final z = zombies[i];
      double speed = (80 + difficulty.speedMultiplier * 20);
      

      Survivor? target;
      double minDist = (difficulty == GameDifficulty.easy) ? 120 : 250;
      for (final s in survivors) {
        double d = z.pos.distanceTo(s.pos);
        if (d < minDist) {
          minDist = d;
          target = s;
        }
      }

      if (target != null) {

        double steer = (target.pos.x - z.pos.x).clamp(-1.0, 1.0);
        z.pos.x += steer * 40 * dt;
        speed *= (difficulty == GameDifficulty.easy) ? 1.1 : 1.3;
      }

      z.pos.y += speed * dt;


      bool hit = false;
      for (int j = bullets.length - 1; j >= 0; j--) {
        if (bullets[j].pos.distanceTo(z.pos) < 30) {
          z.hp--;
          bullets.removeAt(j);
          if (z.hp <= 0) {
            score += 10;
            zombies.removeAt(i);
            hit = true;
          }
          break;
        }
      }
      if (hit) continue;

      if (z.pos.y > shelterY) {
        _lose();
        return;
      }
    }


    for (int i = survivors.length - 1; i >= 0; i--) {
      if (survivors[i].isRemoved) { survivors.removeAt(i); continue; }
      
      final s = survivors[i];
      double speed = 60.0;
      

      bool scared = false;
      for (final z in zombies) {
        if (s.pos.distanceTo(z.pos) < 150) {
          scared = true;
          break;
        }
      }

      if (scared) speed = 120.0;
      
      s.pos.y += speed * dt;

      if (s.pos.y > shelterY && !s.saved) {
        s.saved = true;
        score += 25;
        ammo += 15;
        survivors.removeAt(i);
      }
    }
  }

}

class _TouchHandler extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<ZombieRescueGame> {
  _TouchHandler() : super(anchor: Anchor.topLeft);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.gameOver) return;

    game.gunPos.x = event.canvasEndPosition.x.clamp(50, game.size.x - 50);
    SensoryService.lightImpact();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.gameOver) return;
    game._processTap(event.localPosition);
  }
}

class Zombie {
  Vector2 pos;
  int hp;
  bool isRemoved = false;
  double wobble;
  Zombie(this.pos, Random r) : hp = 1 + r.nextInt(2), wobble = r.nextDouble() * pi;
}

class Survivor {
  Vector2 pos;
  bool saved = false;
  bool isRemoved = false;
  Survivor(this.pos);
}

class Bullet {
  Vector2 pos;
  Bullet(this.pos);
}

class _WorldRenderer extends Component with HasGameReference<ZombieRescueGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    final gridPaint = _p..color = Colors.greenAccent.withValues(alpha: 0.05)..strokeWidth = 1;
    for (double i = 0; i < w; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, h), gridPaint);
    }
    for (double i = 0; i < h; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(w, i), gridPaint);
    }


    final shelterRect = Rect.fromLTWH(0, h - 100, w, 100);
    canvas.drawRect(shelterRect, _p..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.greenAccent.withValues(alpha: 0.3), Colors.black],
    ).createShader(shelterRect));
    canvas.drawLine(Offset(0, h - 100), Offset(w, h - 100),
      _p..color = Colors.greenAccent..strokeWidth = 4..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));


    final tx = g.gunPos.x;
    final ty = h - 60;
    

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(tx, ty), width: 60, height: 40), const Radius.circular(8)), _p..color = const Color(0xFF1B5E20));

    canvas.drawCircle(Offset(tx, ty), 15, _p..color = const Color(0xFF2E7D32));

    canvas.drawRect(Rect.fromLTWH(tx - 4, ty - 35, 8, 25), _p..color = const Color(0xFF388E3C));

    if (g.ammo > 0) {
      canvas.drawRect(Rect.fromLTWH(tx - 6, ty - 40, 12, 10), _p..color = Colors.greenAccent.withValues(alpha: 0.3 + 0.2 * sin(g._time * 5)));
    }

    final trackPaint = _p..color = Colors.black..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(tx - 35, ty - 5, 10, 20), const Radius.circular(4)), trackPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(tx + 25, ty - 5, 10, 20), const Radius.circular(4)), trackPaint);


    for (final b in g.bullets) {
      canvas.drawOval(Rect.fromCenter(center: b.pos.toOffset(), width: 8, height: 18),
        _p..color = Colors.yellowAccent..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3));
    }


    for (final z in g.zombies) {
      final t = g._time;
      final wobble = sin(t * 8 + z.wobble) * 5;
      final pos = Offset(z.pos.x + wobble, z.pos.y);


      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pos + const Offset(0, 5), width: 28, height: 36), const Radius.circular(5)), _p..color = const Color(0xFF4CAF50));

      canvas.drawCircle(pos - const Offset(0, 20), 14, _p..color = const Color(0xFF66BB6A));

      final eyeGlow = _p..color = Colors.redAccent..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(pos + const Offset(-5, -22), 4, eyeGlow);
      canvas.drawCircle(pos + const Offset(5, -22), 4, eyeGlow);
      canvas.drawCircle(pos + const Offset(-5, -22), 2, _p..color = Colors.white);
      canvas.drawCircle(pos + const Offset(5, -22), 2, _p..color = Colors.white);

      canvas.drawLine(pos + const Offset(-14, 0), pos + const Offset(-24, -15), _p..color = const Color(0xFF388E3C)..strokeWidth = 5..strokeCap = StrokeCap.round);
      canvas.drawLine(pos + const Offset(14, 0), pos + const Offset(24, -15), _p..color = const Color(0xFF388E3C)..strokeWidth = 5..strokeCap = StrokeCap.round);

      if (z.hp > 1) {
        canvas.drawCircle(pos - const Offset(0, 38), 5, _p..color = Colors.red);
      }
    }


    for (final s in g.survivors) {

      canvas.drawCircle(s.pos.toOffset() - const Offset(0, 20), 13, _p..color = Colors.amberAccent);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: s.pos.toOffset() + const Offset(0, 5), width: 24, height: 28), const Radius.circular(4)), _p..color = Colors.blue.shade400);

      canvas.drawCircle(s.pos.toOffset(), 25, _p..color = Colors.yellowAccent.withValues(alpha: 0.2 + 0.1 * sin(g._time * 10))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }


    TextPaint(style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4))
      .render(canvas, 'SAFE ZONE', Vector2(w / 2 - 50, h - 55));
  }
}

class _HUD extends Component with HasGameReference<ZombieRescueGame> {
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;

    final tp = TextPainter(
      text: TextSpan(text: 'SCORE: ${g.score}  🔹AMMO: ${g.ammo}',
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 8)])),
      textDirection: TextDirection.ltr,
    )..layout();


      tp.paint(canvas, const Offset(25, 25));
    

    g.logoSprite.render(canvas, 
      position: Vector2(w - 60, 20),
      size: Vector2.all(40),
      overridePaint: Paint()..color = Colors.white.withValues(alpha: 0.25));
    

    final titleTp = TextPainter(
      text: const TextSpan(text: 'ZOMBIE RESCUE',
        style: TextStyle(color: Colors.white10, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 6)),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset(w / 2 - titleTp.width / 2, h * 0.4));


    if (g.score == 0) {
      final hp = TextPainter(
        text: const TextSpan(text: 'TAP ZOMBIES to shoot  •  TAP SURVIVORS to rescue',
          style: TextStyle(color: Colors.white54, fontSize: 14)),
        textDirection: TextDirection.ltr,
      )..layout();
      hp.paint(canvas, Offset(w / 2 - hp.width / 2, 85));
    }
  }
}
