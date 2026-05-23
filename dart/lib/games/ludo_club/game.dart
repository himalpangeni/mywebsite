import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'turn_indicator.dart';
import 'package:flame/events.dart';

class LudoClubGame extends FlameGame {
  final List<PlayerSetup> setupPlayers;
  late List<Player> players;

  int currentPlayerIdx = 0;
  int diceValue = 1;
  int sixCount = 0;
  bool rolling = false;
  bool waitingForMove = false;
  bool gameOver = false;
  int? winnerIdx;
  Token? _lastMovedToken;

  final Random _rand = Random();

  late double cell;
  late double boardSize;

  Vector2 get boardOffset =>
      (size / 2) - Vector2(boardSize / 2, boardSize / 2 + 60);


  final List<Offset> _globalPath = [
    const Offset(8, 0),
    const Offset(8, 1),
    const Offset(8, 2),
    const Offset(8, 3),
    const Offset(8, 4),
    const Offset(8, 5),
    const Offset(9, 6),
    const Offset(10, 6),
    const Offset(11, 6),
    const Offset(12, 6),
    const Offset(13, 6),
    const Offset(14, 6),
    const Offset(14, 7),
    const Offset(14, 8),
    const Offset(13, 8),
    const Offset(12, 8),
    const Offset(11, 8),
    const Offset(10, 8),
    const Offset(9, 8),
    const Offset(8, 9),
    const Offset(8, 10),
    const Offset(8, 11),
    const Offset(8, 12),
    const Offset(8, 13),
    const Offset(8, 14),
    const Offset(7, 14),
    const Offset(6, 14),
    const Offset(6, 13),
    const Offset(6, 12),
    const Offset(6, 11),
    const Offset(6, 10),
    const Offset(6, 9),
    const Offset(5, 8),
    const Offset(4, 8),
    const Offset(3, 8),
    const Offset(2, 8),
    const Offset(1, 8),
    const Offset(0, 8),
    const Offset(0, 7),
    const Offset(0, 6),
    const Offset(1, 6),
    const Offset(2, 6),
    const Offset(3, 6),
    const Offset(4, 6),
    const Offset(5, 6),
    const Offset(6, 5),
    const Offset(6, 4),
    const Offset(6, 3),
    const Offset(6, 2),
    const Offset(6, 1),
    const Offset(6, 0),
    const Offset(7, 0),
  ];

  final Set<int> safeIndices = {1, 9, 14, 22, 27, 35, 40, 48};

  final Map<Color, List<Offset>> _homeStretch = {
    Colors.red: [
      const Offset(7, 1),
      const Offset(7, 2),
      const Offset(7, 3),
      const Offset(7, 4),
      const Offset(7, 5),
      const Offset(7, 6)
    ],
    Colors.green: [
      const Offset(13, 7),
      const Offset(12, 7),
      const Offset(11, 7),
      const Offset(10, 7),
      const Offset(9, 7),
      const Offset(8, 7)
    ],
    Colors.yellow: [
      const Offset(7, 13),
      const Offset(7, 12),
      const Offset(7, 11),
      const Offset(7, 10),
      const Offset(7, 9),
      const Offset(7, 8)
    ],
    Colors.blue: [
      const Offset(1, 7),
      const Offset(2, 7),
      const Offset(3, 7),
      const Offset(4, 7),
      const Offset(5, 7),
      const Offset(6, 7)
    ],
  };

  final Map<Color, List<Offset>> _yardPositions = {
    Colors.red: [
      const Offset(10.5, 1.5),
      const Offset(12.5, 1.5),
      const Offset(10.5, 3.5),
      const Offset(12.5, 3.5)
    ],
    Colors.green: [
      const Offset(10.5, 10.5),
      const Offset(12.5, 10.5),
      const Offset(10.5, 12.5),
      const Offset(12.5, 12.5)
    ],
    Colors.yellow: [
      const Offset(1.5, 10.5),
      const Offset(3.5, 10.5),
      const Offset(1.5, 12.5),
      const Offset(3.5, 12.5)
    ],
    Colors.blue: [
      const Offset(1.5, 1.5),
      const Offset(3.5, 1.5),
      const Offset(1.5, 3.5),
      const Offset(3.5, 3.5)
    ],
  };

