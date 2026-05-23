
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

enum PieceType { pawn, knight, bishop, rook, queen, king }

enum PieceColor { white, black }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  bool hasMoved;
  ChessPiece({required this.type, required this.color, this.hasMoved = false});

  ChessPiece clone() =>
      ChessPiece(type: type, color: color, hasMoved: hasMoved);

  String get symbol {
    const whiteSymbols = {
      PieceType.pawn: '♙',
      PieceType.knight: '♘',
      PieceType.bishop: '♗',
      PieceType.rook: '♖',
      PieceType.queen: '♕',
      PieceType.king: '♔',
    };
    const blackSymbols = {
      PieceType.pawn: '♟',
      PieceType.knight: '♞',
      PieceType.bishop: '♝',
      PieceType.rook: '♜',
      PieceType.queen: '♛',
      PieceType.king: '♚',
    };
    return color == PieceColor.white
        ? whiteSymbols[type]!
        : blackSymbols[type]!;
  }
}

class ChessMove {
  final int from;
  final int to;
  final bool isCastling;
  final PieceType? promotion;
  ChessMove(this.from, this.to, {this.isCastling = false, this.promotion});
}

class ChessGame extends FlameGame with TapCallbacks {
  final GameDifficulty difficulty;
  final bool vsBot;
  final bool playerIsWhite;

  bool whiteToMove = true;
  bool gameOver = false;
  bool botThinking = false;
  String status = 'White to move';
  String result = '';
  int selectedIndex = -1;
  List<int> legalMoves = [];
  List<BoardState> moveHistory = [];
  List<ChessPiece?> board = List.filled(64, null);
  int? enPassantTarget;
  bool boardFlipped = false;

  late TextComponent hud;
  late TextComponent infoText;
  late TextComponent capturedText;
  late ScreenShake shaker;

  static const values = {
    PieceType.pawn: 100,
    PieceType.knight: 320,
    PieceType.bishop: 330,
    PieceType.rook: 500,
    PieceType.queen: 900,
    PieceType.king: 10000,
  };

  ChessGame(
      {required this.difficulty,
      required this.vsBot,
      required this.playerIsWhite}) {
    boardFlipped = vsBot && !playerIsWhite;
  }

