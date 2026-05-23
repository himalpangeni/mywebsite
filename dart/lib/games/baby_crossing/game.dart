import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import '../../models/difficulty.dart';
import 'package:flame/particles.dart';


class BabyCrossingGame extends FlameGame with TapCallbacks, PanDetector {
  final GameDifficulty difficulty;
  int score = 0;
  int row = 0;
  int level = 1;
  int playerLane = 1;
  double playerX = 0;
  final List<double> laneXs = [];
  bool gameOver = false;
  bool playerWon = false;
  late TextComponent hud;
  final List<Car> cars = [];
  double carSpawn = 0;
  List<double> laneYs = [];
  int coins = 0;
  final List<GameCoin> gameCoins = [];  bool _swipeConsumed = false;
  BabyCrossingGame({required this.difficulty}) : super();

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
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
    playerWon = false;
    score = 0;
    row = 0;
    level = 1;
    playerLane = 1;
    playerX = size.x / 2;
    coins = 0;
    cars.clear();
    gameCoins.clear();
    carSpawn = 0;
    hud = TextComponent(
      text: 'Tap outer areas to move left/right, center to hop',
      position: Vector2(10, 8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF1A237E),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(hud);
    add(_CrossingPainter());

    final hint = TextComponent(
      text: 'TAP LEFT/RIGHT TO MOVE LANES, TAP CENTER TO HOP FORWARD.',
      position: Vector2(size.x / 2, 110),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
      ),
    );
    add(hint);
    Future.delayed(const Duration(seconds: 4), () => hint.removeFromParent());

