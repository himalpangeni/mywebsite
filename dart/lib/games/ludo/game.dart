import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import 'dice.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';

enum LudoColor { red, green, yellow, blue }

class LudoPlayer {
    final LudoColor color;
    final bool isBot;
    LudoPlayer({required this.color, this.isBot = false});
}

class LudoGame extends FlameGame with TapCallbacks {
    late final Random _random;
    final GameDifficulty difficulty;
    late List<LudoPlayer> config;
    
    late List<LudoPlayer> players;
    final List<int> safeTiles = const [1, 9, 14, 22, 27, 35, 40, 48];

    int currentPlayerIndex = 0;
    int diceValue = 0;
    bool waitingForMove = false;
    bool isGameOver = false;
    double _time = 0;

    late DiceComponent dice;

    bool _isSafeTile(int tile) => safeTiles.contains(tile);
    bool _isBlockedTile(int tile, [LudoPiece? ignore]) =>
        children
            .whereType<LudoPiece>()
            .where((p) => p.currentTileIndex == tile && p != ignore)
            .length >= 2;
    late ScreenShake shaker;
    late Sprite logoSprite;

    LudoGame({required this.difficulty, required List<dynamic> config}) : super() {
        this.config = config.map((c) {
            if (c is LudoPlayer) return c;
            final colorValue = c['color'] is String ? c['color'] : c['color'].toString();
            final colorName = colorValue.split('.').last;
            return LudoPlayer(
                color: LudoColor.values.firstWhere((e) => e.toString().split('.').last == colorName),
                isBot: c['isBot'] ?? false,
            );
        }).toList();
    }

    @override
    Color backgroundColor() => const Color(0xFF3E2723);

    @override
    Future<void> onLoad() async {
        _random = Random();
        await super.onLoad();
        logoSprite = await loadSprite('logo.png');
        restart();
    }

    @override
    void update(double dt) {
        super.update(dt);
        _time += dt;
    }

