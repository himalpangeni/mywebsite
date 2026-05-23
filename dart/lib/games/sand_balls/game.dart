import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

class Ball {
  Vector2 pos;
  Vector2 vel;
  double radius = 8;
  Color color;
  Ball({required this.pos, required this.vel, required this.color});
}

class SandBallsGame extends FlameGame with PanDetector {
  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  final List<Ball> balls = [];
  final List<List<bool>> grid = [];
  static const int gridSizeX = 45;
  static const int gridSizeY = 110;
  late double cellW, cellH;
  late ScreenShake shaker;
  late Sprite logoSprite;


  SandBallsGame({required this.difficulty});

  @override
  Color backgroundColor() =>
      const Color(0xFF2C1B10);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    _random = Random();
    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
    cellW = size.x / gridSizeX;
    cellH = size.y / gridSizeY;
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
      if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    shaker = ScreenShake();
    add(shaker);
    overlays.remove('GameOver');

    score = 0;
    balls.clear();
    grid.clear();



    for (int y = 0; y < gridSizeY; y++) {
      grid.add(List.filled(gridSizeX, true));
    }


    final rand = Random();
    for (int i = 0; i < 30; i++) {
      balls.add(Ball(
        pos: Vector2(size.x / 2 + (rand.nextDouble() - 0.5) * 60,
            60 + rand.nextDouble() * 40),
        vel: Vector2.zero(),
        color: Colors.primaries[rand.nextInt(Colors.primaries.length)],
      ));
    }

    add(CinematicOverlay());
    add(_SandRenderer());


    add(TextComponent(
      text: 'SAND BALLS',
      position: Vector2(size.x / 2, size.y * 0.45),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.white.withValues(alpha: 0.05), fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 8)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 45, 45),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.2),
    ));

    resumeEngine();
  }

  void resumeGame() {

    if (balls.isEmpty) {
      for (int i = 0; i < 20; i++) {
        balls.add(Ball(
          pos: Vector2(size.x / 2 + (Random().nextDouble() - 0.5) * 60, 60),
          vel: Vector2.zero(),
          color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
        ));
      }
    }
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);


    final gravity = Vector2(0, 450 * difficulty.speedMultiplier);

    for (int i = 0; i < balls.length; i++) {
      final b = balls[i];


      b.vel += gravity * dt;
      final nextPos = b.pos + b.vel * dt;


      int gx = (nextPos.x / cellW).floor().clamp(0, gridSizeX - 1);
      int gy = (nextPos.y / cellH).floor().clamp(0, gridSizeY - 1);

      if (grid[gy][gx]) {

        b.vel *= 0.1;

        if (gx > 0 && !grid[gy][gx - 1]) {
          b.vel.x = -80;
        } else if (gx < gridSizeX - 1 && !grid[gy][gx + 1]) {
          b.vel.x = 80;
        }
      } else {
        b.pos = nextPos;
      }


      for (int j = i + 1; j < balls.length; j++) {
        final b2 = balls[j];
        final dist = b.pos.distanceTo(b2.pos);
        if (dist < (b.radius + b2.radius)) {
          final normal = (b.pos - b2.pos).normalized();
          final overlap = (b.radius + b2.radius) - dist;
          b.pos += normal * overlap * 0.5;
          b2.pos -= normal * overlap * 0.5;
          b.vel *= 0.8;
          b2.vel *= 0.8;
        }
      }


      if (b.pos.x < b.radius) {
        b.pos.x = b.radius;
        b.vel.x *= -0.5;
      }
      if (b.pos.x > size.x - b.radius) {
        b.pos.x = size.x - b.radius;
        b.vel.x *= -0.5;
      }


      if (b.pos.y > size.y - 100) {
        if (b.pos.x > size.x * 0.25 && b.pos.x < size.x * 0.75) {
          score++;
          add(SparkEmitter(position: b.pos.clone(), color: b.color, count: 5));
          balls.removeAt(i);
          i--;
          if (score % 5 == 0) shaker.shake(duration: 0.1, intensity: 3);
        } else if (b.pos.y > size.y + 50) {
          balls.removeAt(i);
          i--;
        }
      }
    }

    if (balls.isEmpty && score > 0) {
      _finishLevel();
    }
  }

  bool get gameOver => overlays.isActive('GameOver');

  void _finishLevel() {
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameOver) return;
    final p = info.eventPosition.global;


    const radius = 2.8;
    int gx = (p.x / cellW).floor();
    int gy = (p.y / cellH).floor();

    bool changed = false;
    for (int i = -3; i <= 3; i++) {
      for (int j = -3; j <= 3; j++) {
        final tx = (gx + i).clamp(0, gridSizeX - 1);
        final ty = (gy + j).clamp(0, gridSizeY - 1);
        if (sqrt(i * i + j * j) <= radius) {
          if (grid[ty][tx]) {
            grid[ty][tx] = false;
            changed = true;
          }
        }
      }
    }
    if (changed) {

      if (_random.nextDouble() < 0.3) {
        add(SparkParticle(
          position: p,
          velocity: Vector2((_random.nextDouble() - 0.5) * 100, 50),
          color: const Color(0xFFF9A825),
          life: 0.5,
        ));
      }
    }
  }
}

class _SandRenderer extends Component with HasGameReference<SandBallsGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    final holePaint = _p..color = const Color(0xFF4E342E);


    final sandPaint = _p
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFB300), Color(0xFFF57F17)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    for (int y = 0; y < SandBallsGame.gridSizeY; y++) {
      for (int x = 0; x < SandBallsGame.gridSizeX; x++) {
        if (g.grid[y][x]) {
          canvas.drawRect(
              Rect.fromLTWH(
                  x * g.cellW, y * g.cellH, g.cellW + 0.5, g.cellH + 0.5),
              sandPaint);
        } else {

          if (x % 5 == 0 && y % 5 == 0) {
            canvas.drawCircle(Offset(x * g.cellW, y * g.cellH), 2,
                holePaint..color = holePaint.color.withValues(alpha: 0.1));
          }
        }
      }
    }


    for (final b in g.balls) {
      final ballPos = b.pos.toOffset();

      canvas.drawCircle(
          ballPos + const Offset(3, 4),
          b.radius,
          _p
            ..color = Colors.black38
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));


      final paint = _p
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.7,
          colors: [Colors.white70, b.color, b.color.withValues(alpha: 0.8)],
        ).createShader(Rect.fromCircle(center: ballPos, radius: b.radius));
      canvas.drawCircle(ballPos, b.radius, paint);


      canvas.drawCircle(ballPos - Offset(b.radius * 0.3, b.radius * 0.3),
          b.radius * 0.2, _p..color = Colors.white.withValues(alpha: 0.5));
    }


    final truckRect = Rect.fromLTWH(w * 0.2, h - 90, w * 0.6, 70);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            truckRect.inflate(4), const Radius.circular(15)),
        _p
          ..color = Colors.cyanAccent.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));


    final truckPaint = _p
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(truckRect, const Radius.circular(12)),
        truckPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(truckRect, const Radius.circular(12)),
        _p
          ..color = Colors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);


    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(truckRect.left, truckRect.top, truckRect.width, 10),
            const Radius.circular(12)),
        _p..color = Colors.white10);


    final tp = TextPainter(
      text: TextSpan(
        text: '${g.score}',
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 48,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, 50));
  }
}
