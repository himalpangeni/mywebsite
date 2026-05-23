
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/particles.dart';
import '../../models/difficulty.dart';

class StackColorsGame extends FlameGame with PanDetector {
  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  double playerLane = 0;
  Color playerColor = Colors.red;
  final List<StackItem> stack = [];
  final List<Collectible> collectibles = [];
  double traveledDist = 0;

  StackColorsGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFFF1F8E9);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
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
    playerLane = 0;
    traveledDist = 0;
    playerColor = Colors.red;
    stack.clear();
    collectibles.clear();
    
    add(_StackRenderer());
    resumeEngine();
  }

  void resumeGame() {
    traveledDist = (traveledDist - 100).clamp(0.0, double.infinity);
    collectibles.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (overlays.isActive('GameOver')) return;
    super.update(dt);

    double speed = (150 + score * 2).toDouble();
    traveledDist += speed * dt;


    if (_random.nextDouble() < 0.05) {
        Color c;
        if (_random.nextDouble() < 0.6) {
            c = playerColor;
        } else {
            c = [Colors.red, Colors.green, Colors.blue][_random.nextInt(3)];
        }
        collectibles.add(Collectible(pos: Vector2((_random.nextInt(3) - 1) * 60, -50), color: c));
    }


    for (int i = collectibles.length - 1; i >= 0; i--) {
        collectibles[i].pos.y += speed * dt;
        if (collectibles[i].pos.y > size.y) collectibles.removeAt(i);
        

        final pPos = Vector2(playerLane, size.y - 150);
        if (collectibles[i].pos.distanceTo(pPos) < 30) {
            if (collectibles[i].color == playerColor) {
                score += 10;
                stack.add(StackItem(color: playerColor));
                add(ParticleSystemComponent(
                    position: Vector2(playerLane + size.x/2, size.y - 150),
                    particle: Particle.generate(count: 5, lifespan: 0.3, generator: (idx) => CircleParticle(radius: 3, paint: Paint()..color = playerColor)),
                ));
                collectibles.removeAt(i);
            } else {
                if (stack.isNotEmpty) {
                    stack.removeLast();
                    collectibles.removeAt(i);
                } else {
                    _gameOver();
                }
            }
        }
    }
  }

  void _gameOver() {
      pauseEngine();
      overlays.add('GameOver');
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    playerLane += info.delta.global.x;
    playerLane = playerLane.clamp(-100, 100);
  }
}

class StackItem {
    final Color color;
    StackItem({required this.color});
}

class Collectible {
    Vector2 pos;
    Color color;
    Collectible({required this.pos, required this.color});
}

class _StackRenderer extends Component with HasGameReference<StackColorsGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final center = g.size.x / 2;
    

    canvas.drawRect(Rect.fromLTWH(center - 120, 0, 240, g.size.y), _p..color = Colors.black12);


    for (final c in g.collectibles) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center + c.pos.x, c.pos.y), width: 40, height: 20), const Radius.circular(4)), _p..color = c.color);
    }


    final playerY = g.size.y - 150;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center + g.playerLane, playerY), width: 50, height: 25), const Radius.circular(4)), _p..color = g.playerColor);
    
    for (int i = 0; i < g.stack.length; i++) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center + g.playerLane, playerY - (i + 1) * 10), width: 45, height: 8), const Radius.circular(2)), _p..color = g.stack[i].color);
    }
  }
}
