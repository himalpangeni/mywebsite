import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../widgets/cinematic_effects.dart';
import '../../models/difficulty.dart';

class PacNeonGame extends FlameGame with PanDetector {

  final GameDifficulty difficulty;
  int score = 0;
  int dotsLeft = 0;
  bool gameOver = false;
  late TextComponent hud;
  late ScreenShake shaker;
  late Sprite logoSprite;

  double _mouthAngle = 0;
  double _mouthDir = 1;
  double _time = 0;

  static const int cols = 13;
  static const int rows = 15;
  late List<List<int>> grid;
  

  double px = 1, py = 1;
  double targetPx = 1, targetPy = 1;
  double moveSpeed = 5.0;

  int gx = 11, gy = 13;
  int g2x = 1, g2y = 13;
  double ghostCd = 0;
  double powerT = 0;
  Vector2 moveDir = Vector2.zero();

  PacNeonGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF030308);

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
    overlays.remove('GameOver');

    gameOver = false;
    score = 0;
    powerT = 0;
    px = 1; py = 1;
    targetPx = 1; targetPy = 1;
    gx = 11; gy = 13;
    g2x = 1; g2y = 13;
    ghostCd = 0;
    moveDir = Vector2.zero();
    _time = 0;
    _buildMaze();
    hud = TextComponent(
      text: 'SCORE: 0',
      position: Vector2(size.x / 2, 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00F5FF),
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
          shadows: [Shadow(color: Color(0xFF00F5FF), blurRadius: 10)],
        ),
      ),
    );
    add(hud);
    

    add(TextComponent(
      text: 'PAC NEON',
      position: Vector2(size.x / 2, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.1), fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 10)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 40, 40),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.cyanAccent.withValues(alpha: 0.3),
    ));

    add(_MazeRenderer());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    powerT = 5;
    gx = 11; gy = 1;
    g2x = 1; g2y = 1;
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _buildMaze() {
    final layout = [
      "1111111111111",
      "1002222222221",
      "1211121112111",
      "1222222222221",
      "1211121211121",
      "1222221222221",
      "1112111112111",
      "1222223222221",
      "1112111112111",
      "1222221222221",
      "1211121211121",
      "1222222222221",
      "1211121112111",
      "1222222222221",
      "1111111111111",
    ];
    grid = List.generate(rows, (y) => List.generate(cols, (x) => int.parse(layout[y][x])));
    
    dotsLeft = 0;
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (grid[y][x] == 2 || grid[y][x] == 3) dotsLeft++;
      }
    }
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    _time += dt;
    if (powerT > 0) powerT -= dt;
    ghostCd -= dt * difficulty.speedMultiplier;

    _mouthAngle += dt * 10 * _mouthDir;
    if (_mouthAngle > 0.8) _mouthDir = -1;
    if (_mouthAngle < 0) _mouthDir = 1;


    if (moveDir.length > 0) {
      final dx = moveDir.x;
      final dy = moveDir.y;
      final nx = (px + dx * moveSpeed * dt * difficulty.speedMultiplier);
      final ny = (py + dy * moveSpeed * dt * difficulty.speedMultiplier);
      

      final nxInt = nx.clamp(0, cols - 1.0).round();
      final pyInt = py.round();
      if (nxInt >= 0 && nxInt < cols && pyInt >= 0 && pyInt < rows && grid[pyInt][nxInt] != 1) {
        px = nx.clamp(1, cols - 2.0);
      }
      

      final pxInt = px.round();
      final nyInt = ny.clamp(0, rows - 1.0).round();
      if (nyInt >= 0 && nyInt < rows && pxInt >= 0 && pxInt < cols && grid[nyInt][pxInt] != 1) {
        py = ny.clamp(1, rows - 2.0);
      }
      

      final cpx = px.round();
      final cpy = py.round();
      if (grid[cpy][cpx] == 2) {
        grid[cpy][cpx] = 0;
        dotsLeft--;
        score += 10;
        add(SparkEmitter(position: _gridToWorld(cpx, cpy), color: const Color(0xFF00F5FF), count: 5));
      } else if (grid[cpy][cpx] == 3) {
        grid[cpy][cpx] = 0;
        dotsLeft--;
        score += 50;
        powerT = 8;
        shaker.shake(duration: 0.3, intensity: 6);
        add(SparkEmitter(position: _gridToWorld(cpx, cpy), color: Colors.pinkAccent, count: 12));
      }
    }

    if (ghostCd <= 0) {
      ghostCd = 0.35;
      _stepGhost(gx, gy, (nx, ny) { gx = nx; gy = ny; });
      _stepGhost(g2x, g2y, (nx, ny) { g2x = nx; g2y = ny; });
    }

    final cpx = px.round();
    final cpy = py.round();
    if ((cpx == gx && cpy == gy) || (cpx == g2x && cpy == g2y)) {
      if (powerT > 0) {
        score += 100;
        shaker.shake(duration: 0.2, intensity: 5);
        if (gx == cpx && gy == cpy) { gx = 11; gy = 1; }
        if (g2x == cpx && g2y == cpy) { g2x = 1; g2y = 1; }
      } else {
        _lose();
      }
    }

    if (dotsLeft <= 0) {
      score += 1000;
      shaker.shake(duration: 0.5, intensity: 10);
      restart();
    }
    hud.text = 'SCORE: $score';
  }

  Vector2 _gridToWorld(int x, int y) {
    final cell = min(size.x / (cols + 0.8), (size.y - 120) / (rows + 0.8));
    final ox = (size.x - cell * cols) / 2;
    final oy = (size.y - cell * rows) / 2 + 40;
    return Vector2(ox + x * cell + cell / 2, oy + y * cell + cell / 2);
  }

  void _stepGhost(int x, int y, void Function(int, int) set) {
    final opts = <List<int>>[];
    for (final d in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      final nx = x + d[0], ny = y + d[1];
      if (nx >= 0 && ny >= 0 && nx < cols && ny < rows && grid[ny][nx] != 1) {
        opts.add(d);
      }
    }
    if (opts.isEmpty) return;
    final cpx = px.round();
    final cpy = py.round();
    opts.sort((a, b) {
      final d1 = (x + a[0] - cpx).abs() + (y + a[1] - cpy).abs();
      final d2 = (x + b[0] - cpx).abs() + (y + b[1] - cpy).abs();
      return powerT > 0 ? d2.compareTo(d1) : d1.compareTo(d2);
    });
    final pick = Random().nextDouble() < 0.7 ? opts.first : opts[Random().nextInt(opts.length)];
    set(x + pick[0], y + pick[1]);
  }

  void _lose() {
    gameOver = true;
    shaker.shake(duration: 0.6, intensity: 15);
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final d = info.delta.global;
    if (d.length > 3) {
      if (d.x.abs() > d.y.abs()) {
        moveDir = Vector2(d.x.sign, 0);
      } else {
        moveDir = Vector2(0, d.y.sign);
      }
    }
  }

  @override
  void onPanDown(DragDownInfo info) {

  }
}

