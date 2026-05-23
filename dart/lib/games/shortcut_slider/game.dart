import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import '../../models/difficulty.dart';



class ShortcutSliderGame extends FlameGame with TapCallbacks, DragCallbacks {
  final GameDifficulty difficulty;
  int score = 0;
  int lane = 1;
  double _visualX = 0;
  double speed = 0;
  double spawnZ = 0;
  final List<Barrier> barriers = [];
  bool gameOver = false;
  late TextComponent scoreText;

  ShortcutSliderGame({required this.difficulty}) : super() {
    speed = 180 * difficulty.speedMultiplier;
  }

  @override
  Color backgroundColor() => const Color(0xFF0A0A18);

  @override
  Future<void> onLoad() async {
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
    lane = 1;
    _visualX = size.x / 2;
    barriers.clear();
    spawnZ = 0;
    speed = 180 * difficulty.speedMultiplier;

    resumeEngine();
    _initUI();
  }

  void resumeGame() {
    gameOver = false;

    barriers.clear();
    spawnZ = 0;
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _initUI() {
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(16, 16),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00FFD1),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);
    add(_RailRenderer());
    add(_PlayerGlow(xGetter: () => _visualX));

    final hint = TextComponent(
      text: 'DRAG LEFT/RIGHT OR TAP SIDES TO SWITCH LANES.',
      position: Vector2(size.x / 2, size.y - 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
    );
    add(hint);
    Future.delayed(const Duration(seconds: 4), () => hint.removeFromParent());
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);


    final safeDt = dt.clamp(0.0, 0.05);

    spawnZ += speed * safeDt;
    while (spawnZ > 140) {
      spawnZ -= 140;
      _spawnBarrierRow();
    }
    for (final b in barriers.toList()) {
      b.z -= speed * safeDt;
      if (b.z < -80) barriers.remove(b);
      if (b.z > -30 && b.z < 40 && b.blockedLanes.contains(lane)) {
        _lose();
        return;
      }
    }


    final targetX = (lane + 0.5) * (size.x / 3);
    final lerpFactor = (15 * safeDt).clamp(0.0, 1.0);
    _visualX = _visualX + (_visualX - targetX).abs() < 0.5
        ? targetX
        : _visualX + (targetX - _visualX) * lerpFactor;

    score += (safeDt * 8 * difficulty.speedMultiplier).round();
    scoreText.text = 'Score: $score';
  }

  void _spawnBarrierRow() {
    final r = Random();
    final blocked = <int>{};
    if (r.nextDouble() < 0.55) {
      blocked.add(r.nextInt(3));
    }
    if (r.nextDouble() < 0.35) {
      blocked.add(r.nextInt(3));
    }
    if (blocked.length >= 3) blocked.remove(blocked.first);
    barriers.add(Barrier(z: 520, blockedLanes: blocked));
  }

  void _lose() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (gameOver) return;
    final x = event.canvasPosition.x;
    if (x < size.x / 3) {
      lane = 0;
    } else if (x > 2 * size.x / 3) {
      lane = 2;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (gameOver) return;
    final w = size.x;
    final x = event.canvasEndPosition.x.clamp(0.0, w);
    if (x < w / 3) {
      lane = 0;
    } else if (x < 2 * w / 3) {
      lane = 1;
    } else {
      lane = 2;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) return;
    final x = event.localPosition.x;
    if (x < size.x / 3) {
      lane = 0;
    } else if (x > 2 * size.x / 3) {
      lane = 2;
    }
  }
}

class Barrier {
  double z;
  final Set<int> blockedLanes;
  Barrier({required this.z, required this.blockedLanes});
}

class _RailRenderer extends Component with HasGameReference<ShortcutSliderGame> {

  final _fillPaint = Paint()..style = PaintingStyle.fill;
  final _dividerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFF00FFD1).withValues(alpha: 0.25);
  final _barrierFillPaint = Paint()..style = PaintingStyle.fill;
  final _barrierStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white24;


  List<Shader>? _laneShaders;
  Size? _lastSize;

  void _rebuildShaders(double w, double h) {
    final laneW = w / 3;
    _laneShaders = List.generate(3, (i) {
      final x = i * laneW;
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A1035).withValues(alpha: 0.9),
          const Color(0xFF0D1A2E),
        ],
      ).createShader(Rect.fromLTWH(x, 0, laneW, h));
    });
  }

  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    final laneW = w / 3;


    final currentSize = Size(w, h);
    if (_lastSize != currentSize || _laneShaders == null) {
      _lastSize = currentSize;
      _rebuildShaders(w, h);
    }

    for (var i = 0; i < 3; i++) {
      final x = i * laneW;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, laneW, h),
        _fillPaint..shader = _laneShaders![i],
      );
      canvas.drawLine(
        Offset(x + laneW, 0),
        Offset(x + laneW, h),
        _dividerPaint,
      );
    }


    final barrierShader = LinearGradient(
      colors: const [Color(0xFFFF3366), Color(0xFF990033)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    for (final b in g.barriers) {
      final py = h * 0.62 - b.z * 0.85;
      for (var L = 0; L < 3; L++) {
        if (!b.blockedLanes.contains(L)) continue;
        final cx = L * laneW + laneW / 2;
        final rr = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, py), width: laneW * 0.72, height: 36),
          const Radius.circular(10),
        );
        canvas.drawRRect(rr, _barrierFillPaint..shader = barrierShader);
        canvas.drawRRect(rr, _barrierStrokePaint);
      }
    }
  }
}

class _PlayerGlow extends Component with HasGameReference<ShortcutSliderGame> {

  final _glowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF00FFD1).withValues(alpha: 0.35);
  final _corePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF00FFD1);
  final _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.white;

  final double Function() xGetter;
  _PlayerGlow({required this.xGetter});

  @override
  void render(Canvas canvas) {
    final h = game.size.y;
    final cx = xGetter();
    final cy = h * 0.62;
    canvas.drawCircle(Offset(cx, cy), 22, _glowPaint);
    canvas.drawCircle(Offset(cx, cy), 14, _corePaint);
    canvas.drawCircle(Offset(cx, cy), 14, _strokePaint);
  }
}