  @override
  Color backgroundColor() => const Color(0xFF121B22);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    await super.onLoad();
    shaker = ScreenShake();
    add(shaker);
    restart();
  }

  void restart() {
    gameOver = false;
    botThinking = false;
    whiteToMove = true;
    selectedIndex = -1;
    legalMoves = [];
    enPassantTarget = null;
    moveHistory.clear();
    result = '';
    status = 'White to move';

    board = List.filled(64, null);
    _setupBoard();

    removeAll(children
        .where((c) => c is! ScreenShake && c is! CinematicOverlay)
        .toList());
    
    camera.viewfinder.anchor = Anchor.topLeft;

    add(hud = TextComponent(
      text: status,
      position: Vector2(size.x / 2, 28),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 10)]),
      ),
    ));
    add(infoText = TextComponent(
      text: vsBot
          ? (playerIsWhite
              ? 'You are White • Bot is Black'
              : 'You are Black • Bot is White')
          : 'Local 2‑player',
      position: Vector2(size.x / 2, 58),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
            color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ));
    add(capturedText = TextComponent(
      text: _getCapturedDisplay(),
      position: Vector2(size.x - 20, 28),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ));
    add(CinematicOverlay());
    add(_ChessRenderer(this));

    resumeEngine();
    overlays.remove('GameOver');
    overlays.add('ChessControls');
    
    if (vsBot && whiteToMove != playerIsWhite) {
      _scheduleBotMove();
    }
  }

  void resumeGame() {
    if (moveHistory.isNotEmpty) {
      undoLastMove();
    }
    gameOver = false;
    overlays.remove('GameOver');
    resumeEngine();
  }

  String _getCapturedDisplay() {

    int whiteMissing = 0, blackMissing = 0;
    List<ChessPiece?> initial = List.filled(64, null);
    const backRank = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook
    ];
    for (int i = 0; i < 8; i++) {
      initial[8 + i] =
          ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      initial[48 + i] =
          ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      initial[i] = ChessPiece(type: backRank[i], color: PieceColor.black);
      initial[56 + i] = ChessPiece(type: backRank[i], color: PieceColor.white);
    }
    for (int i = 0; i < 64; i++) {
      if (initial[i] != null && board[i] == null) {
        if (initial[i]!.color == PieceColor.white) {
          whiteMissing++;
        } else {
          blackMissing++;
        }
      }
    }
    return '⚪ $whiteMissing  ⚫ $blackMissing';
  }

  void _setupBoard() {
    const backRank = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook
    ];
    for (int file = 0; file < 8; file++) {
      board[8 + file] =
          ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      board[48 + file] =
          ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[file] = ChessPiece(type: backRank[file], color: PieceColor.black);
      board[56 + file] =
          ChessPiece(type: backRank[file], color: PieceColor.white);
    }
  }



  void _scheduleBotMove() {
    if (botThinking || gameOver) return;
    botThinking = true;
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (gameOver || whiteToMove == playerIsWhite) {
        botThinking = false;
        return;
      }
      await _performBotMove();
      botThinking = false;
    });
  }

  Future<void> _performBotMove() async {
    final botColor = whiteToMove ? PieceColor.white : PieceColor.black;
    final moves = _allLegalMoves(botColor);
    if (moves.isEmpty) {
      _updateGameState();
      return;
    }

    final args = _BotMoveArgs(
      board.map((p) => p?.clone()).toList(),
      difficulty,
      botColor,
      enPassantTarget,
    );

    final choice = await compute(_calculateBotMoveIsolate, args);

    if (!gameOver) {
      _makeMove(choice);
    }
  }



  static int _minimax(List<ChessPiece?> boardState, int depth, int alpha, int beta,
      bool isMaximizing, PieceColor botColor, int? epTarget) {
    if (depth == 0) {
      return _evaluateBoardAdvanced(boardState, botColor);
    }

    final currentColor = isMaximizing ? botColor : _opponent(botColor);
    final moves = _allLegalMovesOnBoard(currentColor, boardState, epTarget);

    if (moves.isEmpty) {

      if (_isKingInCheckOnBoard(currentColor, boardState, epTarget)) {
        return isMaximizing ? -100000 + (4 - depth) * 1000 : 100000 - (4 - depth) * 1000;
      }
      return 0;
    }

    if (isMaximizing) {
      int maxEval = -999999;
      for (final move in moves) {
        final sim = _simulateMoveOnBoard(move, boardState);
        final newEp = _getNewEpTarget(move, boardState);
        final eval = _minimax(sim, depth - 1, alpha, beta, false, botColor, newEp);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (final move in moves) {
        final sim = _simulateMoveOnBoard(move, boardState);
        final newEp = _getNewEpTarget(move, boardState);
        final eval = _minimax(sim, depth - 1, alpha, beta, true, botColor, newEp);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  static int? _getNewEpTarget(ChessMove move, List<ChessPiece?> boardState) {
    final piece = boardState[move.from];
    if (piece == null || piece.type != PieceType.pawn) return null;
    final fromRank = _rank(move.from);
    final toRank = _rank(move.to);
    if ((piece.color == PieceColor.white && fromRank == 6 && toRank == 4) ||
        (piece.color == PieceColor.black && fromRank == 1 && toRank == 3)) {
      return move.from + (piece.color == PieceColor.white ? -8 : 8);
    }
    return null;
  }

  static List<ChessPiece?> _simulateMoveOnBoard(ChessMove move, List<ChessPiece?> boardState) {
    final clone = boardState.map((p) => p?.clone()).toList();
    final piece = clone[move.from];
    if (piece == null) return clone;
    clone[move.to] = ChessPiece(
        type: move.promotion ?? piece.type, color: piece.color, hasMoved: true);
    clone[move.from] = null;


    if (piece.type == PieceType.pawn && (_rank(move.to) == 0 || _rank(move.to) == 7)) {
      clone[move.to] = ChessPiece(type: PieceType.queen, color: piece.color, hasMoved: true);
    }

    if (move.isCastling) {
      if (move.to == 62) { clone[61] = clone[63]; clone[63] = null; }
      else if (move.to == 58) { clone[59] = clone[56]; clone[56] = null; }
      else if (move.to == 6) { clone[5] = clone[7]; clone[7] = null; }
      else if (move.to == 2) { clone[3] = clone[0]; clone[0] = null; }
    }
    return clone;
  }


  List<ChessPiece?> _simulateMove(ChessMove move) => _simulateMoveOnBoard(move, board);

  int _evaluateBoard(List<ChessPiece?> boardState, PieceColor color) {
    int score = 0;
    for (var piece in boardState) {
      if (piece == null) continue;
      final value = values[piece.type]!;
      score += piece.color == color ? value : -value;
    }
    return score;
  }

  static List<ChessMove> _allLegalMovesOnBoard(PieceColor color, List<ChessPiece?> boardState, int? epTarget) {
    final moves = <ChessMove>[];
    for (int i = 0; i < 64; i++) {
      final piece = boardState[i];
      if (piece == null || piece.color != color) continue;
      for (final move in _pseudoLegalMovesForBoard(i, boardState, epTarget: epTarget, ignoreKingSafety: false)) {
        final clone = _simulateMoveOnBoard(move, boardState);
        final newEp = _getNewEpTarget(move, boardState);
        if (!_isKingInCheckOnBoard(color, clone, newEp)) {
          moves.add(move);
        }
      }
    }
    return moves;
  }


  static const _pawnTable = [
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0,
  ];

  static const _knightTable = [
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  5, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  0,-30,
    -30,  5, 10, 15, 15, 10,  5,-30,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50,
  ];

  static const _bishopTable = [
    -20,-10,-10,-10,-10,-10,-10,-20,
    -10,  0,  0,  0,  0,  0,  0,-10,
    -10,  0, 10, 10, 10, 10,  0,-10,
    -10,  5,  5, 10, 10,  5,  5,-10,
    -10,  0, 10, 10, 10, 10,  0,-10,
    -10, 10, 10, 10, 10, 10, 10,-10,
    -10,  5,  0,  0,  0,  0,  5,-10,
    -20,-10,-10,-10,-10,-10,-10,-20,
  ];

  static const _rookTable = [
     0,  0,  0,  0,  0,  0,  0,  0,
     5, 10, 10, 10, 10, 10, 10,  5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
    -5,  0,  0,  0,  0,  0,  0, -5,
     0,  0,  0,  5,  5,  0,  0,  0,
  ];

  static const _queenTable = [
    -20,-10,-10, -5, -5,-10,-10,-20,
    -10,  0,  0,  0,  0,  0,  0,-10,
    -10,  0,  5,  5,  5,  5,  0,-10,
     -5,  0,  5,  5,  5,  5,  0, -5,
      0,  0,  5,  5,  5,  5,  0, -5,
    -10,  5,  5,  5,  5,  5,  0,-10,
    -10,  0,  5,  0,  0,  0,  0,-10,
    -20,-10,-10, -5, -5,-10,-10,-20,
  ];

  static const _kingTable = [
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30,
    -20,-30,-30,-40,-40,-30,-30,-20,
    -10,-20,-20,-20,-20,-20,-20,-10,
     20, 20,  0,  0,  0,  0, 20, 20,
     20, 30, 10,  0,  0, 10, 30, 20,
  ];

  static const Map<PieceType, List<int>> _psTables = {
    PieceType.pawn: _pawnTable,
    PieceType.knight: _knightTable,
    PieceType.bishop: _bishopTable,
    PieceType.rook: _rookTable,
    PieceType.queen: _queenTable,
    PieceType.king: _kingTable,
  };

  static int _evaluateBoardAdvanced(List<ChessPiece?> boardState, PieceColor botColor) {
    int score = 0;
    for (int i = 0; i < 64; i++) {
      final piece = boardState[i];
      if (piece == null) continue;
      final materialValue = values[piece.type]!;

      final psIndex = piece.color == PieceColor.white ? i : 63 - i;
      final positionalValue = _psTables[piece.type]![psIndex];
      final totalValue = materialValue + positionalValue;
      score += piece.color == botColor ? totalValue : -totalValue;
    }
    return score;
  }


  void _makeMove(ChessMove move) async {
    final piece = board[move.from];
    if (piece == null) return;


    moveHistory.add(BoardState(
      board: board.map((p) => p?.clone()).toList(),
      enPassantTarget: enPassantTarget,
      whiteToMove: whiteToMove,
    ));

    final isPawn = piece.type == PieceType.pawn;
    final targetRank = _rank(move.to);
    enPassantTarget = null;

    if (move.isCastling) {
      board[move.to] =
          ChessPiece(type: piece.type, color: piece.color, hasMoved: true);
      board[move.from] = null;
      if (move.to == 62) {
        board[61] = board[63];
        board[63] = null;
      } else if (move.to == 58) {
        board[59] = board[56];
        board[56] = null;
      } else if (move.to == 6) {
        board[5] = board[7];
        board[7] = null;
      } else if (move.to == 2) {
        board[3] = board[0];
        board[0] = null;
      }
    } else {
      if (piece.type == PieceType.pawn && move.to == enPassantTarget) {
        final capturedIdx =
            move.to + (piece.color == PieceColor.white ? 8 : -8);
        board[capturedIdx] = null;
      }
      board[move.to] = ChessPiece(
          type: move.promotion ?? piece.type,
          color: piece.color,
          hasMoved: true);
      board[move.from] = null;

      if (piece.type == PieceType.pawn &&
          (targetRank == 0 || targetRank == 7)) {

        board[move.to] = ChessPiece(
            type: PieceType.queen, color: piece.color, hasMoved: true);
      }

      if (isPawn) {
        final fromRank = _rank(move.from);
        if ((piece.color == PieceColor.white &&
                fromRank == 6 &&
                targetRank == 4) ||
            (piece.color == PieceColor.black &&
                fromRank == 1 &&
                targetRank == 3)) {
          enPassantTarget =
              move.from + (piece.color == PieceColor.white ? -8 : 8);
        }
      }
    }

    selectedIndex = -1;
    legalMoves = [];
    _toggleTurn();
    _updateGameState();


    if (vsBot && !gameOver && whiteToMove != playerIsWhite) {
      _scheduleBotMove();
    }
  }

  void _toggleTurn() {
    whiteToMove = !whiteToMove;
    status = whiteToMove ? 'White to move' : 'Black to move';
  }

  void _updateGameState() {
    final currentColor = whiteToMove ? PieceColor.white : PieceColor.black;
    final available = _allLegalMoves(currentColor);
    final inCheck = _isKingInCheck(currentColor);
    if (available.isEmpty) {
      gameOver = true;
      if (inCheck) {
        result = '${whiteToMove ? 'White' : 'Black'} is checkmated';
      } else {
        result = 'Stalemate';
      }
      status = 'Game over';
      overlays.add('GameOver');
    } else if (inCheck) {
      status = '${whiteToMove ? 'White' : 'Black'} in check';
    }
    hud.text = status;
    capturedText.text = _getCapturedDisplay();
  }

  List<ChessMove> _allLegalMoves(PieceColor color) {
    final moves = <ChessMove>[];
    for (int i = 0; i < 64; i++) {
      final piece = board[i];
      if (piece == null || piece.color != color) continue;
      for (final move in _pseudoLegalMoves(i)) {
        final clone = _simulateMove(move);
        final newEp = _getNewEpTarget(move, board);
        if (!_isKingInCheckOnBoard(color, clone, newEp)) {
          moves.add(move);
        }
      }
    }
    return moves;
  }

  List<int> _legalTargets(int from) {
    final piece = board[from];
    if (piece == null) return [];
    final result = <int>[];
    for (final move in _allLegalMoves(piece.color)) {
      if (move.from == from) result.add(move.to);
    }
    return result;
  }

  bool _isKingInCheck(PieceColor color) => _isKingInCheckOnBoard(color, board, enPassantTarget);

  static bool _isKingInCheckOnBoard(PieceColor color, List<ChessPiece?> boardState, int? epTarget) {
    final kingIndex = boardState.indexWhere(
        (p) => p != null && p.type == PieceType.king && p.color == color);
    if (kingIndex < 0) return false;
    return _squareAttacked(kingIndex, _opponent(color), boardState, epTarget);
  }

  static PieceColor _opponent(PieceColor color) =>
      color == PieceColor.white ? PieceColor.black : PieceColor.white;

  static bool _squareAttacked(
      int square, PieceColor byColor, List<ChessPiece?> boardState, int? epTarget) {
    for (int i = 0; i < 64; i++) {
      final piece = boardState[i];
      if (piece == null || piece.color != byColor) continue;
      final pseudo =
          _pseudoLegalMovesForBoard(i, boardState, epTarget: epTarget, ignoreKingSafety: true);
      if (pseudo.any((move) => move.to == square)) return true;
    }
    return false;
  }

  List<ChessMove> _pseudoLegalMoves(int from) =>
      _pseudoLegalMovesForBoard(from, board, epTarget: enPassantTarget, ignoreKingSafety: false);

  static List<ChessMove> _pseudoLegalMovesForBoard(
      int from, List<ChessPiece?> boardState,
      {int? epTarget, required bool ignoreKingSafety}) {
    final piece = boardState[from];
    if (piece == null) return [];
    final moves = <ChessMove>[];
    final file = _file(from);
    final rank = _rank(from);
    final forward = piece.color == PieceColor.white ? -1 : 1;
    final opponent = _opponent(piece.color);

    bool isEmpty(int idx) => boardState[idx] == null;
    bool hasEnemy(int idx) =>
        boardState[idx] != null && boardState[idx]!.color == opponent;

    switch (piece.type) {
      case PieceType.pawn:
        final oneStep = _index(file, rank + forward);
        if (_inBoard(file, rank + forward) && isEmpty(oneStep)) {
          moves.add(ChessMove(from, oneStep));
          final startRank = piece.color == PieceColor.white ? 6 : 1;
          final twoStep = _index(file, rank + 2 * forward);
          if (rank == startRank && isEmpty(twoStep) && isEmpty(oneStep)) {
            moves.add(ChessMove(from, twoStep));
          }
        }
        for (final dx in [-1, 1]) {
          final tx = file + dx;
          final ty = rank + forward;
          if (_inBoard(tx, ty)) {
            final idx = _index(tx, ty);
            if (hasEnemy(idx)) {
              moves.add(ChessMove(from, idx));
            } else if (epTarget != null && idx == epTarget) {
              moves.add(ChessMove(from, idx));
            }
          }
        }
        break;
      case PieceType.knight:
        for (final d in const [
          [1, 2],
          [2, 1],
          [-1, 2],
          [-2, 1],
          [1, -2],
          [2, -1],
          [-1, -2],
          [-2, -1]
        ]) {
          final tx = file + d[0];
          final ty = rank + d[1];
          if (!_inBoard(tx, ty)) continue;
          final idx = _index(tx, ty);
          if (boardState[idx] == null || boardState[idx]!.color == opponent) {
            moves.add(ChessMove(from, idx));
          }
        }
        break;
      case PieceType.bishop:
      case PieceType.rook:
      case PieceType.queen:
        final directions = <List<int>>[];
        if (piece.type == PieceType.bishop || piece.type == PieceType.queen) {
          directions.addAll(const [
            [1, 1],
            [1, -1],
            [-1, 1],
            [-1, -1]
          ]);
        }
        if (piece.type == PieceType.rook || piece.type == PieceType.queen) {
          directions.addAll(const [
            [1, 0],
            [-1, 0],
            [0, 1],
            [0, -1]
          ]);
        }
        for (final d in directions) {
          var tx = file + d[0];
          var ty = rank + d[1];
          while (_inBoard(tx, ty)) {
            final idx = _index(tx, ty);
            if (boardState[idx] == null) {
              moves.add(ChessMove(from, idx));
            } else {
              if (boardState[idx]!.color == opponent) {
                moves.add(ChessMove(from, idx));
              }
              break;
            }
            tx += d[0];
            ty += d[1];
          }
        }
        break;
      case PieceType.king:
        for (final d in const [
          [1, 1],
          [1, 0],
          [1, -1],
          [-1, 1],
          [-1, 0],
          [-1, -1],
          [0, 1],
          [0, -1]
        ]) {
          final tx = file + d[0];
          final ty = rank + d[1];
          if (!_inBoard(tx, ty)) continue;
          final idx = _index(tx, ty);
          if (boardState[idx] == null || boardState[idx]!.color == opponent) {
            moves.add(ChessMove(from, idx));
          }
        }
        if (!piece.hasMoved && !ignoreKingSafety) {
          final castlingRank = piece.color == PieceColor.white ? 7 : 0;
          if (rank == castlingRank && file == 4) {
            final kingsideRookIndex = _index(7, castlingRank);
            final queensideRookIndex = _index(0, castlingRank);
            if (_canCastle(from, kingsideRookIndex, boardState, epTarget)) {
              moves.add(
                  ChessMove(from, _index(6, castlingRank), isCastling: true));
            }
            if (_canCastle(from, queensideRookIndex, boardState, epTarget)) {
              moves.add(
                  ChessMove(from, _index(2, castlingRank), isCastling: true));
            }
          }
        }
        break;
    }
    return moves;
  }

  static bool _canCastle(int kingFrom, int rookIndex, List<ChessPiece?> boardState, int? epTarget) {
    final king = boardState[kingFrom];
    final rook = boardState[rookIndex];
    if (king == null || rook == null) return false;
    if (king.hasMoved || rook.hasMoved) return false;
    if (king.type != PieceType.king || rook.type != PieceType.rook) {
      return false;
    }
    if (king.color != rook.color) return false;
    final rank = _rank(kingFrom);
    final file = _file(kingFrom);
    final direction = rookIndex > kingFrom ? 1 : -1;
    final between = <int>[];
    for (int f = file + direction; f != _file(rookIndex); f += direction) {
      between.add(_index(f, rank));
    }
    for (final idx in between) {
      if (boardState[idx] != null) return false;
    }
    for (int f = file; f != file + direction * 3; f += direction) {
      final idx = _index(f, rank);
      if (_squareAttacked(idx, _opponent(king.color), boardState, epTarget)) return false;
    }
    return true;
  }


  void undoLastMove() {
    if (gameOver) return;
    if (moveHistory.isEmpty) return;
    final last = moveHistory.removeLast();
    board = last.board.map((p) => p?.clone()).toList();
    enPassantTarget = last.enPassantTarget;
    whiteToMove = last.whiteToMove;
    selectedIndex = -1;
    legalMoves = [];
    status = whiteToMove ? 'White to move' : 'Black to move';
    hud.text = status;
    capturedText.text = _getCapturedDisplay();

    botThinking = false;

    if (vsBot && whiteToMove != playerIsWhite && !gameOver) {
      _scheduleBotMove();
    }
  }

  void showHint() {
    if (gameOver) return;
    final moves =
        _allLegalMoves(whiteToMove ? PieceColor.white : PieceColor.black);
    if (moves.isEmpty) return;
    final scored = moves.map((move) {
      final sim = _simulateMove(move);
      return MapEntry(
          move,
          _evaluateBoard(
              sim, whiteToMove ? PieceColor.white : PieceColor.black));
    }).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    final best = scored.first.key;
    selectedIndex = best.from;
    legalMoves = [best.to];
    shaker.shake(duration: 0.1, intensity: 2);

    Future.delayed(const Duration(seconds: 2), () {
      if (selectedIndex == best.from && legalMoves == [best.to]) {
        selectedIndex = -1;
        legalMoves = [];
      }
    });
  }

  void flipBoard() {
    boardFlipped = !boardFlipped;
  }

  void resetGame() => restart();


  static int _index(int file, int rank) => rank * 8 + file;
  static int _file(int index) => index % 8;
  static int _rank(int index) => index ~/ 8;
  static bool _inBoard(int file, int rank) =>
      file >= 0 && file < 8 && rank >= 0 && rank < 8;

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver || (vsBot && whiteToMove != playerIsWhite)) return;
    final local = event.localPosition;
    final boardSize = min(size.x, size.y - 140);
    final offsetX = (size.x - boardSize) / 2;
    final offsetY = (size.y - boardSize) / 2;
    final squareSize = boardSize / 8;

    double tolerance = squareSize * 0.15;
    int file = ((local.x - offsetX + tolerance) / squareSize).floor().clamp(0, 7);
    int rank = ((local.y - offsetY + tolerance) / squareSize).floor().clamp(0, 7);
    if (boardFlipped) {
      file = 7 - file;
      rank = 7 - rank;
    }
    if (!_inBoard(file, rank)) return;
    final index = _index(file, rank);
    final targetPiece = board[index];
    if (selectedIndex >= 0 && legalMoves.contains(index)) {
      _makeMove(ChessMove(selectedIndex, index,
          isCastling: _isCastlingMove(selectedIndex, index)));
      return;
    }
    if (targetPiece != null &&
        targetPiece.color ==
            (whiteToMove ? PieceColor.white : PieceColor.black)) {
      selectedIndex = index;
      legalMoves = _legalTargets(index);
    } else {
      selectedIndex = -1;
      legalMoves = [];
    }
  }

  bool _isCastlingMove(int from, int to) {
    final piece = board[from];
    return piece != null &&
        piece.type == PieceType.king &&
        (from == 60 || from == 4) &&
        (to == 62 || to == 58 || to == 6 || to == 2);
  }
}

class _BotMoveArgs {
  final List<ChessPiece?> boardState;
  final GameDifficulty difficulty;
  final PieceColor botColor;
  final int? epTarget;
  _BotMoveArgs(this.boardState, this.difficulty, this.botColor, this.epTarget);
}

ChessMove _calculateBotMoveIsolate(_BotMoveArgs args) {
  final moves = ChessGame._allLegalMovesOnBoard(args.botColor, args.boardState, args.epTarget);
  if (moves.isEmpty) return ChessMove(0, 0);

  if (args.difficulty == GameDifficulty.easy) {
    return moves[Random().nextInt(moves.length)];
  } else if (args.difficulty == GameDifficulty.medium || args.difficulty == GameDifficulty.hard) {
    final scored = moves.map((move) {
      final boardSim = ChessGame._simulateMoveOnBoard(move, args.boardState);
      return MapEntry(
          move,
          ChessGame._evaluateBoardAdvanced(boardSim, args.botColor));
    }).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    if (args.difficulty == GameDifficulty.medium && scored.length > 3) {
      return scored[Random().nextInt(min(3, scored.length))].key;
    }
    return scored.first.key;
  } else {

    final depth = args.difficulty == GameDifficulty.extreme ? 4 : 3;
    int bestScore = -999999;
    ChessMove choice = moves.first;
    for (final move in moves) {
      final sim = ChessGame._simulateMoveOnBoard(move, args.boardState);
      final newEp = ChessGame._getNewEpTarget(move, args.boardState);
      final score = ChessGame._minimax(sim, depth, -999999, 999999, false, args.botColor, newEp);
      if (score > bestScore) {
        bestScore = score;
        choice = move;
      }
    }
    return choice;
  }
}


class BoardState {
  final List<ChessPiece?> board;
  final int? enPassantTarget;
  final bool whiteToMove;
  BoardState(
      {required this.board,
      required this.enPassantTarget,
      required this.whiteToMove});
}


class _ChessRenderer extends Component {
  final ChessGame game;
  _ChessRenderer(this.game);

  final _paint = Paint();

  @override
  void render(Canvas canvas) {
    final g = game;
    final boardSize = min(g.size.x, g.size.y - 140);
    final originX = (g.size.x - boardSize) / 2;
    final originY = (g.size.y - boardSize) / 2;
    final squareSize = boardSize / 8;
    const files = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              originX - 10, originY - 10, boardSize + 20, boardSize + 20),
          const Radius.circular(24)),
      _paint..color = const Color(0xFF0D1F2D),
    );

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        int displayRank = g.boardFlipped ? 7 - rank : rank;
        int displayFile = g.boardFlipped ? 7 - file : file;
        final index = displayRank * 8 + displayFile;
        final color = (file + rank) % 2 == 0
            ? const Color(0xFFF0D9B5)
            : const Color(0xFFB58863);
        final square = Rect.fromLTWH(originX + file * squareSize,
            originY + rank * squareSize, squareSize, squareSize);
        canvas.drawRect(square, _paint..color = color);
        if (g.selectedIndex == index) {
          canvas.drawRect(square,
              _paint..color = Colors.yellowAccent.withValues(alpha: 0.3));
        } else if (g.legalMoves.contains(index)) {
          canvas.drawRect(
              square, _paint..color = Colors.cyanAccent.withValues(alpha: 0.2));
        }
        if (g.board[index] != null) {
          _drawPiece(canvas, square, g.board[index]!);
        }
      }
    }


    for (int file = 0; file < 8; file++) {
      String label = g.boardFlipped ? files[7 - file] : files[file];
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(originX + file * squareSize + squareSize / 2 - tp.width / 2,
              originY + boardSize + 4));
    }

    for (int rank = 0; rank < 8; rank++) {
      int number = g.boardFlipped ? rank + 1 : 8 - rank;
      final tp = TextPainter(
        text: TextSpan(
            text: '$number',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(originX - tp.width - 4,
              originY + rank * squareSize + squareSize / 2 - tp.height / 2));
    }

    if (g.gameOver) {
      final overlay = Rect.fromLTWH(originX, originY, boardSize, boardSize);
      canvas.drawRect(
          overlay, _paint..color = Colors.black.withValues(alpha: 0.4));
      final tp = TextPainter(
        text: TextSpan(
            text: g.result,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: boardSize - 40);
      tp.paint(
          canvas,
          Offset(originX + boardSize / 2 - tp.width / 2,
              originY + boardSize / 2 - tp.height / 2));
    }
  }

  void _drawPiece(Canvas canvas, Rect square, ChessPiece piece) {
    bool isWhite = piece.color == PieceColor.white;
    final center = square.center;
    final radius = square.shortestSide * 0.38;


    canvas.drawCircle(
      center + const Offset(1.5, 2.5),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );


    final discColor = isWhite ? const Color(0xFFF5F0E8) : const Color(0xFF2A2A2A);
    canvas.drawCircle(center, radius, Paint()..color = discColor);


    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isWhite ? const Color(0xFFD4C8B0) : const Color(0xFF555555)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );


    final textStyle = TextStyle(
      color: isWhite ? const Color(0xFF3E2723) : const Color(0xFFECECEC),
      fontSize: square.height * 0.55,
      fontWeight: FontWeight.w900,
    );
    final tp = TextPainter(
      text: TextSpan(text: piece.symbol, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }
}