class _MazeRenderer extends Component with HasGameReference<PacNeonGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  late double cell, ox, oy;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    cell = min(size.x / (PacNeonGame.cols + 1), (size.y - 120) / (PacNeonGame.rows + 1));
    ox = (size.x - cell * PacNeonGame.cols) / 2;
    oy = (size.y - cell * PacNeonGame.rows) / 2 + 40;
  }

  @override
  void render(Canvas canvas) {
    final g = game;
    if (cell <= 0) return;

    for (int y = 0; y < PacNeonGame.rows; y++) {
      for (int x = 0; x < PacNeonGame.cols; x++) {
        final r = Rect.fromLTWH(ox + x * cell, oy + y * cell, cell, cell);
        if (g.grid[y][x] == 1) {
          final inner = RRect.fromRectAndRadius(r.deflate(cell * 0.15), Radius.circular(cell * 0.2));
          canvas.drawRRect(inner, _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = const Color(0xFF00F5FF).withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
          canvas.drawRRect(inner, _p
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFF00F5FF));
        } else if (g.grid[y][x] == 2) {
          final pulse = 0.8 + 0.2 * sin(g._time * 8 + (x + y));
          canvas.drawCircle(r.center, cell * 0.12 * pulse, _p
            ..color = const Color(0xFF00F5FF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          canvas.drawCircle(r.center, cell * 0.05 * pulse, _p..color = Colors.white);
        } else if (g.grid[y][x] == 3) {
          final pulse = 0.7 + 0.3 * sin(g._time * 12);
          canvas.drawCircle(r.center, cell * 0.22 * pulse, _p
            ..color = const Color(0xFFFF00AA)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
          canvas.drawCircle(r.center, cell * 0.1 * pulse, _p..color = Colors.white);
        }
      }
    }


    final pc = Offset(ox + g.px * cell + cell / 2, oy + g.py * cell + cell / 2);
    canvas.save();
    canvas.translate(pc.dx, pc.dy);

    if (g.moveDir.x > 0) {
      canvas.rotate(0);
    } else if (g.moveDir.x < 0) {
      canvas.rotate(pi);
    } else if (g.moveDir.y > 0) {
      canvas.rotate(pi / 2);
    } else if (g.moveDir.y < 0) {
      canvas.rotate(-pi / 2);
    }

    canvas.drawCircle(Offset.zero, cell * 0.5, _p
      ..color = Colors.yellowAccent.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: cell * 0.45),
      g._mouthAngle,
      2 * pi - 2 * g._mouthAngle,
      true,
      _p..color = Colors.yellowAccent,
    );
    canvas.drawCircle(Offset(cell * 0.1, -cell * 0.2), cell * 0.07, _p..color = Colors.black);
    canvas.restore();


    final gc = Offset(ox + g.gx * cell + cell / 2, oy + g.gy * cell + cell / 2);
    final g2c = Offset(ox + g.g2x * cell + cell / 2, oy + g.g2y * cell + cell / 2);
    final isScared = g.powerT > 0;

    for (final c in [gc, g2c]) {
      final ghostColor = isScared ? const Color(0xFF4444FF) : const Color(0xFFFF3366);
      final alpha = (sin(g._time * 5) * 0.15 + 0.85).clamp(0.0, 1.0);
      final scarePulse = isScared ? (1.0 + 0.1 * sin(g._time * 10)) : 1.0;

      canvas.drawCircle(c, cell * 0.5, _p
        ..color = ghostColor.withValues(alpha: 0.35 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(scarePulse);

      final body = Path()
        ..moveTo(-cell * 0.4, cell * 0.4)
        ..lineTo(-cell * 0.4, -cell * 0.1)
        ..arcToPoint(Offset(cell * 0.4, -cell * 0.1), radius: Radius.circular(cell * 0.4))
        ..lineTo(cell * 0.4, cell * 0.4)
        ..lineTo(cell * 0.2, cell * 0.3)
        ..lineTo(0, cell * 0.4)
        ..lineTo(-cell * 0.2, cell * 0.3)
        ..close();
      canvas.drawPath(body, _p..color = ghostColor.withValues(alpha: alpha));

      final eyeColor = isScared ? Colors.white54 : Colors.white;
      canvas.drawCircle(const Offset(-5, -6), 4, _p..color = eyeColor);
      canvas.drawCircle(const Offset(5, -6), 4, _p..color = eyeColor);
      if (!isScared) {
        canvas.drawCircle(Offset(-5 + g.moveDir.x * 2, -6 + g.moveDir.y * 2), 2, _p..color = Colors.black);
        canvas.drawCircle(Offset(5 + g.moveDir.x * 2, -6 + g.moveDir.y * 2), 2, _p..color = Colors.black);
      }
      canvas.restore();
    }
  }
}
