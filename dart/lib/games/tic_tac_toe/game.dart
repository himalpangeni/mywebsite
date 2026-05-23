import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

enum CellState { empty, x, o }

class TicTacToeGame extends FlameGame with TapCallbacks {
  late final Random _random;
  final GameDifficulty difficulty;
  final CellState playerSide;
  final bool isVsBot;

  late List<CellState> board;
  bool isPlayerTurn = true;
  bool isGameOver = false;
  CellState? winner;
  List<int>? winningCombination;
  String status = "";
  int _gameSession = 0;

  late TextComponent statusText;
  late ScreenShake shaker;

  TicTacToeGame(
      {required this.difficulty,
      required this.playerSide,
      required this.isVsBot})
      : super();

  double get boardSize => min(size.x, size.y) * 0.85;
  Vector2 get boardOrigin =>
      Vector2((size.x - boardSize) / 2, (size.y - boardSize) / 2);

  @override
  Future<void> onLoad() async {
    _random = Random();
    await super.onLoad();
    restart();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    overlays.remove('GameOver');

    _gameSession++;
    board = List.generate(9, (_) => CellState.empty);
    isGameOver = false;
    isPlayerTurn = playerSide == CellState.x;
    status = isPlayerTurn ? "YOUR TURN" : "OPPONENT TURN";

    statusText = TextComponent(
      text: status,
      position: Vector2(size.x / 2, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
            color: Colors.cyanAccent.withValues(alpha: 0.9),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            shadows: const [Shadow(color: Colors.cyanAccent, blurRadius: 10)]),
      ),
    );
    add(statusText);

    add(CinematicOverlay());
    shaker = ScreenShake();
    add(shaker);
    add(GridPainter());

    if (!isPlayerTurn && isVsBot) {
      _makeBotMove();
    }
    resumeEngine();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver || !isPlayerTurn) return;

    final lp = event.localPosition;
    final rel = lp - boardOrigin;
    if (rel.x < 0 || rel.y < 0 || rel.x > boardSize || rel.y > boardSize) {
      return;
    }

    final cellSize = boardSize / 3;
    final x = (rel.x / cellSize).floor();
    final y = (rel.y / cellSize).floor();
    final index = y * 3 + x;

    if (board[index] == CellState.empty) {
      _makeMove(index, playerSide);
    }
  }

  void _makeMove(int index, CellState side) {
    board[index] = side;
    add(SymbolComponent(
        side: side, position: _cellCenter(index), cellSize: boardSize / 3));
    shaker.shake(duration: 0.1, intensity: 3);

    final winCombo = _getWinningCombination(side);
    if (winCombo != null) {
      winner = side;
      winningCombination = winCombo;
      add(WinningLineComponent(
          indices: winCombo, boardOrigin: boardOrigin, boardSize: boardSize));
      _endGame("${side.toString().split('.').last.toUpperCase()} WINS!");
    } else if (!board.contains(CellState.empty)) {
      winner = null;
      _endGame("DRAW!");
    } else {
      isPlayerTurn = !isPlayerTurn;
      status = isPlayerTurn ? "YOUR TURN" : "OPPONENT TURN";
      statusText.text = status;
      if (!isPlayerTurn && isVsBot) _makeBotMove();
    }
  }

  void _makeBotMove() {
    final session = _gameSession;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (isGameOver || _gameSession != session) return;
      int move = (difficulty == GameDifficulty.hard)
          ? _getBestMove()
          : _getRandomMove();
      if (move != -1 && _gameSession == session) {
        _makeMove(move, playerSide == CellState.x ? CellState.o : CellState.x);
      }
    });
  }

  int _getRandomMove() {
    final empty = [
      for (int i = 0; i < 9; i++)
        if (board[i] == CellState.empty) i
    ];
    return empty.isEmpty ? -1 : empty[_random.nextInt(empty.length)];
  }

  int _getBestMove() {
    int bestVal = -1000;
    int bestMove = -1;

    for (int i = 0; i < 9; i++) {
      if (board[i] == CellState.empty) {
        board[i] = (playerSide == CellState.x ? CellState.o : CellState.x);
        int moveVal = _minimax(0, false);
        board[i] = CellState.empty;
        if (moveVal > bestVal) {
          bestMove = i;
          bestVal = moveVal;
        }
      }
    }
    return bestMove;
  }

  int _minimax(int depth, bool isMax) {
    final botSide = (playerSide == CellState.x ? CellState.o : CellState.x);
    final winBot = _getWinningCombination(botSide);
    if (winBot != null) return 10 - depth;
    final winPlayer = _getWinningCombination(playerSide);
    if (winPlayer != null) return depth - 10;
    if (!board.contains(CellState.empty)) return 0;

    if (isMax) {
      int best = -1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == CellState.empty) {
          board[i] = botSide;
          best = max(best, _minimax(depth + 1, false));
          board[i] = CellState.empty;
        }
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == CellState.empty) {
          board[i] = playerSide;
          best = min(best, _minimax(depth + 1, true));
          board[i] = CellState.empty;
        }
      }
      return best;
    }
  }

  List<int>? _getWinningCombination(CellState side) {
    const wins = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];
    for (var w in wins) {
      if (w.every((i) => board[i] == side)) return w;
    }
    return null;
  }

  void _endGame(String msg) {
    isGameOver = true;
    statusText.text = msg;
    shaker.shake(duration: 0.6, intensity: 10);
    overlays.add('GameOver');
  }

  Vector2 _cellCenter(int index) {
    final cell = boardSize / 3;
    return boardOrigin +
        Vector2((index % 3) * cell + cell / 2, (index ~/ 3) * cell + cell / 2);
  }
}