    void restart() {
        waitingForMove = false;
        for (final child in children.toList()) {
            if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
        }
        camera.viewfinder.anchor = Anchor.topLeft;
        if (overlays.isActive('GameOver')) overlays.remove('GameOver');

        isGameOver = false;
        players = config.isNotEmpty ? config : [
            LudoPlayer(color: LudoColor.red),
            LudoPlayer(color: LudoColor.green, isBot: true),
            LudoPlayer(color: LudoColor.yellow, isBot: true),
            LudoPlayer(color: LudoColor.blue, isBot: true),
        ];
        currentPlayerIndex = 0;
        
        add(_BoardPainter());
        
        for (int p = 0; p < players.length; p++) {
            for (int i = 0; i < 4; i++) {
                add(LudoPiece(color: players[p].color, index: i, playerIndex: p));
            }
        }
        
        dice = DiceComponent()..position = Vector2(size.x - 70, size.y - 70)..size = Vector2(60, 60);
        add(dice);

        add(CinematicOverlay());
        shaker = ScreenShake();
        add(shaker);
        add(_DynamicLighting());

        add(TextComponent(
          text: 'LUDO MASTER',
          position: Vector2(size.x / 2, 60),
          anchor: Anchor.center,
          textRenderer: TextPaint(style: const TextStyle(color: Colors.white70, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
        ));
        add(TextComponent(
          text: 'Tap dice to roll. Tap your piece when ready.',
          position: Vector2(size.x / 2, 90),
          anchor: Anchor.center,
          textRenderer: TextPaint(style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ));


        add(_TurnOverlay());

        _startTurn();
        resumeEngine();
    }

    void _startTurn() {
        if (isGameOver) return;
        diceValue = 0;
        waitingForMove = false;
        
        if (players[currentPlayerIndex].isBot) {
            Future.delayed(const Duration(milliseconds: 400), () => _rollDice());
        }
    }

    void _rollDice() {
        if (dice.isRolling || waitingForMove || isGameOver) return;
        dice.roll();
        shaker.shake(duration: 0.2, intensity: 4);
        
        Future.delayed(const Duration(milliseconds: 500), () {
            diceValue = dice.value;
            _evaluateMoves();
        });
    }

    void _evaluateMoves() {
        final player = players[currentPlayerIndex];
        final pieces = children.whereType<LudoPiece>().where((p) => p.color == player.color).toList();
        
        List<LudoPiece> movable = [];
        for (var p in pieces) {
            if (p.currentTileIndex == 0) {
                if (diceValue == 6) movable.add(p);
            } else if (p.currentTileIndex + diceValue <= 58) {
                movable.add(p);
            }
        }

        if (movable.isEmpty) {
            Future.delayed(const Duration(milliseconds: 400), _nextTurn);
        } else {
            waitingForMove = true;
            if (player.isBot) {

                final move = (difficulty == GameDifficulty.easy) 
                    ? movable[_random.nextInt(movable.length)] 
                    : _getSmartBotMove(movable);
                Future.delayed(const Duration(milliseconds: 500), () async => await handleMove(move, diceValue));
            }
        }
    }

    LudoPiece _getSmartBotMove(List<LudoPiece> movable) {
        LudoPiece best = movable.first;
        double bestScore = -1.0;

        final safeTiles = [1, 9, 14, 22, 27, 35, 40, 48];

        for (var p in movable) {
            double score = 0;
            int nextIdx = p.currentTileIndex == 0 ? 1 : p.currentTileIndex + diceValue;


            if (nextIdx > 0 && nextIdx <= 52 && !safeTiles.contains(nextIdx)) {
                final others = children.whereType<LudoPiece>().where((o) => o.color != p.color && o.currentTileIndex == nextIdx).toList();
                if (others.isNotEmpty) score += 1000;
            }


            if (p.currentTileIndex == 0) score += 500;


            if (safeTiles.contains(nextIdx)) score += 300;


            if (nextIdx == 58) score += 800;
            if (nextIdx > 52) score += 200;


            score += nextIdx * 10;

            if (score > bestScore) {
                bestScore = score;
                best = p;
            }
        }
        return best;
    }

    Future<void> handleMove(LudoPiece piece, int diceValue) async {
        waitingForMove = true;
        if (piece.currentTileIndex == 0) {
            if (diceValue == 6) piece.currentTileIndex = 1;
        } else {
            int nextPos = piece.currentTileIndex + diceValue;
            if (nextPos <= 58) {
                piece.currentTileIndex = nextPos;
            }
        }
        

        while (piece.isMoving) {
            await Future.delayed(const Duration(milliseconds: 50));
        }

        _checkCapture(piece);
        _checkWinner();

        waitingForMove = false;
        if (diceValue != 6 && !isGameOver) {
            _nextTurn();
        } else if (!isGameOver) {
            _startTurn();
        }
    }

    void _checkWinner() {
        final player = players[currentPlayerIndex];
        final pieces = children.whereType<LudoPiece>().where((p) => p.color == player.color).toList();
        if (pieces.every((p) => p.currentTileIndex == 58)) {
            isGameOver = true;
            add(ConfettiEmitter());
            shaker.shake(duration: 1.0, intensity: 15);
            overlays.add('GameOver');
        }
    }

    void _checkCapture(LudoPiece movedPiece) {
        if (movedPiece.currentTileIndex == 0 || movedPiece.currentTileIndex > 52) return;
        if (_isSafeTile(movedPiece.currentTileIndex)) return;

        final opponents = children
            .whereType<LudoPiece>()
            .where((p) => p.color != movedPiece.color && p.currentTileIndex == movedPiece.currentTileIndex)
            .toList();
        if (opponents.isEmpty || _isBlockedTile(movedPiece.currentTileIndex, movedPiece)) return;

        final alliedPieces = children
            .whereType<LudoPiece>()
            .where((p) => p.color == movedPiece.color && p.currentTileIndex == movedPiece.currentTileIndex)
            .toList();
        if (alliedPieces.length >= 2) return;

        shaker.shake(duration: 0.4, intensity: 12);
        SensoryService.heavyImpact();
        for (var p in opponents) {
            p.currentTileIndex = 0;
        }
    }

    void _nextTurn() {
        currentPlayerIndex = (currentPlayerIndex - 1 + players.length) % players.length;
        _startTurn();
    }

    @override
    void onTapDown(TapDownEvent event) {
        if (!players[currentPlayerIndex].isBot && !dice.isRolling && !waitingForMove) {
            _rollDice();
        }
    }

    int getScore() {
        int total = 0;
        for (final p in children.whereType<LudoPiece>()) {
            if (p.color == players[0].color) {
                total += p.currentTileIndex;
            }
        }
        return total;
    }

    void onPieceTapped(int pIdx, int pieceIdx) {
        if (waitingForMove && pIdx == currentPlayerIndex) {
            final player = players[pIdx];
            final piece = children.whereType<LudoPiece>().firstWhere((p) => p.color == player.color && p.index == pieceIdx);
            
            if (piece.currentTileIndex == 0 && diceValue == 6) {
                handleMove(piece, diceValue);
            } else if (piece.currentTileIndex > 0 && piece.currentTileIndex + diceValue <= 58) {
                handleMove(piece, diceValue);
            }
        }
    }
}

class LudoPiece extends PositionComponent with HasGameReference<LudoGame>, TapCallbacks {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
    final LudoColor color;
    final int index;
    final int playerIndex;
    int currentTileIndex = 0; 
    int _visualTileIndex = 0;
    double _moveTimer = 0;
    bool _isStepping = false;
    bool get isMoving => _visualTileIndex != currentTileIndex || _isStepping;

    LudoPiece({required this.color, required this.index, required this.playerIndex}) : super(size: Vector2(40, 40), anchor: Anchor.center);

    @override
    Future<void> onLoad() async {
        final gridPos = _getGridPosition(currentTileIndex);
        final sizeFactor = (game.size.x < game.size.y ? game.size.x : game.size.y) - 40;
        final cellSize = sizeFactor / 15;
        final boardTopLeft = game.size / 2 - Vector2.all(sizeFactor / 2);
        position = boardTopLeft + Vector2(gridPos.x * cellSize + cellSize / 2, gridPos.y * cellSize + cellSize / 2);
    }
    
    @override
    void update(double dt) {
        super.update(dt);
        if (_visualTileIndex != currentTileIndex) {
            _isStepping = true;
            _moveTimer += dt;
            if (_moveTimer > 0.18) {
                _moveTimer = 0;
                if (_visualTileIndex < currentTileIndex) {
                  _visualTileIndex++;
                } else if (_visualTileIndex > currentTileIndex) {
                  _visualTileIndex = currentTileIndex;
                }
                game.shaker.shake(duration: 0.05, intensity: 3);
            }
        } else {
            _isStepping = false;
            _moveTimer = 0;
        }

        final gridPos = _getGridPosition(_visualTileIndex);
        final sizeFactor = (game.size.x < game.size.y ? game.size.x : game.size.y) - 40;
        final cellSize = sizeFactor / 15;
        final boardTopLeft = game.size / 2 - Vector2.all(sizeFactor / 2);
        
        final target = boardTopLeft + Vector2(gridPos.x * cellSize + cellSize / 2, gridPos.y * cellSize + cellSize / 2);
        final dir = target - position;
        
        if (dir.length > 2) {
            position += dir.normalized() * 500 * dt;
        } else {
            position = target;
        }
    }

    Vector2 _getGridPosition(int tile) {
        if (tile == 0) {
            switch(color) {
                case LudoColor.red: return Vector2(1.5 + (index % 2), 1.5 + (index ~/ 2));
                case LudoColor.green: return Vector2(10.5 + (index % 2), 1.5 + (index ~/ 2));
                case LudoColor.yellow: return Vector2(10.5 + (index % 2), 10.5 + (index ~/ 2));
                case LudoColor.blue: return Vector2(1.5 + (index % 2), 10.5 + (index ~/ 2));
            }
        }

        if (tile > 52) {
            return _getHomePathPosition(tile);
        }
        
        final List<Vector2> track = [
            Vector2(6, 1), Vector2(6, 2), Vector2(6, 3), Vector2(6, 4), Vector2(6, 5),
            Vector2(5, 6), Vector2(4, 6), Vector2(3, 6), Vector2(2, 6), Vector2(1, 6),
            Vector2(0, 6), Vector2(0, 7), Vector2(0, 8), Vector2(1, 8), Vector2(2, 8),
            Vector2(3, 8), Vector2(4, 8), Vector2(5, 8), Vector2(6, 9), Vector2(6, 10),
            Vector2(6, 11), Vector2(6, 12), Vector2(6, 13), Vector2(6, 14), Vector2(7, 14),
            Vector2(8, 14), Vector2(8, 13), Vector2(8, 12), Vector2(8, 11), Vector2(8, 10),
            Vector2(8, 9), Vector2(9, 8), Vector2(10, 8), Vector2(11, 8), Vector2(12, 8),
            Vector2(13, 8), Vector2(14, 8), Vector2(14, 7), Vector2(14, 6), Vector2(13, 6),
            Vector2(12, 6), Vector2(11, 6), Vector2(10, 6), Vector2(9, 6), Vector2(8, 5),
            Vector2(8, 4), Vector2(8, 3), Vector2(8, 2), Vector2(8, 1), Vector2(8, 0),
            Vector2(7, 0), Vector2(6, 0)
        ];

        int adjustedTile = (tile - 1) % 52;
        int offset = 0;
        if (color == LudoColor.yellow) { offset = 13; }
        else if (color == LudoColor.blue) { offset = 25; }
        else if (color == LudoColor.green) { offset = 38; }
        
        return track[(adjustedTile + offset) % track.length];
    }

    Vector2 _getHomePathPosition(int tile) {
        final idx = (tile - 53).toDouble();
        switch (color) {
            case LudoColor.red:
                return Vector2(7.0, 1.0 + idx);
            case LudoColor.green:
                return Vector2(13.0 - idx, 7.0);
            case LudoColor.yellow:
                return Vector2(7.0, 13.0 - idx);
            case LudoColor.blue:
                return Vector2(1.0 + idx, 7.0);
        }
    }

    @override
    void onTapDown(TapDownEvent event) {
        game.onPieceTapped(playerIndex, index);
    }

    @override
    void render(Canvas canvas) {
        final baseColor = _getColor(color);
        final rect = Rect.fromLTWH(0, 0, size.x, size.y);
        

        final gridPos = _getGridPosition(_visualTileIndex);
        final sizeFactor = (game.size.x < game.size.y ? game.size.x : game.size.y) - 40;
        final cellSize = sizeFactor / 15;
        final boardTopLeft = game.size / 2 - Vector2.all(sizeFactor / 2);
        final target = boardTopLeft + Vector2(gridPos.x * cellSize + cellSize / 2, gridPos.y * cellSize + cellSize / 2);
        
        double jumpY = 0;
        final dist = (target - position).length;
        if (dist > 5 || _isStepping) {
            double progress = (_moveTimer / 0.25).clamp(0, 1);
            jumpY = -sin(progress * pi) * 20;
        }


        final shadowPath = Path()..addOval(Rect.fromLTWH(4, size.y - 12 - jumpY/2, size.x - 8, 12));
        canvas.drawShadow(shadowPath, Colors.black, 6, true);
        
        canvas.save();
        canvas.translate(0, jumpY);


        final pegPath = Path();
        final w = size.x;
        final h = size.y;
        

        pegPath.moveTo(w * 0.15, h * 0.95);
        pegPath.quadraticBezierTo(w * 0.5, h * 1.05, w * 0.85, h * 0.95);
        pegPath.lineTo(w * 0.8, h * 0.8);
        

        pegPath.quadraticBezierTo(w * 0.5, h * 0.75, w * 0.2, h * 0.8);
        pegPath.close();


        final bodyPath = Path();
        bodyPath.moveTo(w * 0.25, h * 0.85);
        bodyPath.lineTo(w * 0.35, h * 0.4);
        bodyPath.quadraticBezierTo(w * 0.5, h * 0.3, w * 0.65, h * 0.4);
        bodyPath.lineTo(w * 0.75, h * 0.85);
        bodyPath.close();
        

        final headRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.25), width: w * 0.45, height: h * 0.45);
        

        final paint = _p
            ..shader = RadialGradient(
                colors: [baseColor.lighten(0.3), baseColor, baseColor.darken(0.4)],
                stops: const [0.0, 0.4, 1.0],
            ).createShader(rect);
            
        canvas.drawPath(pegPath, paint);
        canvas.drawPath(bodyPath, paint);
        canvas.drawOval(headRect, paint);
        

        final shinePaint = _p..color = Colors.white.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(w * 0.4, h * 0.2), w * 0.08, shinePaint);
        

        final rimPaint = _p..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.white.withValues(alpha: 0.4);
        canvas.drawOval(headRect, rimPaint);
        canvas.drawPath(bodyPath, rimPaint);
        
        canvas.restore();
    }

