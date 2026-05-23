import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/difficulty.dart';

class SlideShakesGame extends FlameGame with DragCallbacks, TapCallbacks {
  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;
  late TextComponent hint;
  bool hintVisible = true;

  double pX = 80;
  double pVx = 0;
  double pullDistance = 0;
  bool isDragging = false;

  SlideShakesGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF0D0D0D);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    restart();
  }

  void restart() {
    for (var c in children.whereType<PositionComponent>().toList()) {
        c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    gameOver = false;
    score = 0;
    pX = 80;
    pVx = 0;
    pullDistance = 0;
    isDragging = false;

    hud = TextComponent(
      text: 'SCORE: 0',
      position: Vector2(size.x / 2, 60),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2)),
    );
    hintVisible = true;
    hint = TextComponent(
      text: 'PULL BACK & RELEASE',
      position: Vector2(size.x / 2, 110),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5)),
    );
    add(hud);
    add(hint);
    add(_SlideRenderer());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    pX = 80;
    pVx = 0;
    pullDistance = 0;
    isDragging = false;
    camera.viewfinder.anchor = Anchor.topLeft;
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


    final safeDt = dt.clamp(0.0, 0.05);

    hud.text = 'SCORE: $score';

    if (pVx > 0) {
      pX += pVx * safeDt;
      pVx -= 550 * safeDt;
      if (pVx <= 0) {
        pVx = 0;

        if (pX > size.x - 140 && pX < size.x - 40) {
          score++;
          hud.text = 'PERFECT! SCORE: $score';
          pX = 80;
        } else {
          _lose();
        }
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (gameOver || pVx > 0) return;
    isDragging = true;
    pullDistance = 0;
    if (hintVisible) {
      hintVisible = false;
      hint.removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (hintVisible) {
      hintVisible = false;
      hint.removeFromParent();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (gameOver || pVx > 0 || !isDragging) return;
    pullDistance -= event.localDelta.x;
    pullDistance = pullDistance.clamp(0, 200);
    pX = 80 - (pullDistance * 0.2);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!isDragging) return;
    isDragging = false;
    if (hintVisible) {
      hintVisible = false;
      hint.removeFromParent();
    }
    if (pullDistance > 10) {
      pVx = pullDistance * 8 * difficulty.speedMultiplier;
      hud.text = 'SLIDING...';
    } else {
      pX = 80;
    }
    pullDistance = 0;
  }
}

class _SlideRenderer extends Component with HasGameReference<SlideShakesGame> {

  final _tableFillPaint = Paint()..style = PaintingStyle.fill;
  final _targetFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.cyanAccent;
  final _targetStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white;
  final _arrowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..strokeCap = StrokeCap.round
    ..color = Colors.white54;
  final _shadowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black45;


  final _cupFillPaint = Paint()..style = PaintingStyle.fill;
  final _cupStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white24;
  final _glossPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Color.fromRGBO(255, 255, 255, 0.3);


  Shader? _tableShader;
  Shader? _cupShader;
  Size? _lastSize;

  void _rebuildShaders(double w, double h) {
    final tableRect = Rect.fromLTWH(0, h * 0.6, w, h * 0.4);
    _tableShader = const LinearGradient(
      colors: [Color(0xFF4E342E), Color(0xFF2D1B1B)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(tableRect);


    final cupRect = Rect.fromLTWH(0, 0, 40, 70);
    _cupShader = const LinearGradient(
      colors: [Color(0xFFFF5252), Color(0xFFA70000)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(cupRect);
  }

  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    final currentSize = Size(w, h);
    if (_lastSize != currentSize || _tableShader == null) {
      _lastSize = currentSize;
      _rebuildShaders(w, h);
    }


    final tableRect = Rect.fromLTWH(0, h * 0.6, w, h * 0.4);
    canvas.drawRect(tableRect, _tableFillPaint..shader = _tableShader);


    final targetRect = Rect.fromLTWH(w - 140, h * 0.6 - 5, 100, 10);
    canvas.drawRect(targetRect, _targetFillPaint);
    canvas.drawRect(targetRect, _targetStrokePaint);


    if (g.isDragging && g.pullDistance > 10) {
      final arrowPath = Path();
      arrowPath.moveTo(g.pX + 40, h * 0.6 - 60);
      arrowPath.lineTo(g.pX + 40 + g.pullDistance * 1.5, h * 0.6 - 60);
      canvas.drawPath(arrowPath, _arrowPaint);
    }


    final cupRect = Rect.fromCenter(
        center: Offset(g.pX, h * 0.6 - 40), width: 40, height: 70);
    final rCup = RRect.fromRectAndRadius(cupRect, const Radius.circular(8));
    canvas.drawRRect(rCup.shift(const Offset(5, 7)), _shadowPaint);


    canvas.drawRRect(rCup, _cupFillPaint..shader = _cupShader);
    canvas.drawRRect(rCup, _cupStrokePaint);


    canvas.drawRect(
        Rect.fromLTWH(
            cupRect.left + 5, cupRect.top + 5, 6, cupRect.height - 10),
        _glossPaint);
  }
}
