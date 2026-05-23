import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';


class BreadCutGame extends FlameGame with PanDetector, TapCallbacks {


  final GameDifficulty difficulty;
  int score = 0;
  int cutsOnLoaf = 0;
  bool gameOver = false;
  bool playerWon = false;
  double loafX = 100;
  double loafDir = 1;
  late TextComponent hud;
  late Sprite logoSprite;
  late double loafSpeed;
  bool isSlicing = false;
  double sliceAnim = 0;
  double loafScale = 1.0;
  late ScreenShake shaker;
  final List<SliceLine> sliceLines = [];
  final List<FallingSlice> fallingSlices = [];

  BreadCutGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF2B1B17);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
      if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    shaker = ScreenShake();
    add(shaker);
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    gameOver = false;
    playerWon = false;
    score = 0;
    cutsOnLoaf = 0;
    loafX = 100;
    loafDir = 1;
    loafSpeed = 160 * difficulty.speedMultiplier;
    isSlicing = false;
    sliceAnim = 0;
    loafScale = 1.0;
    sliceLines.clear();

    hud = TextComponent(
      text: 'Cuts: 0/6',
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
        ),
      ),
    );
    add(hud);


    add(TextComponent(
      text: 'BREAD CUT',
      position: Vector2(size.x / 2, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: const Color(0xFFFFD54F).withValues(alpha: 0.1), fontSize: 80, fontWeight: FontWeight.w900, letterSpacing: 8)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 45, 45),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.25),
    ));

    add(_KitchenRenderer());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    playerWon = false;
    cutsOnLoaf = 0;
    loafScale = 1.0;
    isSlicing = false;
    sliceAnim = 0;
    sliceLines.clear();
    fallingSlices.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);

    final w = size.x;
    final loafW = 180.0 * loafScale;

    if (!isSlicing) {
      loafX += loafDir * loafSpeed * dt;
      if (loafX > w - loafW - 20) {
        loafX = w - loafW - 20;
        loafDir = -1;
      }
      if (loafX < 20) {
        loafX = 20;
        loafDir = 1;
      }
    } else {
      sliceAnim += dt * 5;
      if (sliceAnim >= 1.0) {
        isSlicing = false;
        sliceAnim = 0;
      }
    }


    for (int i = fallingSlices.length - 1; i >= 0; i--) {
      final s = fallingSlices[i];
      s.velY += 1200 * dt;
      s.offsetY += s.velY * dt;
      s.angle += s.rotation * dt * 10;
      if (s.offsetY > size.y) fallingSlices.removeAt(i);
    }


    for (int i = sliceLines.length - 1; i >= 0; i--) {
      final line = sliceLines[i];
      line.ttl -= dt;
      if (line.ttl <= 0) {
        sliceLines.removeAt(i);
      }
    }

    hud.text = 'Cuts: $cutsOnLoaf/6  •  Score: ${score.toInt()}';
  }

  void _win() {
    playerWon = true;
    gameOver = true;
    shaker.shake(duration: 0.8, intensity: 12);
    pauseEngine();
    overlays.add('GameOver');
  }

  void _lose() {
    playerWon = false;
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void _processAction() {
    if (gameOver || isSlicing) return;
    isSlicing = true;
    sliceAnim = 0;

    final w = size.x;
    final h = size.y;
    final loafW = 180.0 * loafScale;
    final loafH = 80.0 * loafScale;
    final knifeX = w / 2;
    final window = 50.0 / difficulty.speedMultiplier;
    final cx = loafX + loafW / 2;
    final err = (cx - knifeX).abs();

    if (err < window * 2.5) {
      final perfect = err < window;
      cutsOnLoaf++;
      loafScale = 1.0 - (cutsOnLoaf / 6) * 0.5;
      score += perfect ? 50 : 20;
      shaker.shake(duration: perfect ? 0.3 : 0.1, intensity: perfect ? 10 : 4);

      sliceLines.add(SliceLine(x: knifeX, ttl: 0.5));


      const sliceW = 180.0 / 6;
      fallingSlices.add(FallingSlice(
          x: knifeX - sliceW / 2,
          y: h * 0.38 - loafH,
          w: sliceW,
          h: loafH,
          segmentIndex: cutsOnLoaf - 1,
          rotation: (Random().nextDouble() - 0.5) * 0.5));

      if (cutsOnLoaf >= 6) {
        _win();
      }
    } else {
      _lose();
    }
  }

  @override
  void onPanDown(DragDownInfo info) {
    _processAction();
  }

  @override
  void onTapDown(TapDownEvent event) {
    _processAction();
  }
}

class SliceLine {
  double x;
  double ttl;
  SliceLine({required this.x, required this.ttl});
}

class FallingSlice {
  final double x;
  final double y;
  final double w;
  final double h;
  final double rotation;
  double offsetY = 0;
  double velY = -150;
  double angle = 0;
  final int segmentIndex;
  FallingSlice({required this.x, required this.y, required this.w, required this.h, required this.segmentIndex, required this.rotation});
}