    resumeEngine();
    if (size.x > 0 && size.y > 0) _layoutLanes();
  }

  void resumeGame() {
    gameOver = false;
    playerWon = false;
    row = (row - 1).clamp(0, 100);
    cars.clear();
    gameCoins.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _layoutLanes() {
    final h = size.y;
    final w = size.x;

    final gameH = min(h, w * 2.0);
    final topMargin = (h - gameH) / 2;
    
    const n = 7;
    laneYs = List.generate(n, (i) => topMargin + gameH * 0.85 - i * (gameH * 0.7 / (n - 1)));
    laneXs
      ..clear()
      ..addAll([w * 0.2, w * 0.5, w * 0.8]);
    playerX = laneXs[playerLane.clamp(0, laneXs.length - 1)];
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutLanes();
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    if (laneYs.isEmpty) _layoutLanes();
    carSpawn -= dt;
    if (carSpawn <= 0 && laneYs.length > 2) {
      carSpawn = (0.55 / (difficulty.speedMultiplier * (1 + level * 0.08)))
          .clamp(0.18, 0.65);
      final r = Random();
      final lane = r.nextInt(laneYs.length - 2) + 1;
      cars.add(Car(
        y: laneYs[lane],
        x: r.nextBool() ? -90.0 : size.x + 90,
        vx: (r.nextBool() ? 1 : -1) * (160 + level * 15) * difficulty.speedMultiplier,
        w: 80 + r.nextInt(40).toDouble(),
        color: Color.lerp(
          const Color(0xFFFF5252),
          const Color(0xFF536DFE),
          r.nextDouble(),
        )!,
      ));


      if (r.nextDouble() < 0.45) {

        final exactLane = r.nextInt(laneXs.length);
        gameCoins.add(GameCoin(
          y: laneYs[lane],
          x: laneXs[exactLane],
        ));
      }
    }
    
    for (int i = gameCoins.length - 1; i >= 0; i--) {
        final c = gameCoins[i];
        final bx = playerX;
        final by = laneYs[row];
        if ((c.x - bx).abs() < 30 && (c.y - by).abs() < 10) {
            coins++;
            score += 50;
            add(ParticleSystemComponent(
               position: Vector2(c.x, c.y),
               particle: Particle.generate(count: 8, lifespan: 0.5, generator: (idx) => CircleParticle(radius: 3, paint: Paint()..color = Colors.amber)),
            ));
            gameCoins.removeAt(i);
        }
    }

    for (final c in cars.toList()) {
      c.x += c.vx * dt;
      if (c.x < -200 || c.x > size.x + 200) cars.remove(c);
    }
    _checkHit();
    hud.text = 'Score: $score  •  💰 $coins  •  Lvl: $level';
  }

  void _checkHit() {
    if (row <= 0 || row >= laneYs.length - 1) return;
    final by = laneYs[row];
    final bx = playerX;
    for (final c in cars) {
      if ((c.y - by).abs() > 25) continue;
      if ((c.x - bx).abs() < (c.w / 2 + 25)) {
        _lose();
      }
    }
  }

  void _lose() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void _moveSide(int direction) {
    playerLane = (playerLane + direction).clamp(0, laneXs.length - 1);
    playerX = laneXs[playerLane];
  }

  void _hop() {
    if (gameOver) return;
    if (row < laneYs.length - 1) {
      row++;
      _checkHit();
      if (gameOver) return;
    }
    if (row >= laneYs.length - 1) {
      score += 100 * level;
      if (level >= 100) {
        gameOver = true;
        playerWon = true;
        pauseEngine();
        overlays.add('GameOver');
        return;
      }
      level++;
      final levelUpTxt = TextComponent(
          text: 'LEVEL $level!',
          position: Vector2(size.x / 2, size.y / 2),
          anchor: Anchor.center,
          textRenderer: TextPaint(style: const TextStyle(color: Colors.yellowAccent, fontSize: 36, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
      );
      add(levelUpTxt);
      Future.delayed(const Duration(seconds: 1), () => levelUpTxt.removeFromParent());
      row = 0;
      playerLane = 1;
      playerX = laneXs[playerLane.clamp(0, laneXs.length - 1)];
      cars.clear();
      carSpawn = 0;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) return;
    final x = event.localPosition.x;
    final y = event.localPosition.y;
    
    if (y > size.y - 140) {
        if (x < size.x * 0.35) { _moveSide(-1); return; }
        if (x > size.x * 0.65) { _moveSide(1); return; }
        _hop();
        return;
    }
    

    _hop();
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (gameOver) return;
    _swipeConsumed = false;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameOver || _swipeConsumed) return;
    final delta = info.delta.global;
    if (delta.x.abs() > 18 && delta.x.abs() > delta.y.abs()) {
      _moveSide(delta.x > 0 ? 1 : -1);
      _swipeConsumed = true;
      return;
    }
    if (delta.y < -12) {
      _hop();
      _swipeConsumed = true;
    }
  }
}

class Car {
  double x, y, vx, w;
  Color color;
  Car({
    required this.x,
    required this.y,
    required this.vx,
    required this.w,
    required this.color,
  });
}

class _CrossingPainter extends Component with HasGameReference<BabyCrossingGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    if (g.laneYs.isEmpty) return;
    final w = g.size.x;
    for (var i = 0; i < g.laneYs.length; i++) {
      final y = g.laneYs[i];
      final sidewalk = i == 0 || i == g.laneYs.length - 1;
      canvas.drawRect(
        Rect.fromLTWH(0, y - 28, w, 56),
        _p
          ..color = sidewalk
              ? const Color(0xFF8D6E63).withValues(alpha: 0.85)
              : const Color(0xFF455A64),
      );
      if (!sidewalk) {
        for (var x = 0.0; x < w; x += 40) {
          canvas.drawRect(
            Rect.fromLTWH(x, y - 2, 22, 4),
            _p..color = Colors.white.withValues(alpha: 0.85),
          );
        }
      }
    }


    final leftControl = Rect.fromLTWH(0, g.size.y - 140, w * 0.35, 140);
    final rightControl = Rect.fromLTWH(w * 0.65, g.size.y - 140, w * 0.35, 140);
    final centerControl = Rect.fromLTWH(w * 0.35, g.size.y - 140, w * 0.30, 140);
    
    canvas.drawRect(leftControl, _p..color = Colors.white10);
    canvas.drawRect(rightControl, _p..color = Colors.white10);
    canvas.drawRect(centerControl, _p..color = Colors.white24);
    final jtp = TextPainter(text: const TextSpan(text: 'JUMP', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    jtp.paint(canvas, centerControl.center - Offset(jtp.width/2, jtp.height/2));
    
    canvas.drawLine(
        Offset(leftControl.center.dx + 12, leftControl.center.dy),
        Offset(leftControl.center.dx - 18, leftControl.center.dy),
        _p..color = Colors.white70..strokeWidth = 4);
    canvas.drawLine(
        Offset(leftControl.center.dx - 18, leftControl.center.dy),
        leftControl.center + const Offset(6, -12),
        _p..color = Colors.white70..strokeWidth = 4);
    canvas.drawLine(
        Offset(leftControl.center.dx - 18, leftControl.center.dy),
        leftControl.center + const Offset(6, 12),
        _p..color = Colors.white70..strokeWidth = 4);
    canvas.drawLine(
        Offset(rightControl.center.dx - 12, rightControl.center.dy),
        Offset(rightControl.center.dx + 18, rightControl.center.dy),
        _p..color = Colors.white70..strokeWidth = 4);
    canvas.drawLine(
        Offset(rightControl.center.dx + 18, rightControl.center.dy),
        rightControl.center + const Offset(-6, -12),
        _p..color = Colors.white70..strokeWidth = 4);
    canvas.drawLine(
        Offset(rightControl.center.dx + 18, rightControl.center.dy),
        rightControl.center + const Offset(-6, 12),
        _p..color = Colors.white70..strokeWidth = 4);

    for (final c in g.cars) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.x, c.y), width: c.w, height: 36),
        const Radius.circular(8),
      );
      canvas.drawRRect(r, _p..color = c.color);
      canvas.drawRRect(
        r,
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.black26,
      );
    }

    for (final c in g.gameCoins) {

        canvas.drawCircle(Offset(c.x, c.y), 10, _p..color = Colors.amberAccent);
        canvas.drawCircle(Offset(c.x, c.y), 10, _p..color = Colors.orange..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    final bx = g.playerX;
    final by = g.laneYs[g.row.clamp(0, g.laneYs.length - 1)];
    canvas.drawCircle(
      Offset(bx, by),
      22,
      _p..color = const Color(0xFFFFCCBC),
    );
    canvas.drawCircle(
      Offset(bx - 6, by - 4),
      3,
      _p..color = Colors.black87,
    );
    canvas.drawCircle(
      Offset(bx + 6, by - 4),
      3,
      _p..color = Colors.black87,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(bx, by + 2), radius: 10),
      0.1,
      1.2,
      false,
      _p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black54,
    );
  }
}

class GameCoin {
    double x, y;
    GameCoin({required this.x, required this.y});
}