  final Map<Color, int> _startIndices = {
    Colors.red: 1,
    Colors.green: 14,
    Colors.yellow: 27,
    Colors.blue: 40,
  };


  LudoClubGame({required this.setupPlayers});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initPlayers();
    add(BoardPainter(this)..priority = 0);
    add(DiceComponent(this)..priority = 5);
    add(TurnIndicatorComponent()..priority = 5);
    _spawnTokens();
    _spawnSafeStars();
    overlays.add('RulesUI');
    _startInitialAITurn();
  }

  void _startInitialAITurn() {
    if (players[currentPlayerIdx].isAI && !gameOver) {
      Future.delayed(const Duration(milliseconds: 1500), rollDice);
    }
  }

  void _initPlayers() {
    players = [];
    for (var s in setupPlayers) {
      final yards = _yardPositions[s.color]!;
      players.add(Player(
        color: s.color,
        isAI: s.isAI,
        tokens: List.generate(4, (i) => Token(yardPos: yards[i])),
        startIdx: _startIndices[s.color]!,
      ));
    }
    currentPlayerIdx = 0;
    sixCount = 0;
    gameOver = false;
    winnerIdx = null;
    _lastMovedToken = null;
  }

  void _spawnTokens() {
    for (var p in players) {
      for (var t in p.tokens) {
        t.player = p;
        add(TokenComponent(t, p, this));
      }
    }
  }

  void _spawnSafeStars() {
    for (int i in safeIndices) {
      add(SafeStarComponent(this, i));
    }
  }

  int get currentPlayer => currentPlayerIdx;
  Color get currentPlayerColor => players[currentPlayerIdx].color;
  int get dice => diceValue;

  bool _isSquareBlockedFor(int globalIdx, Player mover) {

    if (safeIndices.contains(globalIdx)) {
      return false;
    }
    
    Map<Player, int> tokensAtSquare = {};
    for (var p in players) {
      if (p == mover) continue;
      for (var t in p.tokens) {
        if (t.step != -1 && t.step < 51) {
          if ((p.startIdx + t.step) % 52 == globalIdx) {
            tokensAtSquare[p] = (tokensAtSquare[p] ?? 0) + 1;
          }
        }
      }
    }

    return tokensAtSquare.values.any((count) => count >= 2);
  }


  bool canMove(Token token, int dice) {
    if (token.step == -1) {
      if (dice != 6 && dice != 1) return false;

      int startIdx = token.player!.startIdx;
      return !_isSquareBlockedFor(startIdx, token.player!);
    }
    if (token.step + dice > 57) return false;


    for (int i = 1; i <= dice; i++) {
       int checkStep = token.step + i;
       if (checkStep < 51) {
           int globalIdx = (token.player!.startIdx + checkStep) % 52;
           if (_isSquareBlockedFor(globalIdx, token.player!)) {
               return false;
           }
       }
    }

    return true;
  }

  void rollDice() async {
    if (rolling || gameOver || waitingForMove) return;
    rolling = true;
    HapticFeedback.lightImpact();
    for (var p in players) {
      for (var t in p.tokens) {
        t.holderPos = null;
      }
    }
    children.whereType<DiceComponent>().first.animate();
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      diceValue = _rand.nextInt(6) + 1;
    }
    rolling = false;
    

    if (diceValue == 6 || diceValue == 1) {
      if (diceValue == 6) {
        sixCount++;
      } else {
        sixCount = 0;
      }
      if (sixCount == 3) {

        if (_lastMovedToken != null && _lastMovedToken!.step != -1 && _lastMovedToken!.step < 57) {
          _lastMovedToken!.step = -1;
          _lastMovedToken!.currentPos = _lastMovedToken!.yardPos;
          final comp = children
              .whereType<TokenComponent>()
              .firstWhere((c) => c.token == _lastMovedToken);
          comp.flash();
          comp.syncPosition(instant: false);
        }
        _lastMovedToken = null;
        sixCount = 0;
        _nextTurn();
        return;
      }
    } else {
      sixCount = 0;
    }

    bool hasMove =
        players[currentPlayerIdx].tokens.any((t) => canMove(t, diceValue));
        
    if (!hasMove) {
      rolling = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
          rolling = false;
          waitingForMove = false;
          _nextTurn();
      });
    } else {
      waitingForMove = true;
      if (players[currentPlayerIdx].isAI) {
        Future.delayed(const Duration(milliseconds: 2000), _aiMove);
      }
    }
  }

  void _aiMove() {
    if (gameOver || rolling) return;
    final player = players[currentPlayerIdx];
    final movable = player.tokens.where((t) => canMove(t, diceValue)).toList();
    if (movable.isNotEmpty) {
      movable.sort((a, b) => b.step.compareTo(a.step));
      _executeMove(movable.first, diceValue);
    } else {
      _nextTurn();
    }
  }

  void _executeMove(Token token, int dice) async {
    waitingForMove = false;
    if (!canMove(token, dice)) return;

    _lastMovedToken = token;
    bool extraTurn = (dice == 6 || dice == 1);
    int oldStep = token.step;
    int stepCount = dice;
    token.holderPos = null;


    if (oldStep == -1) {
      stepCount = 1;
    }

    int targetStep = token.step + stepCount;


    for (int i = oldStep + 1; i <= targetStep; i++) {
      final oldPos = token.currentPos;
      token.step = i;
      _updateTokenPosition(token);
      _syncTokensAt(oldPos);
      _syncTokensAt(token.currentPos);
      await Future.delayed(const Duration(milliseconds: 250)); 
    }

    bool captured = _handleCaptures(token);
    if (captured || targetStep >= 57) extraTurn = true;

    if (players[currentPlayerIdx].tokens.every((t) => t.step >= 57)) {
      gameOver = true;
      winnerIdx = currentPlayerIdx;
      overlays.add('GameOver');
      return;
    }

    if (!extraTurn) {
      _nextTurn();
    } else {
      if (players[currentPlayerIdx].isAI && !gameOver) {
        Future.delayed(const Duration(milliseconds: 500), rollDice);
      }
    }
  }

  void _updateTokenPosition(Token token) {
    final player = token.player!;
    if (token.step == -1) {
      token.currentPos = token.yardPos;
    } else if (token.step < 51) {
      int idx = (player.startIdx + token.step) % 52;
      token.currentPos = _globalPath[idx];
    } else if (token.step < 57) {
      int homeIdx = token.step - 51;
      token.currentPos = _homeStretch[player.color]![homeIdx];
    } else {
      token.currentPos = const Offset(7, 7);
    }
  }

  void _syncTokensAt(Offset pos) {
    for (var comp in children.whereType<TokenComponent>().where((c) => c.token.currentPos == pos)) {
      comp.syncPosition(instant: false);
    }
  }



  bool _handleCaptures(Token movedToken) {
    final activePlayer = players[currentPlayerIdx];
    if (movedToken.step == -1 || movedToken.step >= 51) return false;
    int globalIdx = (activePlayer.startIdx + movedToken.step) % 52;
    if (safeIndices.contains(globalIdx)) return false;

    bool captured = false;
    for (var p in players) {
      if (p == activePlayer) continue;
      for (var t in p.tokens) {
        if (t.step != -1 && t.step < 51) {
          if ((p.startIdx + t.step) % 52 == globalIdx) {
            t.step = -1;
            t.currentPos = t.yardPos;
            final comp = children
                .whereType<TokenComponent>()
                .firstWhere((c) => c.token == t);
            comp.flash();
            comp.syncPosition(instant: false);
            _syncTokensAt(movedToken.currentPos);
            captured = true;
          }
        }
      }
    }
    return captured;
  }

  void _nextTurn() {
    if (gameOver) return;
    do {
      currentPlayerIdx = (currentPlayerIdx + 1) % players.length;
    } while (players[currentPlayerIdx].isFinished);
    sixCount = 0;
    for (var comp in children.whereType<TokenComponent>()) {
      comp.highlight(comp.player == players[currentPlayerIdx]);
    }
    if (players[currentPlayerIdx].isAI && !gameOver) {
      Future.delayed(const Duration(milliseconds: 1500), rollDice);
    }
  }

  void moveToken(Token token, int dice) {
    if (rolling || gameOver || !waitingForMove) return;
    if (players[currentPlayerIdx] != token.player) return;
    if (!canMove(token, dice)) return;
    _executeMove(token, dice);
  }

  void restart() {
    _initPlayers();
    for (var child in children.toList()) {
      if (child is BoardPainter || child is DiceComponent || child is TurnIndicatorComponent) continue;
      remove(child);
    }
    _spawnTokens();
    _spawnSafeStars();
    camera.viewfinder.anchor = Anchor.topLeft;
    gameOver = false;
    waitingForMove = false;
    winnerIdx = null;
    overlays.remove('GameOver');
    _startInitialAITurn();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final maxDim = min(size.x, size.y - 140);
    cell = maxDim / 15;
    boardSize = 15 * cell;
  }
}

