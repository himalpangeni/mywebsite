
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

class StackWarsGame extends FlameGame {
  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  bool playerWon = false;
  

  final List<int> playerStock = [];
  final List<int> enemyStock = [];
  final List<int> playerHand = [];
  final List<int> centerPiles = [0, 0, 0, 0];
  final List<List<int>> playerDiscards = [[], [], [], []];
  
  bool isPlayerTurn = true;
  late TextComponent turnText;
  late TextComponent statusText;
  late ScreenShake shaker;
  late Sprite logoSprite;

  StackWarsGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF121212);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
  }

  @override
  void onMount() {
    super.onMount();
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
        if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    
    score = 0;
    gameOver = false;
    isPlayerTurn = true;
    
    playerStock.clear();
    enemyStock.clear();
    playerHand.clear();
    for (var d in playerDiscards) {
      d.clear();
    }
    
    final r = Random();
    for (int i = 0; i < 20; i++) {
       playerStock.add(r.nextInt(12) + 1);
       enemyStock.add(r.nextInt(12) + 1);
    }
    
    for (int i = 0; i < 4; i++) {
      centerPiles[i] = 0;
    }
    _refillHand();

    shaker = ScreenShake();
    add(shaker);
    add(_TouchHandler()..size = size);
    turnText = TextComponent(
      text: "YOUR TURN",
      position: Vector2(size.x / 2, 60),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)),
    );
    add(turnText);

    statusText = TextComponent(
      text: "STOCK: ${playerStock.length}  VS  ENEMY: ${enemyStock.length}",
      position: Vector2(size.x / 2, 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white70, fontSize: 16)),
    );
    add(statusText);


    add(TextComponent(
      text: 'STACK WARS',
      position: Vector2(size.x / 2, size.y * 0.45),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.1), fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 10)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 50, 45),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.cyanAccent.withValues(alpha: 0.3),
    ));

    add(_StackRenderer());
    add(CinematicOverlay());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;

    if (playerStock.isNotEmpty) playerStock.removeAt(0);
    _refillHand();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _refillHand() {
    while (playerHand.length < 5) {
      playerHand.add(Random().nextInt(12) + 1);
    }
  }

  void _checkWin() {
    if (playerStock.isEmpty) {
      _endGame(true);
    } else if (enemyStock.isEmpty) {
      _endGame(false);
    }
  }

  void _endGame(bool won) {
    gameOver = true;
    playerWon = won;
    pauseEngine();
    overlays.add('GameOver');
  }

  void _enemyMove() async {
    if (gameOver) return;
    await Future.delayed(const Duration(milliseconds: 1000));

    bool madeMove = true;
    while (madeMove && !gameOver) {
      madeMove = false;


      if (enemyStock.isNotEmpty) {
        int val = enemyStock.first;
        for (int i = 0; i < 4; i++) {
          if (centerPiles[i] + 1 == val || val == 13) {
            _playEnemyCard(val, i, isFromStock: true);
            madeMove = true;
            await Future.delayed(const Duration(milliseconds: 600));
            break;
          }
        }
      }


      if (!madeMove && enemyStock.isNotEmpty) {
        int targetVal = enemyStock.first - 1;
        if (targetVal < 1) targetVal = 12;

        for (int i = 0; i < 4; i++) {
          if (centerPiles[i] + 1 == targetVal && Random().nextDouble() < 0.4) {
            _playEnemyCard(targetVal, i, isFromStock: false);
            madeMove = true;
            await Future.delayed(const Duration(milliseconds: 600));
            break;
          }
        }
      }
      

      if (!madeMove && Random().nextDouble() < 0.3) {
          for (int i = 0; i < 4; i++) {
              int val = centerPiles[i] + 1;
              if (Random().nextDouble() < 0.2) {
                  _playEnemyCard(val, i, isFromStock: false);
                  madeMove = true;
                  await Future.delayed(const Duration(milliseconds: 600));
                  break;
              }
          }
      }
      
      _checkWin();
    }

    isPlayerTurn = true;
    turnText.text = "YOUR TURN";
    turnText.textRenderer = TextPaint(
        style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold));
    _refillHand();
    statusText.text =
        "STOCK: ${playerStock.length}  VS  ENEMY: ${enemyStock.length}";
  }

  void _playEnemyCard(int val, int pileIdx, {required bool isFromStock}) {
    centerPiles[pileIdx] = val == 13 ? centerPiles[pileIdx] + 1 : val;
    if (centerPiles[pileIdx] >= 12) centerPiles[pileIdx] = 0;
    if (isFromStock) enemyStock.removeAt(0);
    shaker.shake(duration: 0.1, intensity: 3);
  }

}

