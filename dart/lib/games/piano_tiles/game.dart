import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import '../../models/difficulty.dart';


class PianoTilesGame extends FlameGame with TapCallbacks, PanDetector {



  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  final List<Tile> tiles = [];
  double spawnT = 0;
  late TextComponent hud;
  static const int lanes = 4;

  double laneW = 0;
  double ox = 0;

  PianoTilesGame({required this.difficulty}) : super();

  @override
  Color backgroundColor() => const Color(0xFF0C0C0C);

  @override
  Future<void> onLoad() async {

    await super.onLoad();
    restart();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    laneW = min(size.x / lanes, size.y / 2);
    ox = (size.x - laneW * lanes) / 2;
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    gameOver = false;
    score = 0;
    tiles.clear();
    spawnT = 0.4;
    hud = TextComponent(
      text: 'Score: 0',
      position: Vector2(10, 40),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
    add(hud);
    add(_LaneRenderer());
    resumeEngine();
  }

  double get _speed => 350 * difficulty.speedMultiplier;

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    if (laneW <= 0) onGameResize(size);
    
    spawnT -= dt;
    if (spawnT <= 0) {
      spawnT = (0.55 / difficulty.speedMultiplier).clamp(0.22, 0.55);
      final lane = Random().nextInt(lanes);
      final ink = Random().nextDouble() < 0.75;
      tiles.add(Tile(lane: lane, y: -100, isInk: ink));
    }
    
    final hitY = size.y * 0.8;
    for (final t in tiles.toList()) {
      t.y += _speed * dt;
      if (t.isInk && t.y > hitY + 60) {
        tiles.remove(t);
        _lose();
        return;
      }
      if (t.y > size.y + 100) {
        tiles.remove(t);
      }
    }
    hud.text = 'Score: $score';
  }

  void _lose() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void _processHit(Vector2 localPos) {
    if (gameOver) return;
    final lane = ((localPos.x - ox) / laneW).floor().clamp(0, lanes - 1);
    final hitY = size.y * 0.8;
    
    Tile? hit;
    for (final t in tiles) {
      if (t.lane != lane) continue;
      if ((t.y - hitY).abs() < 90) {
        hit = t;
        break;
      }
    }
    
    if (hit == null) return;
    if (!hit.isInk) {
      _lose();
    } else {
      tiles.remove(hit);
      score += 15;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    _processHit(event.localPosition);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {

    _processHit(info.eventPosition.widget);
  }
}

class Tile {
  int lane;
  double y;
  final bool isInk;
  Tile({required this.lane, required this.y, required this.isInk});
}

class _LaneRenderer extends Component with HasGameReference<PianoTilesGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    final lw = w / PianoTilesGame.lanes;
    final hitY = h * 0.78;
    for (var i = 0; i <= PianoTilesGame.lanes; i++) {
      canvas.drawLine(
        Offset(i * lw, 0),
        Offset(i * lw, h),
        _p..color = Colors.white12,
      );
    }
    canvas.drawLine(
      Offset(0, hitY),
      Offset(w, hitY),
      _p
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 3,
    );
    for (final t in g.tiles) {
      final x = t.lane * lw + 4;
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, t.y, lw - 8, 72),
        const Radius.circular(8),
      );
      if (t.isInk) {
        canvas.drawRRect(
          rr,
          _p
            ..shader = const LinearGradient(
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF8A2BE2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(x, t.y, lw - 8, 72)),
        );

        canvas.drawRRect(
          rr,
          _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4)
            ..color = Colors.purpleAccent.withValues(alpha: 0.4),
        );
      } else {
        canvas.drawRRect(rr, _p..color = const Color(0xFFF5F5F5));
      }
      canvas.drawRRect(
        rr,
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white24,
      );
    }
  }
}