class Player {
  final Color color;
  final bool isAI;
  final List<Token> tokens;
  final int startIdx;
  bool isFinished = false;
  Player({
    required this.color,
    required this.isAI,
    required this.tokens,
    required this.startIdx,
  });
}

class Token {
  int step = -1;
  Offset currentPos;
  final Offset yardPos;
  Player? player;
  Offset? holderPos;
  Token({required this.yardPos}) : currentPos = yardPos;
}

class PlayerSetup {
  final Color color;
  final bool isAI;
  PlayerSetup({required this.color, required this.isAI});
}

class BoardPainter extends Component {
  final LudoClubGame game;
  BoardPainter(this.game);

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(game.boardOffset.x, game.boardOffset.y);
    final c = game.cell;
    final bs = 15 * c;


    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-4, -4, bs + 8, bs + 8), const Radius.circular(12)),
      Paint()..color = Colors.black26,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, bs, bs), const Radius.circular(10)),
      Paint()..color = const Color(0xFFFFF8E1),
    );


    _drawYard(canvas, 0, 0, Colors.blue, c);
    _drawYard(canvas, 9, 0, Colors.red, c);
    _drawYard(canvas, 9, 9, Colors.green, c);
    _drawYard(canvas, 0, 9, Colors.yellow, c);


    final trackPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black38
      ..strokeWidth = 0.8;


    final Map<int, Color> startColors = {1: Colors.red.shade300, 14: Colors.green.shade300, 27: Colors.yellow.shade300, 40: Colors.blue.shade400};

    for (int i = 0; i < 52; i++) {
      final pos = game._globalPath[i];
      final r = Rect.fromLTWH(pos.dx * c, pos.dy * c, c, c);


      if (startColors.containsKey(i)) {
        canvas.drawRect(r, trackPaint..color = startColors[i]!);

        final arrowPaint = Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke;
        final cx = r.center.dx;
        final cy = r.center.dy;
        final s = c * 0.25;
        canvas.drawLine(Offset(cx - s, cy), Offset(cx + s, cy), arrowPaint);
        canvas.drawLine(Offset(cx + s, cy), Offset(cx + s * 0.4, cy - s * 0.6), arrowPaint);
        canvas.drawLine(Offset(cx + s, cy), Offset(cx + s * 0.4, cy + s * 0.6), arrowPaint);
      } else if (game.safeIndices.contains(i)) {
        canvas.drawRect(r, trackPaint..color = Colors.grey.shade200);

        _drawStar(canvas, r.center, c * 0.3, Colors.amber);
      } else {
        canvas.drawRect(r, trackPaint..color = Colors.white);
      }
      canvas.drawRect(r, borderPaint);
    }


    final homePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 1; i <= 5; i++) {

      final rr = Rect.fromLTWH(7 * c, i * c, c, c);
      canvas.drawRect(rr, homePaint..color = Colors.red.shade300);
      canvas.drawRect(rr, borderPaint);

      final gr = Rect.fromLTWH((14 - i) * c, 7 * c, c, c);
      canvas.drawRect(gr, homePaint..color = Colors.green.shade300);
      canvas.drawRect(gr, borderPaint);

      final yr = Rect.fromLTWH(7 * c, (14 - i) * c, c, c);
      canvas.drawRect(yr, homePaint..color = Colors.yellow.shade300);
      canvas.drawRect(yr, borderPaint);

      final br = Rect.fromLTWH(i * c, 7 * c, c, c);
      canvas.drawRect(br, homePaint..color = Colors.blue.shade400);
      canvas.drawRect(br, borderPaint);
    }


    final center = 7.5 * c;
    final triangleBorder = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.5;

    final topTri = Path()..moveTo(6 * c, 6 * c)..lineTo(center, center)..lineTo(9 * c, 6 * c)..close();
    canvas.drawPath(topTri, Paint()..color = Colors.red);
    canvas.drawPath(topTri, triangleBorder);

    final rightTri = Path()..moveTo(9 * c, 6 * c)..lineTo(center, center)..lineTo(9 * c, 9 * c)..close();
    canvas.drawPath(rightTri, Paint()..color = Colors.green);
    canvas.drawPath(rightTri, triangleBorder);

    final bottomTri = Path()..moveTo(9 * c, 9 * c)..lineTo(center, center)..lineTo(6 * c, 9 * c)..close();
    canvas.drawPath(bottomTri, Paint()..color = Colors.yellow);
    canvas.drawPath(bottomTri, triangleBorder);

    final leftTri = Path()..moveTo(6 * c, 9 * c)..lineTo(center, center)..lineTo(6 * c, 6 * c)..close();
    canvas.drawPath(leftTri, Paint()..color = Colors.blue);
    canvas.drawPath(leftTri, triangleBorder);


    canvas.drawCircle(Offset(center, center), c * 0.6, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center, center), c * 0.6, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(center, center), c * 0.35, Paint()..color = Colors.amber);


    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, bs, bs), const Radius.circular(10)),
      Paint()..color = Colors.brown.shade800..style = PaintingStyle.stroke..strokeWidth = 3,
    );

    canvas.restore();
  }

  void _drawYard(Canvas canvas, double x, double y, Color color, double c) {

    final outerRect = Rect.fromLTWH(x * c, y * c, 6 * c, 6 * c);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(6)),
      Paint()..color = color,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(6)),
      Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2,
    );

    final innerRect = Rect.fromLTWH((x + 0.8) * c, (y + 0.8) * c, 4.4 * c, 4.4 * c);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(10)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(10)),
      Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2,
    );

    final positions = [
      Offset((x + 2) * c, (y + 2) * c),
      Offset((x + 4) * c, (y + 2) * c),
      Offset((x + 2) * c, (y + 4) * c),
      Offset((x + 4) * c, (y + 4) * c),
    ];
    for (final pos in positions) {
      canvas.drawCircle(pos, c * 0.5, Paint()..color = color.withValues(alpha: 0.15));
      canvas.drawCircle(pos, c * 0.5, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    final innerR = radius * 0.4;
    for (int i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final r = (i % 2 == 0) ? radius : innerR;
      final pt = Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }
}

class SafeStarComponent extends PositionComponent {
  final LudoClubGame game;
  final int index;
  SafeStarComponent(this.game, this.index);

  @override
  Future<void> onLoad() async {
    size = Vector2.all(game.cell * 0.8);
    anchor = Anchor.center;
    final pos = game._globalPath[index];
    position = Vector2(
      game.boardOffset.x + pos.dx * game.cell + game.cell / 2,
      game.boardOffset.y + pos.dy * game.cell + game.cell / 2,
    );
    add(ScaleEffect.to(
      Vector2.all(1.3),
      EffectController(duration: 0.6, reverseDuration: 0.6, infinite: true),
    ));
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.orange;
    

    final Path path = Path();
    final double halfWidth = size.x / 2;
    final double radius = size.x * 0.45;
    final double innerRadius = size.x * 0.2;
    final Offset center = Offset(halfWidth, size.y / 2);

    for (int i = 0; i < 10; i++) {
      double angle = -pi / 2 + (i * pi / 5);
      double r = (i % 2 == 0) ? radius : innerRadius;
      double dx = center.dx + cos(angle) * r;
      double dy = center.dy + sin(angle) * r;
      
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
}

class DiceComponent extends PositionComponent with TapCallbacks {
  final LudoClubGame game;
  DiceComponent(this.game);

  @override
  void onTapDown(TapDownEvent event) {
    if (game.gameOver || game.rolling || game.waitingForMove) return;
    if (!game.players[game.currentPlayerIdx].isAI) {
      game.rollDice();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, game.boardOffset.y + game.boardSize + 70);
    this.size = Vector2(50, 50);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10)),
        Paint()..color = game.currentPlayerColor);
    final paint = Paint()..color = Colors.white;
    int v = game.diceValue;
    if (v % 2 != 0) canvas.drawCircle(const Offset(25, 25), 4, paint);
    if (v >= 2) {
      canvas.drawCircle(const Offset(12, 12), 4, paint);
      canvas.drawCircle(const Offset(38, 38), 4, paint);
    }
    if (v >= 4) {
      canvas.drawCircle(const Offset(38, 12), 4, paint);
      canvas.drawCircle(const Offset(12, 38), 4, paint);
    }
    if (v == 6) {
      canvas.drawCircle(const Offset(12, 25), 4, paint);
      canvas.drawCircle(const Offset(38, 25), 4, paint);
    }
  }

  void animate() {
    add(ScaleEffect.to(Vector2.all(1.4),
        EffectController(duration: 0.2, reverseDuration: 0.2)));
    add(RotateEffect.by(pi * 4, EffectController(duration: 0.5)));
  }
}