class _KitchenRenderer extends Component with HasGameReference<BreadCutGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final h = g.size.y;
    final w = g.size.x;


    canvas.drawRect(Rect.fromLTWH(0, h * 0.38, w, h * 0.52),
        _p..color = const Color(0xFF5D4037));
    final p = _p
      ..color = Colors.black26
      ..strokeWidth = 2;
    for (double i = 0; i < w; i += 30) {
      canvas.drawLine(Offset(i, h * 0.38), Offset(i, h * 0.9), p);
    }


    final knifeX = w / 2;
    final knifeYBase = h * 0.38 - 60;
    final knifeY = knifeYBase +
        (g.sliceAnim > 0.5 ? (1.0 - g.sliceAnim) * 120 : g.sliceAnim * 120);
    final knifePaint = _p..color = Colors.grey.shade400;
    canvas.drawRect(Rect.fromLTWH(knifeX - 5, knifeY, 10, 170), knifePaint);
    canvas.drawRect(
        Rect.fromLTWH(knifeX - 5, knifeY, 10, 170),
        _p
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 1);
    canvas.drawRect(Rect.fromLTWH(knifeX - 1, knifeY, 2, 170),
        _p..color = Colors.white.withValues(alpha: 0.5));


    canvas.drawRect(Rect.fromLTWH(knifeX - 40, h * 0.38 - 10, 80, 20),
        _p..color = Colors.greenAccent.withValues(alpha: 0.15));
    canvas.drawLine(
        Offset(knifeX - 40, h * 0.38),
        Offset(knifeX + 40, h * 0.38),
        _p
          ..color = Colors.greenAccent.withValues(alpha: 0.5)
          ..strokeWidth = 2);


    for (final s in g.fallingSlices) {
      final sRect = Rect.fromLTWH(s.x, s.y, s.w, s.h);
      final sRRect =
          RRect.fromRectAndRadius(sRect, Radius.circular(22.0 * g.loafScale));
      canvas.save();
      canvas.translate(0, s.offsetY);
      canvas.drawRRect(sRRect, _p..color = const Color(0xFF8B4513));
      canvas.drawRRect(
          sRRect.deflate(5), _p..color = const Color(0xFFD2B48C));
      canvas.restore();
    }

    final loafTop = h * 0.38 - 80.0;
    const totalSegments = 6;
    const segW = 180.0 / totalSegments;
    const segH = 80.0;


    final cutPaint = _p
      ..color = Colors.redAccent.withValues(alpha: 0.6)
      ..strokeWidth = 4;
    for (final cut in g.sliceLines) {
      canvas.drawLine(
        Offset(cut.x, loafTop + 8),
        Offset(cut.x, loafTop + segH - 8),
        cutPaint,
      );
    }

    for (int i = g.cutsOnLoaf; i < totalSegments; i++) {
      final sx = g.loafX + i * segW;
      final segRect = Rect.fromLTWH(sx, loafTop, segW, segH);
      final segRRect = RRect.fromRectAndCorners(
        segRect,
        topLeft: i == g.cutsOnLoaf ? const Radius.circular(20) : Radius.zero,
        bottomLeft: i == g.cutsOnLoaf ? const Radius.circular(20) : Radius.zero,
        topRight: i == totalSegments - 1 ? const Radius.circular(20) : Radius.zero,
        bottomRight: i == totalSegments - 1 ? const Radius.circular(20) : Radius.zero,
      );
      
      canvas.drawRRect(segRRect, _p..color = const Color(0xFF8B4513));
      canvas.drawRRect(segRRect.deflate(4), _p..color = const Color(0xFFD2B48C));
      

      if (i > g.cutsOnLoaf) {
        canvas.drawLine(Offset(sx, loafTop + 5), Offset(sx, loafTop + segH - 5), _p..color = Colors.black26..strokeWidth = 1);
      }
    }
    for (final s in g.fallingSlices) {
      canvas.save();
      canvas.translate(s.x + s.w / 2, s.y + s.offsetY + s.h / 2);
      canvas.rotate(s.angle);
      final sliceRect = Rect.fromCenter(center: Offset.zero, width: s.w, height: s.h);
      canvas.drawRRect(RRect.fromRectAndRadius(sliceRect, const Radius.circular(18)), _p..color = const Color(0xFF8B4513));
      canvas.drawRRect(RRect.fromRectAndRadius(sliceRect.deflate(4), const Radius.circular(14)), _p..color = const Color(0xFFD2B48C));
      canvas.restore();
    }


    final instr = TextPainter(
      text: TextSpan(
          text: 'SWIPE DOWN to slice! ${6 - g.cutsOnLoaf} cuts left',
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    instr.paint(canvas, Offset(w / 2 - instr.width / 2, h * 0.88));
  }
}
