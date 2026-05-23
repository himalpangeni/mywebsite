import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import '../../models/difficulty.dart';

class NumberMergeGame extends FlameGame with PanDetector {

  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;

  static const int gridSize = 4;
  late List<List<int>> board;
  bool isMoving = false;

  NumberMergeGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF102218);

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
    score = 0;
    board = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    _addRandomTile();
    _addRandomTile();

    hud = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 60),
      textRenderer: TextPaint(
        style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
    add(hud);
    add(_NumberMergeRenderer());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;

    overlays.remove('GameOver');
    resumeEngine();
  }

  void _addRandomTile() {
    List<Point<int>> emptyCells = [];
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board[y][x] == 0) emptyCells.add(Point(x, y));
      }
    }
    if (emptyCells.isNotEmpty) {
      final p = emptyCells[Random().nextInt(emptyCells.length)];
      board[p.y][p.x] = Random().nextDouble() < 0.9 ? 2 : 4;
    }
  }

  void _move(Vector2 direction) {
    if (gameOver || isMoving) return;

    bool moved = false;
    int dx = direction.x.toInt();
    int dy = direction.y.toInt();


    if (dx != 0) {
      for (int y = 0; y < gridSize; y++) {
        List<int> line = board[y];
        if (dx > 0) line = line.reversed.toList();
        var result = _slide(line);
        if (dx > 0) result = result.reversed.toList();
        if (!_listsEqual(board[y], result)) {
          board[y] = result;
          moved = true;
        }
      }
    } else if (dy != 0) {
      for (int x = 0; x < gridSize; x++) {
        List<int> line = [for (int y = 0; y < gridSize; y++) board[y][x]];
        if (dy > 0) line = line.reversed.toList();
        var result = _slide(line);
        if (dy > 0) result = result.reversed.toList();
        for (int y = 0; y < gridSize; y++) {
          if (board[y][x] != result[y]) {
            board[y][x] = result[y];
            moved = true;
          }
        }
      }
    }

    if (moved) {
      _addRandomTile();
      _checkGameOver();
      hud.text = 'Score: $score';
    }
  }

  List<int> _slide(List<int> line) {
    List<int> filtered = line.where((x) => x != 0).toList();
    for (int i = 0; i < filtered.length - 1; i++) {
      if (filtered[i] == filtered[i + 1]) {
        filtered[i] *= 2;
        score += filtered[i];
        filtered[i + 1] = 0;
      }
    }
    filtered = filtered.where((x) => x != 0).toList();
    while (filtered.length < gridSize) {
      filtered.add(0);
    }
    return filtered;
  }

  bool _listsEqual(List<int> a, List<int> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _checkGameOver() {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (board[y][x] == 0) return;
        if (x < gridSize - 1 && board[y][x] == board[y][x + 1]) return;
        if (y < gridSize - 1 && board[y][x] == board[y + 1][x]) return;
      }
    }
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onPanEnd(DragEndInfo info) {
    final v = info.velocity;
    if (v.length > 100) {
      if (v.x.abs() > v.y.abs()) {
        _move(Vector2(v.x.sign, 0));
      } else {
        _move(Vector2(0, v.y.sign));
      }
    }
  }
}

class _NumberMergeRenderer extends Component with HasGameReference<NumberMergeGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    const padding = 20.0;
    final gridW = w - padding * 2;
    final cellW = gridW / NumberMergeGame.gridSize;
    final startY = (h - gridW) / 2 + 40;


    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(padding, startY, gridW, gridW),
            const Radius.circular(16)),
        _p..color = Colors.black38);

    for (int y = 0; y < NumberMergeGame.gridSize; y++) {
      for (int x = 0; x < NumberMergeGame.gridSize; x++) {
        final val = g.board[y][x];
        final rect = Rect.fromLTWH(padding + x * cellW + 4,
            startY + y * cellW + 4, cellW - 8, cellW - 8);
        _drawTile(canvas, rect, val);
      }
    }
  }

  void _drawTile(Canvas canvas, Rect r, int val) {
    final color = _getTileColor(val);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()..color = color);

    if (val > 0) {
      final tp = TextPainter(
        text: TextSpan(
            text: '$val',
            style: TextStyle(
                color: val <= 4 ? Colors.black87 : Colors.white,
                fontSize: r.width * 0.35,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
    }
  }

  Color _getTileColor(int val) {
    switch (val) {
      case 0:
        return Colors.white10;
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      default:
        return Colors.black;
    }
  }
}
