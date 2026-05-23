
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';

class SmashHitGame extends FlameGame with TapCallbacks {
  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  final List<GlassObstacle> obstacles = [];
  double traveledDist = 0;
  final List<Ball> balls = [];

  SmashHitGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF006064);

  @override
  Future<void> onLoad() async {
    _random = Random();
    await super.onLoad();
    restart();
  }

  void resumeGame() {
    overlays.remove('GameOver');
    resumeEngine();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    score = 0;
    traveledDist = 0;
    obstacles.clear();
    balls.clear();

    add(_VoidRenderer());
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (overlays.isActive('GameOver')) return;
    super.update(dt);

    double speed = 300.0;
    traveledDist += speed * dt;


    if (_random.nextDouble() < 0.05) {
      obstacles.add(
          GlassObstacle(pos: Vector2(_random.nextDouble() * size.x, -50)));
    }


    for (int i = balls.length - 1; i >= 0; i--) {
      balls[i].pos += balls[i].velocity * dt;
      if (balls[i].pos.y < 0) {
        balls.removeAt(i);
      } else {
        for (int j = obstacles.length - 1; j >= 0; j--) {
          if (balls[i].pos.distanceTo(obstacles[j].pos) < 40) {
            obstacles.removeAt(j);
            balls.removeAt(i);
            score += 50;
            break;
          }
        }
      }
    }


    for (int i = obstacles.length - 1; i >= 0; i--) {
      obstacles[i].pos.y += speed * dt;
      if (obstacles[i].pos.y > size.y) {
        obstacles.removeAt(i);
        _gameOver();
      }
    }
  }

  void _gameOver() {
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onTapDown(TapDownEvent event) {
    balls.add(Ball(
        pos: Vector2(size.x / 2, size.y - 100),
        velocity: (event.localPosition - Vector2(size.x / 2, size.y - 100))
                .normalized() *
            1000));
  }
}

class GlassObstacle {
  Vector2 pos;
  GlassObstacle({required this.pos});
}

class Ball {
  Vector2 pos;
  Vector2 velocity;
  Ball({required this.pos, required this.velocity});
}

class _VoidRenderer extends Component with HasGameReference<SmashHitGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;


    final glassP = _p
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final edgeP = _p
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final obs in g.obstacles) {
      final rect =
          Rect.fromCenter(center: obs.pos.toOffset(), width: 60, height: 60);
      canvas.drawRect(rect, glassP);
      canvas.drawRect(rect, edgeP);
    }


    for (final b in g.balls) {
      canvas.drawCircle(b.pos.toOffset(), 8, _p..color = Colors.white70);
    }
  }
}
