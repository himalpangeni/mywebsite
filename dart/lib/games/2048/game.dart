import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

class Game2048 extends FlameGame with PanDetector {

  final GameDifficulty difficulty;
  late List<List<int>> grid;
  int score = 0;
  bool gameOver = false;

  late TextComponent scoreText;
  late ScreenShake shaker;

  Game2048({required this.difficulty}) : super();

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    await super.onLoad();
    restart();
  }

  void restart() {
    grid = List.generate(4, (_) => List.generate(4, (_) => 0));
    score = 0;
    gameOver = false;
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');


    _addTile();
    _addTile();

    scoreText = TextComponent(
      text: 'SCORE: 0',
      position: Vector2(size.x / 2, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)]),
      ),
    );
    add(scoreText);

    add(CinematicOverlay());
    shaker = ScreenShake();
    add(shaker);
    add(_GridRenderer());

    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _addTile() {
    List<Point<int>> empty = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (grid[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isNotEmpty) {
      final p = empty[Random().nextInt(empty.length)];
      grid[p.x][p.y] = Random().nextDouble() < 0.9 ? 2 : 4;
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (gameOver) return;
    final vel = info.velocity;
    bool moved = false;

    if (vel.x.abs() > vel.y.abs()) {
      if (vel.x > 0) {
        moved = _moveRight();
      } else {
        moved = _moveLeft();
      }
    } else {
      if (vel.y > 0) {
        moved = _moveDown();
      } else {
        moved = _moveUp();
      }
    }

    if (moved) {
      _addTile();
      shaker.shake(duration: 0.1, intensity: 2);
      scoreText.text = 'SCORE: $score';
      if (_checkGameOver()) {
        gameOver = true;
        shaker.shake(duration: 0.5, intensity: 10);
        overlays.add('GameOver');
      }
    }
  }

  bool _moveLeft() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      List<int> row = grid[r].where((e) => e != 0).toList();
      for (int i = 0; i < row.length - 1; i++) {
        if (row[i] == row[i + 1]) {
          row[i] *= 2;
          score += row[i];
          row.removeAt(i + 1);
          moved = true;
        }
      }
      while (row.length < 4) {
        row.add(0);
      }
      if (!const ListEquality().equals(grid[r], row)) moved = true;
      grid[r] = row;
    }
    return moved;
  }

  bool _moveRight() {
    bool moved = false;
    for (int r = 0; r < 4; r++) {
      List<int> row = grid[r].where((e) => e != 0).toList();
      for (int i = row.length - 1; i > 0; i--) {
        if (row[i] == row[i - 1]) {
          row[i] *= 2;
          score += row[i];
          row.removeAt(i - 1);
          moved = true;
          i--;
        }
      }
      while (row.length < 4) {
        row.insert(0, 0);
      }
      if (!const ListEquality().equals(grid[r], row)) moved = true;
      grid[r] = row;
    }
    return moved;
  }

  bool _moveUp() {
    bool moved = false;
    for (int c = 0; c < 4; c++) {
      List<int> col = [for (int r = 0; r < 4; r++) grid[r][c]]
          .where((e) => e != 0)
          .toList();
      for (int i = 0; i < col.length - 1; i++) {
        if (col[i] == col[i + 1]) {
          col[i] *= 2;
          score += col[i];
          col.removeAt(i + 1);
          moved = true;
        }
      }
      while (col.length < 4) {
        col.add(0);
      }
      for (int r = 0; r < 4; r++) {
        if (grid[r][c] != col[r]) moved = true;
        grid[r][c] = col[r];
      }
    }
    return moved;
  }

  bool _moveDown() {
    bool moved = false;
    for (int c = 0; c < 4; c++) {
      List<int> col = [for (int r = 0; r < 4; r++) grid[r][c]]
          .where((e) => e != 0)
          .toList();
      for (int i = col.length - 1; i > 0; i--) {
        if (col[i] == col[i - 1]) {
          col[i] *= 2;
          score += col[i];
          col.removeAt(i - 1);
          moved = true;
          i--;
        }
      }
      while (col.length < 4) {
        col.insert(0, 0);
      }
      for (int r = 0; r < 4; r++) {
        if (grid[r][c] != col[r]) moved = true;
        grid[r][c] = col[r];
      }
    }
    return moved;
  }

  bool _checkGameOver() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (grid[r][c] == 0) return false;
        if (r < 3 && grid[r][c] == grid[r + 1][c]) return false;
        if (c < 3 && grid[r][c] == grid[r][c + 1]) return false;
      }
    }
    return true;
  }
}

class _GridRenderer extends Component with HasGameReference<Game2048> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final bs = min(w, g.size.y) * 0.9;
    final start = Vector2((w - bs) / 2, (g.size.y - bs) / 2);
    final cs = bs / 4;


    final bgRect = Rect.fromLTWH(start.x, start.y, bs, bs);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(20)),
        _p..color = const Color(0xFF16213E));
    canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(20)),
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.cyanAccent.withValues(alpha: 0.3));

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final val = g.grid[r][c];
        final rect = Rect.fromLTWH(start.x + c * cs, start.y + r * cs, cs, cs)
            .deflate(6);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));


        canvas.drawRRect(
            rr, _p..color = Colors.white.withValues(alpha: 0.05));

        if (val != 0) {
          final color = _getTileColor(val);

          canvas.drawRRect(rr, _p..color = color.withValues(alpha: 0.8));
          canvas.drawRRect(
              rr,
              _p
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.white24);


          canvas.drawRRect(
              rr,
              _p
                ..color = color.withValues(alpha: 0.2)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

          final tp = TextPainter(
              text: TextSpan(
                  text: '$val',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: cs * 0.35,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4)
                      ])),
              textDirection: TextDirection.ltr)
            ..layout();
          tp.paint(
              canvas,
              Offset(start.x + c * cs + cs / 2 - tp.width / 2,
                  start.y + r * cs + cs / 2 - tp.height / 2));
        }
      }
    }
  }

  Color _getTileColor(int v) {
    switch (v) {
      case 2:
        return const Color(0xFF00D2FF);
      case 4:
        return const Color(0xFF3A7BD5);
      case 8:
        return const Color(0xFF6A11CB);
      case 16:
        return const Color(0xFF2575FC);
      case 32:
        return const Color(0xFFFF4B2B);
      case 64:
        return const Color(0xFFFF416C);
      case 128:
        return const Color(0xFFFDC830);
      case 256:
        return const Color(0xFFF37335);
      case 512:
        return const Color(0xFF00C9FF);
      case 1024:
        return const Color(0xFF92FE9D);
      case 2048:
        return Colors.cyanAccent;
      default:
        return Colors.blueGrey;
    }
  }
}