class TokenComponent extends PositionComponent with TapCallbacks {
  final Token token;
  final Player player;
  final LudoClubGame game;
  late CircleComponent _circle;
  late CircleComponent _glow;
  bool _flashing = false;

  TokenComponent(this.token, this.player, this.game) {
    size = Vector2(28, 28);
    anchor = Anchor.center;
    token.player = player;
    priority = 10;
  }

  @override
  Future<void> onLoad() async {
    _circle = CircleComponent(
      radius: 13,
      paint: Paint()..color = player.color,
      anchor: Anchor.center,
      position: Vector2(14, 14),
    );
    add(_circle);
    

    _glow = CircleComponent(
      radius: 14,
      anchor: Anchor.center,
      position: Vector2(14, 14),
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    add(_glow);
    syncPosition(instant: true);
    highlight(player == game.players[game.currentPlayerIdx]);
  }

  void highlight(bool active) {
    if (active) {
      _glow.paint = Paint()
        ..color = player.color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
    } else {
      _glow.paint = Paint()
        ..color = player.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
    }
  }

  void syncPosition({bool instant = false}) {
    final baseTarget = Vector2(
      game.boardOffset.x + token.currentPos.dx * game.cell + game.cell / 2,
      game.boardOffset.y + token.currentPos.dy * game.cell + game.cell / 2,
    );

    Vector2 offset = Vector2.zero();
    if (token.step != -1 && token.step < 57) {

      final tokensAtSamePos = game.children
          .whereType<TokenComponent>()
          .where((c) => c.token.currentPos == token.currentPos && c.token.step != -1)
          .toList();
      
      if (tokensAtSamePos.length > 1) {

        tokensAtSamePos.sort((a, b) {
          int colA = game.players.indexOf(a.player);
          int colB = game.players.indexOf(b.player);
          if (colA != colB) return colA.compareTo(colB);
          return a.token.yardPos.dx.compareTo(b.token.yardPos.dx);
        });

        int index = tokensAtSamePos.indexOf(this);
        int total = tokensAtSamePos.length;
        double angle = (2 * pi * index) / total;
        double dist = game.cell * 0.25;
        offset = Vector2(cos(angle) * dist, sin(angle) * dist);
      }
    }

    final target = baseTarget + offset;
    if (instant) {
      position = target;
    } else {

      double duration = (token.step == -1) ? 0.4 : 0.25;
      if (token.step == -1) {
        add(RotateEffect.by(pi * 4, EffectController(duration: duration)));
      }
      add(MoveToEffect(
          target, EffectController(duration: duration, curve: Curves.easeInOut)));
    }
    



  }

  void flash() async {
    if (_flashing) return;
    _flashing = true;
    add(ScaleEffect.to(Vector2.all(1.6),
        EffectController(duration: 0.2, reverseDuration: 0.2)));
    for (int i = 0; i < 3; i++) {
      _circle.paint = Paint()..color = Colors.red;
      await Future.delayed(const Duration(milliseconds: 80));
      _circle.paint = Paint()..color = player.color;
      await Future.delayed(const Duration(milliseconds: 80));
    }
    _flashing = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (token.holderPos != null) {
      final ringPaint = Paint()
        ..color = player.color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 18, ringPaint);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.rolling || game.gameOver) return;
    if (game.players[game.currentPlayerIdx] != player) return;
    if (game.canMove(token, game.diceValue)) {
      game.moveToken(token, game.diceValue);
    }
  }
}