class GridPainter extends Component with HasGameReference<TicTacToeGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final origin = g.boardOrigin;
    final bs = g.boardSize;
    final cell = bs / 3;

    final paint = _p
      ..color = Colors.cyanAccent.withValues(alpha: 0.85)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.save();
    canvas.translate(origin.x, origin.y);

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, bs, bs), const Radius.circular(20)),
        paint);


    canvas.drawLine(Offset(cell, 10), Offset(cell, bs - 10), paint);
    canvas.drawLine(Offset(cell * 2, 10), Offset(cell * 2, bs - 10), paint);
    canvas.drawLine(Offset(10, cell), Offset(bs - 10, cell), paint);
    canvas.drawLine(Offset(10, cell * 2), Offset(bs - 10, cell * 2), paint);
    canvas.restore();
  }
}

class SymbolComponent extends PositionComponent {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  final CellState side;
  double animation = 0;

  SymbolComponent(
      {required this.side, required Vector2 position, required double cellSize})
      : super(
            position: position,
            size: Vector2.all(cellSize * 0.65),
            anchor: Anchor.center);

  @override
  void update(double dt) {
    animation = (animation + dt * 3).clamp(0, 1);
  }

  @override
  void render(Canvas canvas) {
    final paint = _p
      ..color = side == CellState.x ? Colors.cyanAccent : Colors.pinkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);

    if (side == CellState.x) {

      if (animation < 0.5) {
        double p = animation * 2;
        canvas.drawLine(Offset.zero, Offset(size.x * p, size.y * p), paint);
      } else {
        canvas.drawLine(Offset.zero, Offset(size.x, size.y), paint);
        double p = (animation - 0.5) * 2;
        canvas.drawLine(Offset(size.x, 0),
            Offset(size.x - (size.x * p), size.y * p), paint);
      }
    } else {

      canvas.drawArc(Rect.fromLTWH(0, 0, size.x, size.y), -pi / 2,
          2 * pi * animation, false, paint);
    }
  }
}

class WinningLineComponent extends PositionComponent {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  final List<int> indices;
  final Vector2 boardOrigin;
  final double boardSize;
  double animation = 0;

  WinningLineComponent(
      {required this.indices,
      required this.boardOrigin,
      required this.boardSize})
      : super(size: Vector2.all(boardSize));

  @override
  void update(double dt) {
    animation = (animation + dt * 2.5).clamp(0, 1);
  }

  @override
  void render(Canvas canvas) {
    if (indices.length < 3) return;
    final cellSize = boardSize / 3;
    final start = _getCenter(indices[0], cellSize);
    final end = _getCenter(indices[2], cellSize);

    final paint = _p
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final currentEnd = Offset.lerp(start, end, animation)!;
    canvas.drawLine(start, currentEnd, paint);
    canvas.drawLine(
        start,
        currentEnd,
        _p
          ..color = Colors.white70
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
  }

  Offset _getCenter(int index, double cellSize) {
    return Offset(
      boardOrigin.x + (index % 3) * cellSize + cellSize / 2,
      boardOrigin.y + (index ~/ 3) * cellSize + cellSize / 2,
    );
  }
}
