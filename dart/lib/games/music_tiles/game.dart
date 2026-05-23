import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';
import 'package:flame/particles.dart';

class MusicTilesGame extends FlameGame {
  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  final List<Tile> tiles = [];
  double spawnT = 0;
  late TextComponent hud;
  late Sprite logoSprite;
  static const int lanes = 4;

  double laneW = 0;
  double ox = 0;
  late ScreenShake shaker;

  MusicTilesGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF0A0A0A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    laneW = size.x / lanes;
    ox = 0;
  }

  void restart() {
    for (final child in children.toList()) {
      if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    gameOver = false;
    score = 0;
    tiles.clear();
    spawnT = 0.4;

    shaker = ScreenShake();
    add(shaker);
    add(_TouchHandler());
    hud = TextComponent(
      text: '🎵 0',
      position: Vector2(10, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
    add(hud);


    add(TextComponent(
      text: 'MUSIC TILES',
      position: Vector2(size.x / 2, size.y * 0.45),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 10)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 40, 40),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.25),
    ));

    add(CinematicOverlay());
    add(_LaneRenderer());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    tiles.clear();
    spawnT = 0.4;
    overlays.remove('GameOver');
    resumeEngine();
  }

  double get _speed => 320 * difficulty.speedMultiplier;

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    if (laneW <= 0) onGameResize(size);

    spawnT -= dt;
    if (spawnT <= 0) {
      spawnT = (0.55 / difficulty.speedMultiplier).clamp(0.22, 0.65);
      final lane = Random().nextInt(lanes);
      tiles.add(Tile(lane: lane, y: -100));
    }

    final hitY = size.y * 0.8;
    for (int i = tiles.length - 1; i >= 0; i--) {
      final t = tiles[i];
      t.y += _speed * dt;
      if (!t.tapped && t.y > hitY + 120) {
        tiles.removeAt(i);
        _lose();
        return;
      }
      if (t.tapped) {
        tiles.removeAt(i);
      }
    }
    hud.text = '🎵 $score';
  }

  void _lose() {
    gameOver = true;
    shaker.shake(duration: 0.5, intensity: 12);
    pauseEngine();
    overlays.add('GameOver');
  }

  void _processHit(Vector2 localPos) {
    if (gameOver) return;
    if (laneW <= 0) return;
    final lane = ((localPos.x - ox) / laneW).floor().clamp(0, lanes - 1);
    final hitY = size.y * 0.8;


    int bestIdx = -1;
    double bestDist = double.infinity;
    for (int i = 0; i < tiles.length; i++) {
      final t = tiles[i];
      if (t.lane != lane || t.tapped) continue;

      if (t.y > -50 && t.y < size.y + 100) {
        final dist = (t.y - hitY).abs();
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
    }

    if (bestIdx >= 0 && bestDist < 600) {
      final t = tiles[bestIdx];
      t.tapped = true;
      score += 15;
      shaker.shake(duration: 0.05, intensity: 2);
      SensoryService.lightImpact();
      

      final hitPos = Vector2(t.lane * laneW + laneW / 2, t.y);
      tiles.removeAt(bestIdx);


      add(ParticleSystemComponent(
        position: hitPos,
        particle: Particle.generate(
          count: 6,
          lifespan: 0.25,
          generator: (i) => CircleParticle(
            radius: 3.5,
            paint: Paint()..color = Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ));
    }
  }

}

class _TouchHandler extends PositionComponent
    with TapCallbacks, HasGameReference<MusicTilesGame> {
  _TouchHandler() : super(anchor: Anchor.topLeft);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.gameOver) return;
    game._processHit(event.localPosition);
  }
}

class Tile {
  final int lane;
  double y;
  bool tapped = false;
  Tile({required this.lane, required this.y});
}


class SparkEffect extends Component {
  final Vector2 position;
  SparkEffect({required this.position});
  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.purpleAccent;
    final random = Random();
    for (int i = 0; i < 10; i++) {
      final offset =
          Offset(random.nextDouble() * 30 - 15, random.nextDouble() * 30 - 15);
      canvas.drawCircle(
          Offset(position.x + offset.dx, position.y + offset.dy), 3, paint);
    }
  }

  @override
  void update(double dt) {

    removeFromParent();
  }
}

class _LaneRenderer extends Component with HasGameReference<MusicTilesGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint
    ..maskFilter = null
    ..shader = null
    ..style = PaintingStyle.fill
    ..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    final lw = w / MusicTilesGame.lanes;
    final hitY = h * 0.8;


    for (var i = 0; i <= MusicTilesGame.lanes; i++) {
      canvas.drawLine(
          Offset(i * lw, 0),
          Offset(i * lw, h),
          _p
            ..color = Colors.white12
            ..strokeWidth = 1);
    }


    canvas.drawRect(
        Rect.fromLTWH(0, hitY - 2, w, 6),
        _p
          ..color = Colors.purpleAccent.withAlpha(100)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawLine(
        Offset(0, hitY),
        Offset(w, hitY),
        _p
          ..color = Colors.purpleAccent
          ..strokeWidth = 3);


    for (final t in g.tiles) {
      final x = t.lane * lw + 4;
      final tileRect = Rect.fromLTWH(x, t.y, lw - 8, 72);
      final rr = RRect.fromRectAndRadius(tileRect, const Radius.circular(10));

      canvas.drawRRect(
          rr,
          _p
            ..shader = const LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(tileRect));
      canvas.drawRRect(
          rr,
          _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.purpleAccent.withAlpha(150)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6));
      final tp = TextPainter(
        text: const TextSpan(
            text: '♪', style: TextStyle(color: Colors.white54, fontSize: 22)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + (lw - 8) / 2 - tp.width / 2, t.y + 22));
    }
  }
}
