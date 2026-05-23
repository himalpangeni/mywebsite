import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/difficulty.dart';


class TapCounterGame extends FlameGame with TapCallbacks {
  final GameDifficulty difficulty;
  int score = 0;
  int lives = 3;
  bool gameOver = false;
  final List<Target> targets = [];
  double spawnT = 0;
  late TextComponent hud;

  TapCounterGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF121212);

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
    lives = 3;
    targets.clear();
    spawnT = 0.5;
    
    hud = TextComponent(
      text: 'TAP TO CLEAR',
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
    add(hud);
    add(_TapPainter());
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    
    spawnT -= dt;
    if (spawnT <= 0) {
      spawnT = (1.5 / difficulty.speedMultiplier).clamp(0.6, 2.0);
      final r = Random();
      targets.add(Target(
        x: r.nextDouble() * (size.x - 100) + 50,
        y: -60,
        vy: 100 * difficulty.speedMultiplier,
        left: r.nextInt(3) + 2,
        hue: r.nextDouble() * 360,
      ));
    }
    
    for (final t in targets.toList()) {
      t.y += t.vy * dt;
      if (t.y > size.y + 50) {
        targets.remove(t);
        lives--;
        if (lives <= 0) _lose();
      }
    }
    hud.text = 'Score: $score  |  Lives: $lives';
  }

  void _lose() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) return;
    final p = event.localPosition;
    for (final t in targets.toList()) {
      final dist = (Vector2(t.x, t.y) - p).length;
      if (dist < 45) {
        t.left--;
        score += 5;
        if (t.left <= 0) {
          targets.remove(t);
          score += 25;
        }
        return;
      }
    }
  }
}

class Target {
  double x, y, vy;
  int left;
  final double hue;
  Target({required this.x, required this.y, required this.vy, required this.left, required this.hue});
}

class _TapPainter extends Component with HasGameReference<TapCounterGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    for (final t in game.targets) {
      final color = HSVColor.fromAHSV(1, t.hue, 0.7, 0.9).toColor();
      

      canvas.drawCircle(Offset(t.x + 4, t.y + 4), 40, _p..color = Colors.black38..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      

      canvas.drawCircle(Offset(t.x, t.y), 45, _p..color = color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      

      canvas.drawCircle(Offset(t.x, t.y), 40, _p..color = color);
      canvas.drawCircle(Offset(t.x, t.y), 40, _p..style = PaintingStyle.stroke..color = Colors.white38..strokeWidth = 2);
      
      final tp = TextPainter(
        text: TextSpan(text: '${t.left}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(t.x - tp.width / 2, t.y - tp.height / 2));
    }
  }
}