    Color _getColor(LudoColor c) {
        switch(c) {
            case LudoColor.red: return const Color(0xFFD32F2F);
            case LudoColor.blue: return const Color(0xFF1976D2);
            case LudoColor.green: return const Color(0xFF388E3C);
            case LudoColor.yellow: return const Color(0xFFFBC02D);
        }
    }
}

class _BoardPainter extends Component with HasGameReference<LudoGame> {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
    @override
    void render(Canvas canvas) {
        final sizeFactor = (game.size.x < game.size.y ? game.size.x : game.size.y) - 40;
        final cellSize = sizeFactor / 15;
        final boardTopLeft = game.size / 2 - Vector2.all(sizeFactor / 2);


        canvas.drawRect(game.size.toRect(), _p..color = const Color(0xFF0F0F1B));
        
        final boardRect = Rect.fromLTWH(boardTopLeft.x, boardTopLeft.y, sizeFactor, sizeFactor);
        

        canvas.drawRRect(RRect.fromRectAndRadius(boardRect.inflate(15), const Radius.circular(20)), _p..color = Colors.cyanAccent.withValues(alpha: 0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
        

        canvas.drawRRect(RRect.fromRectAndRadius(boardRect.inflate(4), const Radius.circular(12)), _p..color = const Color(0xFF1E1E2E));
        canvas.drawRRect(RRect.fromRectAndRadius(boardRect.inflate(4), const Radius.circular(12)), _p..color = Colors.white12..style = PaintingStyle.stroke..strokeWidth = 2);


        for (int i=0; i<15; i++) {
           for (int j=0; j<15; j++) {
              if ((i >= 6 && i <= 8) || (j >= 6 && j <= 8)) {
                  if (!((i<6 && j<6) || (i>8 && j<6) || (i<6 && j>8) || (i>8 && j>8))) {
                       final rect = Rect.fromLTWH(boardTopLeft.x + i*cellSize, boardTopLeft.y + j*cellSize, cellSize, cellSize).deflate(4);
                       _drawNeonCell(canvas, rect, Colors.white10);
                  }
              }
           }
        }


        const safeTiles = [
          Offset(6, 1),
          Offset(0, 6),
          Offset(1, 8),
          Offset(6, 14),
          Offset(8, 14),
          Offset(14, 8),
          Offset(14, 6),
          Offset(8, 0),
        ];
        for (final tile in safeTiles) {
          final center = Offset(boardTopLeft.x + tile.dx * cellSize + cellSize / 2,
              boardTopLeft.y + tile.dy * cellSize + cellSize / 2);
          _drawSafeMarker(canvas, center, cellSize * 0.18);
        }


        _drawCyberBase(canvas, boardTopLeft, cellSize, 0, 0, Colors.redAccent, "NODE 01");
        _drawCyberBase(canvas, boardTopLeft, cellSize, 9, 0, Colors.greenAccent, "NODE 02");
        _drawCyberBase(canvas, boardTopLeft, cellSize, 9, 9, Colors.blueAccent, "NODE 03");
        _drawCyberBase(canvas, boardTopLeft, cellSize, 0, 9, Colors.orangeAccent, "NODE 04");


        for (int i=1; i<6; i++) {
            _drawNeonCell(canvas, Rect.fromLTWH(boardTopLeft.x + i*cellSize, boardTopLeft.y + 7*cellSize, cellSize, cellSize).deflate(4), Colors.redAccent);
            _drawNeonCell(canvas, Rect.fromLTWH(boardTopLeft.x + 7*cellSize, boardTopLeft.y + i*cellSize, cellSize, cellSize).deflate(4), Colors.greenAccent);
            _drawNeonCell(canvas, Rect.fromLTWH(boardTopLeft.x + (14-i)*cellSize, boardTopLeft.y + 7*cellSize, cellSize, cellSize).deflate(4), Colors.blueAccent);
            _drawNeonCell(canvas, Rect.fromLTWH(boardTopLeft.x + 7*cellSize, boardTopLeft.y + (14-i)*cellSize, cellSize, cellSize).deflate(4), Colors.orangeAccent);
        }


        final centerRect = Rect.fromLTWH(boardTopLeft.x+6*cellSize, boardTopLeft.y+6*cellSize, 3*cellSize, 3*cellSize);
        _drawCyberCenter(canvas, centerRect);
    }

    void _drawNeonCell(Canvas canvas, Rect rect, Color color) {
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rrect, _p..color = color.withValues(alpha: 0.1));
        canvas.drawRRect(rrect, _p..color = color.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    void _drawCyberBase(Canvas canvas, Vector2 origin, double cellSize, int gx, int gy, Color color, String label) {
        final rect = Rect.fromLTWH(origin.x + gx * cellSize, origin.y + gy * cellSize, 6 * cellSize, 6 * cellSize).deflate(4);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
        

        canvas.drawRRect(rrect.inflate(5), _p..color = color.withValues(alpha: 0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        

        canvas.drawRRect(rrect, _p..color = const Color(0xFF1E1E2E));
        canvas.drawRRect(rrect, _p..color = color.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 2);


        for (int i=0; i<4; i++) {
            double ox = (i%2 == 0 ? 2 : 4) * cellSize;
            double oy = (i~/2 == 0 ? 2 : 4) * cellSize;
            canvas.drawCircle(Offset(origin.x + gx*cellSize + ox, origin.y + gy*cellSize + oy), cellSize*0.6, _p..color = color.withValues(alpha: 0.1));
            canvas.drawCircle(Offset(origin.x + gx*cellSize + ox, origin.y + gy*cellSize + oy), cellSize*0.5, _p..color = color.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        }
    }

    void _drawCyberCenter(Canvas canvas, Rect rect) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(15)), _p..color = const Color(0xFF1E1E2E));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(15)), _p..color = Colors.cyanAccent.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 3);
        

        final pulse = 0.8 + 0.2 * sin(game._time * 3);
        canvas.drawCircle(rect.center, rect.width * 0.3 * pulse, _p..color = Colors.cyanAccent.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }

    void _drawSafeMarker(Canvas canvas, Offset center, double radius) {
        final path = Path();
        for (int i = 0; i < 5; i++) {
            final angle = (i * 72 - 90) * pi / 180;
            final nextAngle = (i * 72 + 36 - 90) * pi / 180;
            final outer = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
            final inner = Offset(center.dx + cos(nextAngle) * radius * 0.45, center.dy + sin(nextAngle) * radius * 0.45);
            if (i == 0) {
                path.moveTo(outer.dx, outer.dy);
            } else {
                path.lineTo(outer.dx, outer.dy);
            }
            path.lineTo(inner.dx, inner.dy);
        }
        path.close();

        canvas.drawPath(path, _p..color = Colors.white.withValues(alpha: 0.85));
        canvas.drawPath(path, _p..color = Colors.cyanAccent.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
}

class _DynamicLighting extends Component with HasGameReference {
    double time = 0;
    final Paint _paint = Paint();

    @override
    void update(double dt) {
        time += dt;
    }

    @override
    void render(Canvas canvas) {
        final size = game.size;
        final center = size / 2;
        

        final lampPos = Offset(
            center.x + sin(time * 0.5) * 100,
            center.y + cos(time * 0.3) * 100,
        );

        _paint.shader = RadialGradient(
            center: Alignment.center,
            colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent],
            stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: lampPos, radius: size.x * 0.8));
            
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
    }
}

class _TurnOverlay extends Component with HasGameReference<LudoGame> {
  double _timer = 0;
  @override
  void update(double dt) {
    if (!game.isGameOver && !game.players[game.currentPlayerIndex].isBot) {
      _timer += dt;
    } else {
      _timer = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.isGameOver || game.players[game.currentPlayerIndex].isBot) return;
    

    final opacity = (0.2 + 0.2 * sin(_timer * 5)).clamp(0.0, 1.0);
    final paint = Paint()..color = Colors.cyanAccent.withValues(alpha: opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, game.size.x, game.size.y), paint);
    
    final tp = TextPainter(
      text: const TextSpan(
        text: 'YOUR TURN',
        style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 15)])
      ),
      textDirection: TextDirection.ltr
    )..layout();
    tp.paint(canvas, Offset(game.size.x / 2 - tp.width / 2, game.size.y / 2 - tp.height / 2));


    game.logoSprite.render(canvas,
        position: Vector2(game.size.x - 60, 20),
        size: Vector2.all(40),
        overridePaint: Paint()..color = Colors.white.withValues(alpha: 0.25));


    if (_timer < 3.0) {
      final titleTp = TextPainter(
        text: const TextSpan(
          text: 'LUDO MASTER',
          style: TextStyle(color: Colors.white12, fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: 8)
        ),
        textDirection: TextDirection.ltr
      )..layout();
      titleTp.paint(canvas, Offset(game.size.x / 2 - titleTp.width / 2, game.size.y * 0.35));
    }
  }
}

