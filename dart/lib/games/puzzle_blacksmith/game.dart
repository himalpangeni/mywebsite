
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../services/sensory.dart';

class PuzzleBlacksmithGame extends FlameGame {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;

  static const int rows = 12;
  static const int cols = 8;
  late double cellSize;
  late Vector2 offset;

  List<List<Color?>> grid = List.generate(rows, (_) => List.filled(cols, null));
  List<List<bool>> mold = List.generate(rows, (_) => List.filled(cols, false));

  late Tetromino currentPiece;
  double _dropTimer = 0;
  int weaponsForged = 0;
  bool isGameOver = false;
  late TextComponent scoreText;
  late Sprite logoSprite;

  final GameDifficulty difficulty;
  double speedMultiplier = 1.0;
  double _progressionTimer = 0;

  PuzzleBlacksmithGame({required this.difficulty}) : super() {
    speedMultiplier = difficulty.speedMultiplier;
  }

  @override
  Future<void> onLoad() async {
    cellSize = min(size.x / (cols + 2), size.y / (rows + 2));
    offset =
        Vector2((size.x - cols * cellSize) / 2, (size.y - rows * cellSize) / 2);
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
        if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    grid = List.generate(rows, (_) => List.filled(cols, null));

    isGameOver = false;
    weaponsForged = 0;
    _progressionTimer = 0;
    _dropTimer = 0;
    speedMultiplier = difficulty.speedMultiplier;

    add(_TouchHandler());
    _generateMold();
    _spawnPiece();

    scoreText = TextComponent(
      text: 'Forged: 0',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold)),
    );
    add(scoreText);


    add(TextComponent(
      text: 'PUZZLE BLACKSMITH',
      position: Vector2(size.x / 2, size.y * 0.45),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.orangeAccent.withValues(alpha: 0.1), fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: 6)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 50, 50),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.orangeAccent.withValues(alpha: 0.25),
    ));

    resumeEngine();
  }

  void resumeGame() {
    isGameOver = false;
    _dropTimer = 0;

    _spawnPiece();
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _generateMold() {
    mold = List.generate(rows, (_) => List.filled(cols, false));
    final random = Random();

    int startRow = rows - 5;
    int startCol = 2;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (random.nextDouble() < 0.6) mold[startRow + i][startCol + j] = true;
      }
    }
  }

  void _spawnPiece() {
    currentPiece = Tetromino.random();
    currentPiece.pos = Vector2((cols / 2).floorToDouble() - 1, 0);
    if (_checkCollision(currentPiece.pos, currentPiece.shape)) {
      gameOver();
    }
  }

  bool _checkCollision(Vector2 pos, List<List<int>> shape) {
    for (int r = 0; r < shape.length; r++) {
      for (int c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 1) {
          int gridR = (pos.y + r).toInt();
          int gridC = (pos.x + c).toInt();
          if (gridC < 0 || gridC >= cols || gridR >= rows) return true;
          if (gridR >= 0 && grid[gridR][gridC] != null) return true;
        }
      }
    }
    return false;
  }

  void _lockPiece() {
    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        if (currentPiece.shape[r][c] == 1) {
          int gridR = (currentPiece.pos.y + r).toInt();
          int gridC = (currentPiece.pos.x + c).toInt();
          if (gridR >= 0) grid[gridR][gridC] = currentPiece.color;
        }
      }
    }
    _checkClearRows();
    _checkClearColumns();
    _checkForge();
    _spawnPiece();
  }

  void _checkClearRows() {
    for (int r = rows - 1; r >= 0; r--) {
      bool full = true;
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) {

        for (int rowToShift = r; rowToShift > 0; rowToShift--) {
          grid[rowToShift] = List.from(grid[rowToShift - 1]);
        }
        grid[0] = List.filled(cols, null);
        r++;
        SensoryService.lightImpact();
      }
    }
  }

  void _checkClearColumns() {
    for (int c = 0; c < cols; c++) {
      bool full = true;
      for (int r = 0; r < rows; r++) {
        if (grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) {
        for (int r = 0; r < rows; r++) {
          grid[r][c] = null;
        }
        SensoryService.lightImpact();
      }
    }
  }

  void _checkForge() {
    bool forged = true;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (mold[r][c] && grid[r][c] == null) {
          forged = false;
          break;
        }
      }
    }
    if (forged) {
      weaponsForged++;
      scoreText.text = 'Forged: $weaponsForged';
      grid = List.generate(
          rows, (_) => List.filled(cols, null));
      _generateMold();
    }
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    _progressionTimer += dt;
    if (_progressionTimer >= 15.0) {
      _progressionTimer = 0;
      speedMultiplier += 0.2;
    }

    _dropTimer += dt;
    double dropInterval = (1.0 / speedMultiplier).clamp(0.2, 2.0);
    if (_dropTimer >= dropInterval) {
      _dropTimer = 0;
      if (!_checkCollision(
          currentPiece.pos + Vector2(0, 1), currentPiece.shape)) {
        currentPiece.pos.y += 1;
      } else {
        _lockPiece();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);


    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
        bgRect,
        _p
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF331100)],
          ).createShader(bgRect));


    final gridRect = Rect.fromLTWH(
        offset.x - 5, offset.y - 5, cols * cellSize + 10, rows * cellSize + 10);
    canvas.drawShadow(Path()..addRect(gridRect), Colors.black, 10, false);
    canvas.drawRect(gridRect, _p..color = const Color(0xFF2D2D2D));


    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(offset.x + c * cellSize,
            offset.y + r * cellSize, cellSize, cellSize);
        if (grid[r][c] != null) {
          _drawIngot(canvas, rect, grid[r][c]!);
        } else if (mold[r][c]) {
          canvas.drawRect(
              rect.deflate(2),
              _p
                ..color = Colors.orangeAccent.withValues(alpha: 0.2)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2);
          canvas.drawRect(rect.deflate(4),
              _p..color = Colors.orangeAccent.withValues(alpha: 0.1));
        } else {
          canvas.drawRect(rect.deflate(1), _p..color = Colors.black26);
        }
      }
    }

    for (int r = 0; r < currentPiece.shape.length; r++) {
      for (int c = 0; c < currentPiece.shape[r].length; c++) {
        if (currentPiece.shape[r][c] == 1) {
          final rect = Rect.fromLTWH(
              offset.x + (currentPiece.pos.x + c) * cellSize,
              offset.y + (currentPiece.pos.y + r) * cellSize,
              cellSize,
              cellSize);
          _drawIngot(canvas, rect, currentPiece.color);
        }
      }
    }


    _drawButton(canvas, 'ROTATE', Vector2(size.x / 2, size.y - 60));
    _drawButton(canvas, 'LEFT', Vector2(size.x / 2 - 100, size.y - 60));
    _drawButton(canvas, 'RIGHT', Vector2(size.x / 2 + 100, size.y - 60));
    _drawButton(canvas, 'DROP', Vector2(size.x / 2, size.y - 120));
  }

  void _drawIngot(Canvas canvas, Rect rect, Color color) {

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.lighten(0.3), color, color.darken(0.3)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)),
        paint);

    canvas.drawLine(
        Offset(rect.left + 5, rect.top + 5),
        Offset(rect.right - 5, rect.top + 5),
        Paint()
          ..color = Colors.white30
          ..strokeWidth = 2);
  }

  void _drawButton(Canvas canvas, String label, Vector2 pos) {
    final rect = Rect.fromCenter(center: pos.toOffset(), width: 80, height: 45);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = Colors.orangeAccent);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white);

    final textPainter = TextPainter(
      text: TextSpan(
          text: label,
          style: const TextStyle(
              color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas,
        pos.toOffset() - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  bool _isButtonHit(Vector2 tap, Vector2 btnPos) {
    final rect =
        Rect.fromCenter(center: btnPos.toOffset(), width: 80, height: 45);
    return rect.contains(tap.toOffset());
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }
}

class _TouchHandler extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<PuzzleBlacksmithGame> {
  _TouchHandler() : super(anchor: Anchor.topLeft);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.isGameOver) return;
    double dx = event.localDelta.x;
    if (dx.abs() > game.cellSize / 4) {
      double move = dx > 0 ? 1 : -1;
      if (!game._checkCollision(
          game.currentPiece.pos + Vector2(move, 0), game.currentPiece.shape)) {
        game.currentPiece.pos.x += move;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.isGameOver) return;
    final p = event.localPosition;


    if (game._isButtonHit(p, Vector2(game.size.x / 2, game.size.y - 60))) {

      game.currentPiece.rotate();
      if (game._checkCollision(game.currentPiece.pos, game.currentPiece.shape)) {
        game.currentPiece.rotateBack();
      }
    } else if (game._isButtonHit(
        p, Vector2(game.size.x / 2 - 100, game.size.y - 60))) {

      if (!game._checkCollision(
          game.currentPiece.pos + Vector2(-1, 0), game.currentPiece.shape)) {
        game.currentPiece.pos.x -= 1;
      }
    } else if (game._isButtonHit(
        p, Vector2(game.size.x / 2 + 100, game.size.y - 60))) {

      if (!game._checkCollision(
          game.currentPiece.pos + Vector2(1, 0), game.currentPiece.shape)) {
        game.currentPiece.pos.x += 1;
      }
    } else if (game._isButtonHit(
        p, Vector2(game.size.x / 2, game.size.y - 120))) {

      while (!game._checkCollision(
          game.currentPiece.pos + Vector2(0, 1), game.currentPiece.shape)) {
        game.currentPiece.pos.y += 1;
      }
      game._lockPiece();
    } else {

      game.currentPiece.rotate();
      if (game._checkCollision(game.currentPiece.pos, game.currentPiece.shape)) {
        game.currentPiece.rotateBack();
      }
    }
  }
}

class Tetromino {
  List<List<int>> shape;
  Color color;
  Vector2 pos = Vector2.zero();

  Tetromino({required this.shape, required this.color});

  static Tetromino random() {
    final shapes = [
      [
        [1, 1, 1, 1]
      ],
      [
        [1, 1, 1],
        [0, 1, 0]
      ],
      [
        [1, 1, 0],
        [0, 1, 1]
      ],
      [
        [0, 1, 1],
        [1, 1, 0]
      ],
      [
        [1, 1],
        [1, 1]
      ],
      [
        [1, 1, 1],
        [1, 0, 0]
      ],
      [
        [1, 1, 1],
        [0, 0, 1]
      ],
    ];
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.cyan
    ];
    final idx = Random().nextInt(shapes.length);
    return Tetromino(shape: shapes[idx], color: colors[idx]);
  }

  void rotate() {
    final newShape = List.generate(
        shape[0].length,
        (c) =>
            List.generate(shape.length, (r) => shape[shape.length - 1 - r][c]));
    shape = newShape;
  }

  void rotateBack() {
    for (int i = 0; i < 3; i++) {
      rotate();
    }
  }
}
