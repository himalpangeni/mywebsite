import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';

enum BrickType { normal, overclock, gravity }

class Brick {
  Rect rect;
  Color color;
  BrickType type;
  bool isDestroyed = false;
  double health = 1.0;
  Brick({required this.rect, required this.color, this.type = BrickType.normal});
}

class BallTrail {
  Vector2 pos;
  double life = 1.0;
  BallTrail(this.pos);
}

class BounceBallGame extends FlameGame with PanDetector {
  final GameDifficulty difficulty;
  int score = 0;
  int combo = 0;
  int level = 1;
  bool gameOver = false;

  late Vector2 ballPos;
  late Vector2 ballVel;
  late Rect paddleBox;
  final List<Brick> bricks = [];
  final List<BallTrail> trail = [];

  final double ballRadius = 12;
  final double paddleW = 140;
  final double paddleH = 20;

  late TextComponent scoreText;
  late ScreenShake shaker;

  BounceBallGame({required this.difficulty}) : super();

  @override
  Color backgroundColor() => const Color(0xFF03030F);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    await super.onLoad();
    shaker = ScreenShake();
    add(shaker);
    restart();
  }

  void restart() {
    bricks.clear();
    trail.clear();
    score = 0;
    combo = 0;
    gameOver = false;
    _setupLevel();
  }

  void _setupLevel() {
    bricks.clear();
    trail.clear();
    for (var c in children.toList()) {
      if (c is! ScreenShake && c is! CinematicOverlay && c is! CameraComponent) {
        c.removeFromParent();
      }
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    ballPos = Vector2(size.x / 2, size.y / 2 + 100);
    double speedBase = 280 + (level - 1) * 30;
    ballVel = Vector2(speedBase, -speedBase) * difficulty.speedMultiplier;
    paddleBox =
        Rect.fromLTWH(size.x / 2 - paddleW / 2, size.y - 120, paddleW, paddleH);

    int rows = (4 + level).clamp(6, 10);
    final r = Random();
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < 7; col++) {
        final brW = (size.x - 60) / 7;
        const brH = 24.0;
        final hue = (row * 25 + col * 15).toDouble();
        
        final type = (r.nextDouble() < 0.15) ? BrickType.overclock : BrickType.normal;
        bricks.add(Brick(
          rect: Rect.fromLTWH(30 + col * brW, 100 + row * (brH + 6), brW - 8, brH),
          color: type == BrickType.overclock ? Colors.redAccent : HSVColor.fromAHSV(1.0, hue, 0.7, 0.9).toColor(),
          type: type,
        ));
      }
    }

    scoreText = TextComponent(
      text: '$score',
      position: Vector2(size.x / 2, 60),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 50,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 15)],
        ),
      ),
    );
    add(scoreText);

    add(_BrickRenderer());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    ballPos = Vector2(size.x / 2, size.y / 2 + 100);
    double speedBase = 280 + (level - 1) * 30;
    ballVel = Vector2(speedBase, -speedBase) * difficulty.speedMultiplier;
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);

    final heatMult = 1.0 + (combo * 0.01).clamp(0.0, 0.1);
    ballPos += ballVel * heatMult * dt;
    ballVel.clampLength(0, 720);

    trail.add(BallTrail(ballPos.clone()));
    if (trail.length > 15) trail.removeAt(0);
    for (final t in trail) {
      t.life -= dt * 2;
    }

    if (ballPos.x < ballRadius || ballPos.x > size.x - ballRadius) {
      ballVel.x *= -1.05;
      ballPos.x = ballPos.x.clamp(ballRadius, size.x - ballRadius);
      shaker.shake(duration: 0.1, intensity: 4);
    }
    if (ballPos.y < ballRadius) {
      ballVel.y *= -1.05;
      ballPos.y = ballRadius;
      shaker.shake(duration: 0.1, intensity: 4);
    }

    if (ballPos.y > paddleBox.top - ballRadius &&
        ballPos.y < paddleBox.bottom &&
        ballPos.x > paddleBox.left - 5 &&
        ballPos.x < paddleBox.right + 5) {
      
      SensoryService.mediumImpact();
      double hitPos =
          (ballPos.x - (paddleBox.left + paddleW / 2)) / (paddleW / 2);
      ballVel.y = -ballVel.y.abs();
      ballVel.x = hitPos * 400 * difficulty.speedMultiplier;

      ballPos.y = paddleBox.top - ballRadius;
      combo = 0;
      shaker.shake(duration: 0.1, intensity: 8);
      add(SparkEmitter(position: ballPos.clone(), color: Colors.white, count: 10));
    }

    for (var b in bricks) {
      if (!b.isDestroyed &&
          b.rect.inflate(ballRadius * 0.5).contains(ballPos.toOffset())) {
        
        if (b.type == BrickType.overclock) {

            ballVel.clampLength(0, 720);
            SensoryService.heavyImpact();
        } else {
            SensoryService.lightImpact();
        }

        b.isDestroyed = true;
        ballVel.y *= -1;
        score += 10 + combo * 5;
        combo++;
        scoreText.text = '$score';
        shaker.shake(duration: 0.15, intensity: (6.0 + combo).clamp(6.0, 20.0));
        _burstBrick(b);

        if (bricks.every((br) => br.isDestroyed)) _win();
        break;
      }
    }

    if (ballPos.y > size.y + 100) {
      gameOver = true;
      shaker.shake(duration: 0.6, intensity: 15);
      pauseEngine();
      overlays.add('GameOver');
    }
  }

  void _burstBrick(Brick b) {
    final center = Vector2(b.rect.center.dx, b.rect.center.dy);
    add(SparkEmitter(position: center, color: b.color, count: 12));
    add(SparkEmitter(position: center, color: Colors.white, count: 4));
  }

  void _win() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void nextLevel() {
    level++;
    gameOver = false;
    _setupLevel();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameOver) return;
    double nx = paddleBox.left + info.delta.global.x;
    nx = nx.clamp(0.0, size.x - paddleW);
    paddleBox = Rect.fromLTWH(nx, paddleBox.top, paddleW, paddleH);
  }
}