class _TouchHandler extends PositionComponent
    with TapCallbacks, HasGameReference<StackWarsGame> {
  _TouchHandler() : super(anchor: Anchor.topLeft);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final g = game;
    if (g.gameOver || !g.isPlayerTurn) return;
    final pos = event.localPosition;

    int? valToPlay;
    bool fromStock = false;
    int handIdx = -1;


    if (pos.y > g.size.y / 2 - 50 && pos.y < g.size.y / 2 + 50 && pos.x < 150) {
      if (g.playerStock.isNotEmpty) {
        valToPlay = g.playerStock.first;
        fromStock = true;
      }
    }


    if (valToPlay == null) {
      double discardY = g.size.y - 180;
      double discardStartX = g.size.x - 300;
      for (int d = 0; d < 4; d++) {
        if (g.playerDiscards[d].isNotEmpty) {
          double dx = discardStartX + d * 65;
          if (pos.x > dx - 30 && pos.x < dx + 30 && pos.y > discardY - 40 && pos.y < discardY + 40) {
            valToPlay = g.playerDiscards[d].last;
            handIdx = -(d + 1);
            break;
          }
        }
      }
    }


    if (valToPlay == null) {
      double handY = g.size.y - 100;
      if (pos.y > handY - 60 && pos.y < handY + 60) {
        double startX = (g.size.x - (g.playerHand.length * 60)) / 2;
        for (int i = 0; i < g.playerHand.length; i++) {
          if (pos.x > startX + i * 60 - 30 && pos.x < startX + i * 60 + 30) {
            valToPlay = g.playerHand[i];
            handIdx = i;
            break;
          }
        }
      }
    }


    if (valToPlay != null) {
      double centerY = g.size.y / 2;
      double startX = (g.size.x - (4 * 70)) / 2;
      for (int i = 0; i < 4; i++) {
        if (pos.x > startX + i * 70 - 35 &&
            pos.x < startX + i * 70 + 35 &&
            pos.y > centerY - 60 &&
            pos.y < centerY + 60) {
          if (g.centerPiles[i] + 1 == valToPlay || valToPlay == 13) {
            g.centerPiles[i] =
                valToPlay == 13 ? g.centerPiles[i] + 1 : valToPlay;
            if (g.centerPiles[i] >= 12) g.centerPiles[i] = 0;

            if (fromStock) {
              g.playerStock.removeAt(0);
            } else if (handIdx < 0) {
              g.playerDiscards[(-handIdx) - 1].removeLast();
            } else {
              g.playerHand.removeAt(handIdx);
            }

            g.shaker.shake(duration: 0.1, intensity: 5);
            g.score += 10;
            g.statusText.text =
                "STOCK: ${g.playerStock.length}  VS  ENEMY: ${g.enemyStock.length}";
            g._checkWin();
            return;
          }
        }
      }
    }


    if (handIdx >= 0 && valToPlay != null) {
      double discardY = g.size.y - 180;
      double discardStartX = g.size.x - 300;
      for (int d = 0; d < 4; d++) {
        double dx = discardStartX + d * 65;
        if (pos.x > dx - 30 && pos.x < dx + 30 && pos.y > discardY - 40 && pos.y < discardY + 40) {
          g.playerDiscards[d].add(g.playerHand.removeAt(handIdx));
          return;
        }
      }
    }


    if (pos.y > g.size.y - 180 &&
        pos.y < g.size.y - 140 &&
        pos.x > g.size.x - 120) {
      g.isPlayerTurn = false;
      g.turnText.text = "ENEMY TURN";
      g.turnText.textRenderer = TextPaint(
          style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold));
      g._enemyMove();
    }
  }
}

class _StackRenderer extends Component with HasGameReference<StackWarsGame> {
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    

    double centerY = h / 2;
    double startX = (w - (4 * 70)) / 2;
    for (int i = 0; i < 4; i++) {
      _drawCard(canvas, startX + i * 70, centerY, g.centerPiles[i], g.centerPiles[i] == 0 ? "START" : "${g.centerPiles[i]}", Colors.blueGrey);
    }
    

    if (g.playerStock.isNotEmpty) {
      _drawCard(canvas, 50, centerY, g.playerStock.first, "${g.playerStock.first}", Colors.orange);
      _drawText(canvas, 50, centerY + 60, "YOUR STOCK (${g.playerStock.length})", 12);
    }


    if (g.enemyStock.isNotEmpty) {
      _drawCard(canvas, w - 50, centerY, g.enemyStock.first, "?", Colors.red.shade700);
      _drawText(canvas, w - 50, centerY + 60, "ENEMY STOCK (${g.enemyStock.length})", 12);
    }
    

    double discardStartX = w - 300;
    double discardY = h - 180;
    for (int d = 0; d < 4; d++) {
      double dx = discardStartX + d * 65;
      if (g.playerDiscards[d].isNotEmpty) {
        _drawCard(canvas, dx, discardY, g.playerDiscards[d].last, "${g.playerDiscards[d].last}", Colors.teal);
      } else {
        final rect = Rect.fromCenter(center: Offset(dx, discardY), width: 50, height: 75);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = Colors.white10);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1);
      }
    }
    _drawText(canvas, discardStartX + 97, discardY + 55, "DISCARD PILES", 11);
    

    double handY = h - 100;
    double hStartX = (w - (g.playerHand.length * 60)) / 2;
    for (int i = 0; i < g.playerHand.length; i++) {
      _drawCard(canvas, hStartX + i * 60, handY, g.playerHand[i], g.playerHand[i] == 13 ? 'SKIP' : "${g.playerHand[i]}", g.playerHand[i] == 13 ? Colors.purple : Colors.cyan);
    }
    

    final btnRect = Rect.fromLTWH(w - 110, h - 60, 100, 40);
    canvas.drawRRect(RRect.fromRectAndRadius(btnRect, const Radius.circular(8)), Paint()..color = Colors.orangeAccent);
    _drawText(canvas, w - 60, h - 40, "END TURN", 14);
  }

  void _drawCard(Canvas canvas, double x, double y, int val, String label, Color color) {
    final rect = Rect.fromCenter(center: Offset(x, y), width: 50, height: 75);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = color);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = Colors.white30..style = PaintingStyle.stroke..strokeWidth = 2);
    
    final tp = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  void _drawText(Canvas canvas, double x, double y, String text, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: Colors.white70, fontSize: size)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }
}
