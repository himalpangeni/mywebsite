import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

class GlowHockeyGame extends FlameGame with PanDetector {
  final GameDifficulty difficulty;
  int playerScore = 0;
  int aiScore = 0;
  bool isGameOver = false;
  
  late TextComponent hud;
  late ScreenShake shaker;
  
  Vector2 puckPos = Vector2.zero();
  Vector2 puckVel = Vector2.zero();
  Vector2 playerPos = Vector2.zero();
  Vector2 aiPos = Vector2.zero();

  final double puckRadius = 22;
  final double paddleRadius = 38;
  final List<Vector2> _trail = [];
  double _flashIntensity = 0;

  GlowHockeyGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF01010A);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    await super.onLoad();
    shaker = ScreenShake();
    add(shaker);
    restart();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    isGameOver = false;
    playerScore = 0;
    aiScore = 0;
    _flashIntensity = 0;
    
    puckPos = size / 2;
    puckVel = Vector2.zero();
    playerPos = Vector2(size.x / 2, size.y - 150);
    aiPos = Vector2(size.x / 2, 150);

    hud = TextComponent(
      text: '0 - 0',
      position: Vector2(size.x / 2, 60),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 80,
          fontWeight: FontWeight.w900,
          letterSpacing: 10,
          shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 25)],
        ),
      ),
    );
    add(hud);

    add(CinematicOverlay());
    add(_HockeyRenderer());
    resumeEngine();
  }

  void resumeGame() {
    _resetPuck();
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    puckPos += puckVel * dt;
    puckVel *= 0.988;

    _trail.add(puckPos.clone());
    if (_trail.length > 12) _trail.removeAt(0);

    if (_flashIntensity > 0) _flashIntensity -= dt * 4;



    double aiSpeed = 550 * difficulty.speedMultiplier;
    
    double targetX = puckPos.x.clamp(paddleRadius, size.x - paddleRadius);
    double targetY;
    
    bool puckOnAiSide = puckPos.y < size.y / 2 + 60; 
    bool puckIsSlow = puckVel.length < 200;

    if (puckOnAiSide || (puckIsSlow && puckPos.y < size.y * 0.8)) {

      targetY = (puckPos.y - 50).clamp(paddleRadius, size.y / 2 - paddleRadius);
    } else {

      targetY = 110.0;
    }


    double baseResponsiveness = (aiSpeed * dt / 60);
    double responsiveness = puckIsSlow ? (baseResponsiveness * 1.5).clamp(0, 1) : baseResponsiveness.clamp(0, 1);

    aiPos.x = lerpDouble(aiPos.x, targetX, responsiveness) ?? aiPos.x;
    aiPos.y = lerpDouble(aiPos.y, targetY, responsiveness) ?? aiPos.y;


    if (puckPos.x < puckRadius || puckPos.x > size.x - puckRadius) {
      puckVel.x *= -0.95;
      puckPos.x = puckPos.x.clamp(puckRadius, size.x - puckRadius);
      _onImpact(puckPos, Colors.white70, low: true);
    }

    double goalW = size.x * 0.4;
    double goalL = (size.x - goalW) / 2;
    double goalR = goalL + goalW;

    if (puckPos.y < puckRadius) {
      if (puckPos.x > goalL && puckPos.x < goalR) {
        playerScore++;
        _onGoal(true);
      } else {
        puckVel.y *= -0.95;
        puckPos.y = puckRadius;
        _onImpact(puckPos, Colors.white70, low: true);
      }
    } else if (puckPos.y > size.y - puckRadius) {
      if (puckPos.x > goalL && puckPos.x < goalR) {
        aiScore++;
        _onGoal(false);
      } else {
        puckVel.y *= -0.95;
        puckPos.y = size.y - puckRadius;
        _onImpact(puckPos, Colors.white70, low: true);
      }
    }

    _handlePaddleCollision(playerPos, Colors.cyanAccent);
    _handlePaddleCollision(aiPos, Colors.pinkAccent);

    hud.text = '$aiScore - $playerScore';

    if (playerScore >= 7 || aiScore >= 7) {
      isGameOver = true;
      pauseEngine();
      overlays.add('GameOver');
    }
  }

  void _handlePaddleCollision(Vector2 paddle, Color color) {
    double dist = puckPos.distanceTo(paddle);
    if (dist < (puckRadius + paddleRadius)) {
      Vector2 normal = (puckPos - paddle).normalized();
      puckPos = paddle + normal * (puckRadius + paddleRadius + 1);
      
      double dot = puckVel.dot(normal);
      if (dot < 0) puckVel -= normal * 2 * dot;
      puckVel += normal * 650;
      puckVel.clampLength(0, 900);
      
      _onImpact(puckPos, color);
    }
  }

  void _onImpact(Vector2 pos, Color color, {bool low = false}) {
    shaker.shake(duration: low ? 0.05 : 0.12, intensity: low ? 3 : 8);
    add(SparkEmitter(position: pos.clone(), color: color, count: low ? 5 : 12));
    if (!low) _flashIntensity = 0.25;
  }

  void _onGoal(bool playerScored) {
    shaker.shake(duration: 0.6, intensity: 18);
    _flashIntensity = 0.5;
    add(SparkEmitter(position: puckPos.clone(), color: playerScored ? Colors.cyanAccent : Colors.pinkAccent, count: 30));
    _resetPuck();
  }

  void _resetPuck() {
    puckPos = size / 2;
    puckVel = Vector2.zero();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver) return;
    Vector2 next = playerPos + info.delta.global;
    if (next.y > size.y / 2 + paddleRadius && next.y < size.y - paddleRadius &&
        next.x > paddleRadius && next.x < size.x - paddleRadius) {
      playerPos = next;
    }
  }
}

class _HockeyRenderer extends Component with HasGameReference<GlowHockeyGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;

    final boardPaint = _p..color = Colors.cyanAccent.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 4;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), boardPaint);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), boardPaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 90, boardPaint);
    
    final goalW = w * 0.4;
    final goalL = (w - goalW) / 2;
    canvas.drawRect(Rect.fromLTWH(goalL, -5, goalW, 10), _p..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawRect(Rect.fromLTWH(goalL, h - 5, goalW, 10), _p..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    for (int i = 0; i < g._trail.length; i++) {
      final t = g._trail[i];
      final op = (i / g._trail.length) * 0.35;
      canvas.drawCircle(t.toOffset(), g.puckRadius * (i / g._trail.length), _p..color = Colors.white.withValues(alpha: op)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    canvas.drawCircle(g.puckPos.toOffset(), g.puckRadius + 5, _p..color = Colors.white.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(g.puckPos.toOffset(), g.puckRadius, _p..color = Colors.white);
    canvas.drawCircle(g.puckPos.toOffset(), g.puckRadius * 0.7, _p..color = Colors.black26);

    _drawPaddle(canvas, g.playerPos.toOffset(), Colors.cyanAccent);
    _drawPaddle(canvas, g.aiPos.toOffset(), Colors.pinkAccent);

    if (g._flashIntensity > 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _p..color = Colors.white.withValues(alpha: g._flashIntensity));
    }
  }

  void _drawPaddle(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(pos, game.paddleRadius + 15, Paint()..color = color.withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    canvas.drawCircle(pos, game.paddleRadius, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 5);
    canvas.drawCircle(pos, game.paddleRadius, Paint()..color = color.withValues(alpha: 0.5));
    canvas.drawCircle(pos, game.paddleRadius * 0.4, Paint()..color = Colors.white70);
  }
}