class _BrickRenderer extends Component with HasGameReference<BounceBallGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  
  @override
  void render(Canvas canvas) {
    final g = game;

    if (g.difficulty == GameDifficulty.easy || g.combo > 5) {
       _drawPrediction(canvas, g);
    }

    for (int i = 0; i < g.trail.length; i++) {
      final t = g.trail[i];
      final op = (i / g.trail.length) * 0.4;
      canvas.drawCircle(
          t.pos.toOffset(),
          g.ballRadius * (i / g.trail.length),
          _p
            ..color = Colors.cyanAccent.withValues(alpha: op)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }

    final pRRect = RRect.fromRectAndRadius(g.paddleBox, const Radius.circular(12));
    canvas.drawRRect(pRRect, _p..color = Colors.cyanAccent..maskFilter = const MaskFilter.blur(BlurStyle.solid, 12));
    canvas.drawRRect(pRRect, _p..color = Colors.white..maskFilter = null);
    canvas.drawRRect(pRRect.deflate(3), _p..color = Colors.black26);

    final ballCore = _p..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final ballGlow = _p..color = Colors.cyanAccent..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(g.ballPos.toOffset(), g.ballRadius + 4, ballGlow);
    canvas.drawCircle(g.ballPos.toOffset(), g.ballRadius, ballCore);

    for (var b in g.bricks) {
      if (!b.isDestroyed) {
        final br = RRect.fromRectAndRadius(b.rect, const Radius.circular(6));
        canvas.drawRRect(br, _p..color = b.color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawRRect(br, _p..color = b.color..maskFilter = null);
        canvas.drawRRect(br.deflate(4), _p..color = Colors.white24);
        canvas.drawRRect(br, _p..style = PaintingStyle.stroke..color = Colors.white38..strokeWidth = 1);
      }
    }
  }

  void _drawPrediction(Canvas canvas, BounceBallGame g) {
    Vector2 simPos = g.ballPos.clone();
    Vector2 simVel = g.ballVel.clone();
    final dotPaint = _p..color = Colors.cyanAccent.withValues(alpha: 0.3)..maskFilter = null..style = PaintingStyle.fill;
    
    for (int i = 0; i < 40; i++) {
      simPos += simVel * 0.016;
      if (simPos.x < g.ballRadius || simPos.x > g.size.x - g.ballRadius) simVel.x *= -1;
      if (simPos.y < g.ballRadius) simVel.y *= -1;
      
      if (i % 4 == 0) {
        canvas.drawCircle(simPos.toOffset(), 3, dotPaint);
      }
      if (simPos.y > g.size.y) break;
    }
  }
}
