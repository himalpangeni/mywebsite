import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import 'dart:math';
import '../../widgets/cinematic_effects.dart';

class TennisGame extends FlameGame {

  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;
  late Sprite logoSprite;

  double ballX = 0, ballY = 0;
  double ballVx = 0, ballVy = 0;
  double enemyX = 0;
  double playerX = 0;
  late ScreenShake shaker;

  TennisGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF27ae60);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
  }

  @override
  void onMount() {
    super.onMount();
    restart();
  }

  void resumeGame() {
    gameOver = false;
    ballX = size.x / 2;
    ballY = size.y / 2;
    ballVx = (Random().nextBool() ? 180 : -180);
    ballVy = 300 * difficulty.speedMultiplier;
    enemyX = size.x / 2;
    playerX = size.x / 2;
    overlays.remove('GameOver');
    resumeEngine();
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
    
    ballX = size.x / 2;
    ballY = size.y / 2;
    ballVx = (Random().nextBool() ? 180 : -180);
    ballVy = 300 * difficulty.speedMultiplier;
    enemyX = size.x / 2;
    playerX = size.x / 2;

    shaker = ScreenShake();
    add(shaker);
    add(_TouchHandler()..size = size);
    hud = TextComponent(
      text: 'Returns: 0',
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
        ),
      ),
    );
    add(hud);
    

    add(TextComponent(
      text: 'TENNIS',
      position: Vector2(size.x / 2, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white24, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 12)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 50, 50),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.3),
    ));

    add(CinematicOverlay());
    add(_TennisRenderer());
    resumeEngine();
  }

  void _lose() {
    gameOver = true;
    shaker.shake(duration: 0.5, intensity: 12);
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    
    ballX += ballVx * dt;
    ballY += ballVy * dt;


    if (ballX < 15 || ballX > size.x - 15) {
      ballVx *= -1;
      ballX = ballX.clamp(15, size.x - 15);
      shaker.shake(duration: 0.05, intensity: 2);
    }


    double aiSpeed = 350 * difficulty.speedMultiplier;
    if (ballVy < 0) {
      double targetX = ballX + (Random().nextDouble() - 0.5) * 20;
      if (enemyX < targetX - 5) enemyX += aiSpeed * dt;
      if (enemyX > targetX + 5) enemyX -= aiSpeed * dt;
    } else {

      if (enemyX < size.x / 2 - 5) enemyX += 100 * dt;
      if (enemyX > size.x / 2 + 5) enemyX -= 100 * dt;
    }
    enemyX = enemyX.clamp(30.0, size.x - 30.0);


    if (ballY < 70 && ballVy < 0) {
      if ((ballX - enemyX).abs() < 50) {
        ballVy *= -1.02;
        ballX += (ballX - enemyX) * 2;
        shaker.shake(duration: 0.1, intensity: 4);
        add(SparkEmitter(position: Vector2(ballX, ballY), color: Colors.redAccent, count: 8));
      } else if (ballY < 20) {

        score += 5;
        hud.text = 'Returns: $score';
        _resetBall();
      }
    }


    if (ballY > size.y - 120 && ballVy > 0) {
      if ((ballX - playerX).abs() < 80) {
        ballVy *= -1.05;
        ballX += (ballX - playerX) * 2;
        score++;
        hud.text = 'Returns: $score';
        shaker.shake(duration: 0.15, intensity: 6);
        add(SparkEmitter(
            position: Vector2(ballX, ballY),
            color: Colors.yellowAccent,
            count: 12));
      } else if (ballY > size.y - 20) {
        _lose();
      }
    }
  }

  void _resetBall() {
    ballX = size.x / 2;
    ballY = size.y / 2;
    ballVx = (Random().nextBool() ? 200 : -200);
    ballVy = 300 * difficulty.speedMultiplier;
  }

}

class _TouchHandler extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<TennisGame> {
  _TouchHandler() : super(anchor: Anchor.topLeft);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.gameOver) return;
    game.playerX = event.canvasPosition.x.clamp(30.0, game.size.x - 30.0);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.gameOver) return;
    game.playerX = event.canvasEndPosition.x.clamp(30.0, game.size.x - 30.0);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.gameOver) return;
    game.playerX = event.localPosition.x.clamp(30.0, game.size.x - 30.0);
  }
}

class _TennisRenderer extends Component with HasGameReference<TennisGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    

    final linePaint = _p..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 4..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(20, 20, w - 40, h - 40), linePaint);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), linePaint..strokeWidth = 6);
    

    final enemyRect = Rect.fromCenter(center: Offset(g.enemyX, 60), width: 70, height: 15);
    canvas.drawRRect(RRect.fromRectAndRadius(enemyRect, const Radius.circular(5)), _p..color = Colors.redAccent..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8));
    canvas.drawRRect(RRect.fromRectAndRadius(enemyRect, const Radius.circular(5)), _p..color = Colors.redAccent);
    

    final px = g.playerX;
    final py = h - 80;
    
    canvas.save();
    canvas.translate(px, py);
    

    canvas.drawOval(Rect.fromCenter(center: const Offset(4, 4), width: 80, height: 100), _p..color = Colors.black45..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));


    final handlePaint = _p..color = const Color(0xFF5D4037);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 50), width: 12, height: 40), const Radius.circular(4)), handlePaint);
    

    final frameRect = Rect.fromCenter(center: Offset.zero, width: 75, height: 95);
    final framePaint = _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..shader = const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]).createShader(frameRect);
    canvas.drawOval(frameRect, framePaint);
    

    final stringPaint = _p..color = Colors.white30..strokeWidth = 1;
    for (int i=-3; i<=3; i++) {
        canvas.drawLine(Offset(i * 10, -40), Offset(i * 10, 40), stringPaint);
        canvas.drawLine(Offset(-30, i * 12), Offset(30, i * 12), stringPaint);
    }
    

    canvas.drawOval(const Rect.fromLTWH(-20, -35, 15, 30), _p..color = Colors.white10);

    canvas.restore();



    const ballRadius = 14.0;
    final ballPos = Offset(g.ballX, g.ballY);
    canvas.drawCircle(ballPos, ballRadius + 5, _p..color = Colors.yellowAccent.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(ballPos, ballRadius, _p..color = Colors.yellowAccent);
    

    final logoPaint = _p..color = Colors.black..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(g.ballX - 6, g.ballY), Offset(g.ballX + 6, g.ballY), logoPaint);
  }
}
