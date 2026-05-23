
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';

class SpiralRollGame extends FlameGame with PanDetector {
  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  bool isPeeling = false;
  double peelLength = 0;
  late Vector2 toolPos;

  final List<Peel> peels = [];
  final List<Obstacle> obstacles = [];
  double traveledDist = 0;

  SpiralRollGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFFECEFF1);

  @override
  Future<void> onLoad() async {
    _random = Random();
    await super.onLoad();
    restart();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    score = 0;
    traveledDist = 0;
    peelLength = 0;
    isPeeling = false;
    toolPos = Vector2(size.x / 2, size.y - 200);
    peels.clear();
    obstacles.clear();

    add(_SpiralRenderer());
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (overlays.isActive('GameOver')) return;
    super.update(dt);

    double speed = (100 + score * 5).toDouble();
    traveledDist += speed * dt;

    if (isPeeling) {
      peelLength += 150 * dt;
      peelLength = peelLength.clamp(0, 300);
    }


    if (_random.nextDouble() < 0.02) {
      obstacles.add(Obstacle(
          pos: Vector2(size.x / 2 + (_random.nextBool() ? 40 : -40), -50)));
    }


    for (int i = obstacles.length - 1; i >= 0; i--) {
      obstacles[i].pos.y += speed * dt;
      if (obstacles[i].pos.y > size.y) obstacles.removeAt(i);


      if (obstacles[i].pos.distanceTo(toolPos) < 30) {
        _gameOver();
      }
    }


    for (int i = peels.length - 1; i >= 0; i--) {
      peels[i].pos.y -= 400 * dt;
      peels[i].rotation += 5 * dt;
      if (peels[i].pos.y < -100) peels.removeAt(i);


      for (var obs in obstacles) {
        if (obs.pos.distanceTo(peels[i].pos) < peels[i].length / 2 + 20) {
          obstacles.remove(obs);
          score += 10;
          break;
        }
      }
    }
  }

  void _gameOver() {
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onPanDown(DragDownInfo info) {
    isPeeling = true;
    peelLength = 0;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (peelLength > 20) {
      peels.add(Peel(pos: toolPos.clone(), length: peelLength));
    }
    isPeeling = false;
    peelLength = 0;
  }
}

class Peel {
  Vector2 pos;
  double length;
  double rotation = 0;
  Peel({required this.pos, required this.length});
}

class Obstacle {
  Vector2 pos;
  Obstacle({required this.pos});
}

class _SpiralRenderer extends Component with HasGameReference<SpiralRollGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        _p
          ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD7CCC8), Color(0xFFA1887F)])
              .createShader(Rect.fromLTWH(0, 0, w, h)));


    final logRect = Rect.fromLTWH(0, h / 2 - 40, w, 80);
    final logP = _p
      ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5D4037), Color(0xFF8D6E63), Color(0xFF5D4037)])
          .createShader(logRect);
    canvas.drawRect(logRect, logP);


    final grainP = _p
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 80; i += 10) {
      canvas.drawLine(
          Offset(0, h / 2 - 40 + i), Offset(w, h / 2 - 40 + i + 5), grainP);
    }


    final sx = w * 0.3;
    final chiselP = _p
      ..shader =
          LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade700])
              .createShader(Rect.fromLTWH(sx - 10, h / 2 - 60, 20, 40));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(sx - 5, h / 2 - 70 + (g.isPeeling ? 30 : 0), 10, 40),
            const Radius.circular(2)),
        chiselP);
    canvas.drawRect(
        Rect.fromLTWH(sx - 2, h / 2 - 80 + (g.isPeeling ? 30 : 0), 4, 20),
        _p..color = Colors.brown);


    if (g.isPeeling) {
      final peelP = _p
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      final path = Path();
      path.moveTo(sx, h / 2 - 20);
      for (double i = 0; i < g.peelLength; i += 5) {
        double angle = i / 10;
        double radius = i / 10;
        path.lineTo(sx + cos(angle) * (20 + radius),
            h / 2 - 20 - i + sin(angle) * radius);
      }
      canvas.drawPath(path, peelP);
    }


    for (final p in g.peels) {
      canvas.save();
      canvas.translate(p.pos.x, p.pos.y);
      canvas.rotate(p.rotation);
      final pPaint = _p
        ..color = const Color(0xFFBCAAA4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawCircle(Offset.zero, p.length / 10, pPaint);
      canvas.restore();
    }


    for (final obs in g.obstacles) {
      canvas.drawRect(
          Rect.fromCenter(center: obs.pos.toOffset(), width: 30, height: 30),
          _p..color = Colors.redAccent);
    }


    final tp = TextPainter(
        text: TextSpan(
            text: 'SCORE: ${g.score}',
            style: const TextStyle(
                color: Colors.brown,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, 100));
  }
}
