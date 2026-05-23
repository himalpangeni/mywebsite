import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import '../../widgets/cinematic_effects.dart';
import '../../models/difficulty.dart';
import '../../services/sensory.dart';

enum UnoCardType { number, skip, reverse, drawTwo, wild, wildDrawFour }

class UnoCard {
  int color;
  final int value;
  final UnoCardType type;

  UnoCard({required this.color, required this.value, required this.type});

  String get name {
     String c = color == 0 ? "Red" : color == 1 ? "Green" : color == 2 ? "Blue" : color == 3 ? "Yellow" : "Wild";
     if (type == UnoCardType.number) return "$c $value";
     if (type == UnoCardType.skip) return "$c Skip";
     if (type == UnoCardType.reverse) return "$c Reverse";
     if (type == UnoCardType.drawTwo) return "$c +2";
     if (type == UnoCardType.wild) return "Wild";
     if (type == UnoCardType.wildDrawFour) return "Wild +4";
     return "Card";
  }
}

class UnoAnimatedCard {
  final UnoCard card;
  final Offset from;
  final Offset to;
  final bool isDraw;
  final bool hideFace;
  final int? targetPlayerIndex;
  double progress = 0;
  final double duration;
  UnoAnimatedCard({required this.card, required this.from, required this.to, this.isDraw = false, this.hideFace = false, this.targetPlayerIndex, this.duration = 0.5});
}

class UnoLightGame extends FlameGame with TapCallbacks {
  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  bool playerWon = false;
  late TextComponent hud;
  late TextComponent instructions;
  late ScreenShake shaker;
  late Sprite logoSprite;
  final int botCount;
  final List<List<UnoCard>> opponents;

  int get playerCount => botCount + 1;

  static const _colors = [
    Color(0xFFD32F2F),
    Color(0xFF388E3C),
    Color(0xFF1976D2),
    Color(0xFFFBC02D),
    Color(0xFF212121),
  ];

  late UnoCard top;
  final List<UnoCard> hand = [];
  int turn = 0;
  int direction = 1;
  int _pendingDrawCount = 0;
  bool _stackActive = false;

  List<String> gameLog = [];
  bool _isDealing = true;
  bool _unoCalled = false;
  double _dealTimer = 0;
  final List<UnoAnimatedCard> _animations = [];
  late UnoTurnOverlay turnOverlay;
  bool _waitingForColorChoice = false;
  UnoCard? _pendingWildCard;

  UnoLightGame({required this.difficulty, required this.botCount}) : opponents = List.generate(botCount, (_) => []);

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void resumeGame() {
    gameOver = false;
    overlays.remove('GameOver');
    resumeEngine();
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
    turn = 0;
    _unoCalled = false;
    direction = 1;
    _pendingDrawCount = 0;
    _stackActive = false;
    hand.clear();
    _isDealing = true;
    _dealTimer = 0;
    _animations.clear();
    for (var o in opponents) {
      o.clear();
    }
    gameLog.clear();
    _logActivity("Game started! Dealing...");

    top = _generateRandomCard(allowWild: false);
    for (var i = 0; i < 7; i++) {
      hand.add(_generateRandomCard());
      for (var o in opponents) {
        o.add(_generateRandomCard());
      }
    }

    add(hud = TextComponent(
      text: 'GET READY',
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              backgroundColor: Colors.black54,
              shadows: [Shadow(blurRadius: 15, color: Colors.cyanAccent)])),
    ));

    add(UnoTurnOverlay());
    add(TextComponent(
      text: 'Players: $playerCount',
      position: Vector2(20, 70),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 6, color: Colors.black)])),
    ));
    add(instructions = TextComponent(
      text: 'TAP a glowing card to play it  •  TAP the deck to draw a card',
      position: Vector2(size.x / 2, size.y - 30),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              backgroundColor: Colors.black54,
              shadows: [Shadow(blurRadius: 6, color: Colors.black)])),
    ));
    add(_AtmosphericBackground());
    add(CinematicOverlay());
    add(_UnoRenderer());
    turnOverlay = UnoTurnOverlay();
    add(turnOverlay);
    resumeEngine();
  }

  void _logActivity(String msg) {
    gameLog.insert(0, msg);
    if (gameLog.length > 5) gameLog.removeLast();
  }

  @override
  void onRemove() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.onRemove();
  }

  UnoCard _generateRandomCard({bool allowWild = true}) {
    final Random r = Random();

    final color = allowWild ? (r.nextInt(6) >= 5 ? 4 : r.nextInt(4)) : r.nextInt(4);
    if (color == 4) {

      return UnoCard(
          color: 4,
          value: r.nextInt(3) == 0 ? 14 : 13,
          type: r.nextInt(3) == 0 ? UnoCardType.wildDrawFour : UnoCardType.wild);
    }

    final val = r.nextInt(15);
    if (val < 12) {
      return UnoCard(color: color, value: r.nextInt(10), type: UnoCardType.number);
    }
    if (val == 12) {
      return UnoCard(color: color, value: 10, type: UnoCardType.skip);
    }
    if (val == 13) {
      return UnoCard(color: color, value: 11, type: UnoCardType.reverse);
    }
    return UnoCard(color: color, value: 12, type: UnoCardType.drawTwo);
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);

    if (_isDealing) {
      _dealTimer += dt;
      if (_dealTimer > 2.0) {
        _isDealing = false;
        hud.text = 'YOUR TURN';
      }
      return;
    }

    for (int i = _animations.length - 1; i >= 0; i--) {
      final a = _animations[i];

      a.progress += dt / a.duration; 
      if (a.progress >= 1.0) {
        if (a.isDraw) {
          if (a.targetPlayerIndex == 0) {
            hand.add(a.card);
          } else if (a.targetPlayerIndex != null) {
            final pidx = a.targetPlayerIndex! - 1;
            opponents[pidx].add(a.card);
          }
        } else {
          top = a.card;
          if (a.targetPlayerIndex == 0) {
            _logActivity("You played ${a.card.name}");
          } else if (a.targetPlayerIndex != null) {
            _logActivity("Player ${a.targetPlayerIndex! + 1} played ${a.card.name}");
          }
          _handleCardEffect(a.card);
          
          if (a.card.type != UnoCardType.number) {
            String msg = '';
            if (a.card.type == UnoCardType.wildDrawFour) { msg = '+4'; }
            else if (a.card.type == UnoCardType.drawTwo) { msg = '+2'; }
            else if (a.card.type == UnoCardType.skip) { msg = 'SKIP'; }
            else if (a.card.type == UnoCardType.reverse) { msg = 'REVERSE'; }
            else if (a.card.type == UnoCardType.wild) { msg = 'WILD'; }
            if (msg.isNotEmpty) {
                turnOverlay.floatingMessage = msg;
                turnOverlay.floatingAge = 0;
            }
          }
          
          _checkWin();
        }
        _animations.removeAt(i);
      }
    }
  }

  void _handleCardEffect(UnoCard card) {
    if (card.type == UnoCardType.skip) {
      _advanceTurn();
    } else if (card.type == UnoCardType.reverse) {
      direction *= -1;
    } else if (card.type == UnoCardType.drawTwo) {

      _pendingDrawCount += 2;
      _stackActive = true;
    } else if (card.type == UnoCardType.wildDrawFour) {

      _pendingDrawCount += 4;
      _stackActive = true;
    }
    _advanceTurn();
  }

  void _advanceTurn() {
    var next = (turn + direction) % playerCount;
    if (next < 0) next += playerCount;
    turn = next;
    if (turn == 0) {
      hud.text = _stackActive ? 'YOUR TURN — +$_pendingDrawCount PENDING!' : 'YOUR TURN';
    } else {
      hud.text = _stackActive ? 'Player ${turn + 1} faces +$_pendingDrawCount...' : 'Player ${turn + 1} thinking...';

      final delay = 2500 + Random().nextInt(2000);
      Future.delayed(Duration(milliseconds: delay), _botPlay);
    }
  }

  void _botPlay() {
    if (gameOver || turn == 0) return;
    final botHand = opponents[turn - 1];


    if (_stackActive) {

      final stackIdx = botHand.indexWhere((c) =>
          (c.type == UnoCardType.drawTwo && top.type == UnoCardType.drawTwo) ||
          (c.type == UnoCardType.wildDrawFour && top.type == UnoCardType.wildDrawFour) ||
          (c.type == UnoCardType.wildDrawFour)
      );
      if (stackIdx >= 0) {

        final c = botHand.removeAt(stackIdx);
        if (c.color == 4) c.color = _aiBestColor(botHand);
        _animations.add(UnoAnimatedCard(
            card: c,
            from: Offset(turn == 1 ? size.x * 0.2 : (turn == 2 ? size.x / 2 : size.x * 0.8), 80),
            to: Offset(size.x / 2 - 40, size.y * 0.4 - 60),
            hideFace: true,
            duration: 0.8,
            targetPlayerIndex: turn));
        return;
      } else {

        _logActivity("Player ${turn + 1} draws $_pendingDrawCount cards!");
        hud.text = 'Player ${turn + 1} draws $_pendingDrawCount!';
        final drawCount = _pendingDrawCount;
        _pendingDrawCount = 0;
        _stackActive = false;
        final toPos = Offset(turn == 1 ? size.x * 0.2 : (turn == 2 ? size.x / 2 : size.x * 0.8), 80);
        for (int i = 0; i < drawCount; i++) {
          final c = _generateRandomCard();
          _animations.add(UnoAnimatedCard(
              card: c,
              from: Offset(size.x / 2 + 65, size.y * 0.4 - 65),
              to: toPos,
              isDraw: true,
              hideFace: true,
              duration: 0.6,
              targetPlayerIndex: turn));
        }
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!gameOver) _advanceTurn();
        });
        return;
      }
    }



    final hasPlayable = botHand.any((c) => _canPlay(c, top));
    final botMisses = Random().nextInt(10) < 3;
    final idx = (hasPlayable && !botMisses) ? botHand.indexWhere((c) => _canPlay(c, top)) : -1;
    if (idx >= 0) {
      final c = botHand.removeAt(idx);

      if (c.color == 4) {
        c.color = Random().nextInt(10) < 4 ? Random().nextInt(4) : _aiBestColor(botHand);
      }
      _animations.add(UnoAnimatedCard(
          card: c,
          from: Offset(turn == 1 ? size.x * 0.2 : (turn == 2 ? size.x / 2 : size.x * 0.8), 80),
          to: Offset(size.x / 2 - 40, size.y * 0.4 - 60),
          hideFace: true,
          duration: 0.8,
          targetPlayerIndex: turn));
    } else {
      final c = _generateRandomCard();
      _animations.add(UnoAnimatedCard(
          card: c,
          from: Offset(size.x / 2 + 65, size.y * 0.4 - 65),
          to: Offset(turn == 1 ? size.x * 0.2 : (turn == 2 ? size.x / 2 : size.x * 0.8), 80),
          isDraw: true,
          hideFace: true,
          duration: 0.6,
          targetPlayerIndex: turn));
      hud.text = 'Player ${turn + 1} drew a card';
      _logActivity("Player ${turn + 1} drew a card");
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!gameOver) _advanceTurn();
      });
      return;
    }
  }

  int _aiBestColor(List<UnoCard> hand) {
    final counts = [0, 0, 0, 0];
    for (var c in hand) {
      if (c.color < 4) counts[c.color]++;
    }
    int best = 0;
    for (int i = 1; i < 4; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    return best;
  }

  bool _canPlay(UnoCard a, UnoCard b) {
    if (a.color == 4) return true;
    if (a.color == b.color) return true;
    if (a.value == b.value && a.type == b.type && a.type == UnoCardType.number) return true;

    if (a.type == b.type && a.type != UnoCardType.number) return true;
    return false;
  }

  void _checkWin() {
    if (hand.isEmpty) {
      playerWon = true;
      gameOver = true;
      add(ConfettiEmitter());
      overlays.add('GameOver');
      return;
    }
    for (int i = 0; i < opponents.length; i++) {
      if (opponents[i].isEmpty) {
        playerWon = false;
        gameOver = true;
        overlays.add('GameOver');
        return;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver || _isDealing) return;
    final p = event.localPosition;


    if (_waitingForColorChoice) {
      final cx = size.x / 2;
      final cy = size.y / 2;
      const boxSize = 70.0;
      const gap = 10.0;
      for (int i = 0; i < 4; i++) {
        final bx = cx - (2 * boxSize + 1.5 * gap) + i * (boxSize + gap);
        final by = cy - boxSize / 2;
        if (Rect.fromLTWH(bx, by, boxSize, boxSize).contains(p.toOffset())) {
          _waitingForColorChoice = false;
          if (_pendingWildCard != null) {
            _pendingWildCard!.color = i;
            top = _pendingWildCard!;
            _handleCardEffect(_pendingWildCard!);
            _pendingWildCard = null;
            _checkWin();
          }
          return;
        }
      }
      return;
    }

    if (turn != 0) return;


    if (hand.length <= 2 &&
        Rect.fromLTWH(size.x - 120, size.y / 2 - 40, 100, 80)
            .contains(p.toOffset())) {
      _unoCalled = true;
      SensoryService.heavyImpact();
      hud.text = "UNO CALLED!";
      return;
    }


    if (Rect.fromLTWH(size.x / 2 + 60, size.y * 0.4 - 60, 80, 120)
        .contains(p.toOffset())) {
      _unoCalled = false;


      if (_stackActive) {
        final drawCount = _pendingDrawCount;
        _pendingDrawCount = 0;
        _stackActive = false;
        _logActivity("You draw $drawCount cards!");
        hud.text = 'YOU DRAW $drawCount CARDS!';
        for (int i = 0; i < drawCount; i++) {
          final c = _generateRandomCard();
          _animations.add(UnoAnimatedCard(
              card: c,
              from: Offset(size.x / 2 + 65, size.y * 0.4 - 65),
              to: Offset(size.x / 2, size.y - 120),
              isDraw: true,
              duration: 0.4,
              targetPlayerIndex: 0));
        }
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!gameOver) _advanceTurn();
        });
        return;
      }


      hud.text = 'YOU DREW A CARD';
      _logActivity("You drew a card");
      final c = _generateRandomCard();
      _animations.add(UnoAnimatedCard(
          card: c,
          from: Offset(size.x / 2 + 65, size.y * 0.4 - 65),
          to: Offset(size.x / 2, size.y - 120),
          isDraw: true,
          duration: 0.4,
          targetPlayerIndex: 0));
      
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!gameOver) _advanceTurn();
      });
      return;
    }
    

    final cardW = min(80.0, (size.x - 40) / max(hand.length, 1));
    for (int i = 0; i < hand.length; i++) {
        final rect = Rect.fromLTWH(20 + i * cardW, size.y - 130, cardW, 120);
        if (rect.contains(p.toOffset())) {

            if (_stackActive) {
              final card = hand[i];
              final canStack = 
                  (card.type == UnoCardType.drawTwo && top.type == UnoCardType.drawTwo) ||
                  (card.type == UnoCardType.wildDrawFour && top.type == UnoCardType.wildDrawFour) ||
                  (card.type == UnoCardType.wildDrawFour);
              if (!canStack) {
                shaker.shake(duration: 0.2, intensity: 5);
                hud.text = 'PLAY A + CARD OR TAP DECK TO DRAW $_pendingDrawCount!';
                return;
              }

              if (hand.length == 2 && !_unoCalled) {

                hud.text = "DON'T FORGET TO CALL UNO!";
                shaker.shake(duration: 0.2, intensity: 3);
              }
              final c = hand.removeAt(i);
              _unoCalled = false;
              if (c.color == 4) {
                _pendingWildCard = c;
                _waitingForColorChoice = true;
                _animations.add(UnoAnimatedCard(
                    card: c,
                    from: Offset(20 + i * cardW, size.y - 130),
                    to: Offset(size.x / 2 - 40, size.y * 0.4 - 60),
                    targetPlayerIndex: 0));
                hud.text = 'CHOOSE A COLOR';
                score += 50;
              } else {
                _animations.add(UnoAnimatedCard(
                    card: c,
                    from: Offset(20 + i * cardW, size.y - 130),
                    to: Offset(size.x / 2 - 40, size.y * 0.4 - 60),
                    targetPlayerIndex: 0));
                score += 50;
              }
              return;
            }


            if (_canPlay(hand[i], top)) {
                if (hand.length == 2 && !_unoCalled) {
                   for (int j = 0; j < 2; j++) {
                     hand.add(_generateRandomCard());
                   }
                   hud.text = "FORGOT UNO! +2 CARDS";
                   shaker.shake(duration: 0.3, intensity: 8);
                }
                final c = hand.removeAt(i);
                _unoCalled = false;
                

                if (c.color == 4) {
                  _pendingWildCard = c;
                  _waitingForColorChoice = true;
                  _animations.add(UnoAnimatedCard(
                      card: c,
                      from: Offset(20 + i * cardW, size.y - 130),
                      to: Offset(size.x / 2 - 40, size.y * 0.4 - 60),
                      targetPlayerIndex: 0));
                  hud.text = 'CHOOSE A COLOR';
                  score += 50;
                } else {
                  _animations.add(UnoAnimatedCard(
                      card: c,
                      from: Offset(20 + i * cardW, size.y - 130),
                      to: Offset(size.x / 2 - 40, size.y * 0.4 - 60),
                      targetPlayerIndex: 0));
                  score += 50;
                }
            } else {
                shaker.shake(duration: 0.2, intensity: 5);
            }
            return;
        }
    }
  }
}

class _UnoRenderer extends Component with HasGameReference<UnoLightGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    _drawCard(canvas, Offset(w / 2 - 45, h * 0.4 - 65), 90, 130, game.top);


    final deckRect = Rect.fromLTWH(w / 2 + 65, h * 0.4 - 65, 90, 130);
    final deckPaint = _p
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(deckRect, const Radius.circular(10)),
        deckPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(deckRect, const Radius.circular(10)),
        _p
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    final deckLabel = TextPainter(
        text: const TextSpan(
            text: 'DECK',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout();
    deckLabel.paint(canvas, Offset(deckRect.center.dx - deckLabel.width / 2, deckRect.top - 18));


    const logoSize = 60.0;
    game.logoSprite.render(canvas,
        position: Vector2(deckRect.center.dx - logoSize / 2,
            deckRect.center.dy - logoSize / 2),
        size: Vector2.all(logoSize));


    if (game.hand.length <= 2) {
        final unoRect = Rect.fromLTWH(w - 120, h / 2 - 40, 100, 80);
        final paint = _p..color = game._unoCalled ? Colors.yellow : Colors.redAccent;
        canvas.drawRRect(RRect.fromRectAndRadius(unoRect, const Radius.circular(15)), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(unoRect.deflate(4), const Radius.circular(12)), _p..color = Colors.black38);
        
        TextPainter(
            text: TextSpan(
                text: 'UNO',
                style: TextStyle(
                    fontSize: 24,
                    color: game._unoCalled ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
            textDirection: TextDirection.ltr)
          ..layout()
          ..paint(canvas, unoRect.center - const Offset(28, 14));
    }

    for (var a in game._animations) {
      final pos = Offset.lerp(a.from, a.to, a.progress)!;
      _drawCard(canvas, pos, 90, 130, a.card, hideFace: a.hideFace);
    }


    final cardW = min(80.0, (w - 40) / max(game.hand.length, 1));
    for (int i = 0; i < game.hand.length; i++) {
      _drawCard(canvas, Offset(20 + i * cardW, h - 130), cardW.clamp(50, 80), 120,
          game.hand[i],
          isPlayable: game._canPlay(game.hand[i], game.top));
    }


    final oppPos = <Offset>[];
    if (g.botCount == 1) {
      oppPos.add(Offset(w / 2, 80));
    } else if (g.botCount == 2) {
      oppPos.addAll([Offset(w * 0.3, 80), Offset(w * 0.7, 80)]);
    } else {
      oppPos.addAll([Offset(w * 0.18, 80), Offset(w / 2, 80), Offset(w * 0.82, 80)]);
    }
    for (int i = 0; i < g.opponents.length; i++) {
      final pos = oppPos[i];
      final active = g.turn == i + 1;
      final cardCount = g.opponents[i].length;


      TextPainter(
          text: TextSpan(
              text: 'Player ${i + 2}${active ? ' ●' : ''}',
              style: TextStyle(
                  fontSize: 14,
                  color: active ? Colors.yellow : Colors.white70,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr)
        ..layout()
        ..paint(canvas, pos - const Offset(40, 55));


      final fanCount = cardCount.clamp(1, 7);
      for (int c = 0; c < fanCount; c++) {
        final angle = -0.3 + (c / (fanCount - 1).clamp(1, 6)) * 0.6;
        final cardOffset = Offset(cos(angle) * 20, -sin(angle.abs()) * 10 - 25);
        canvas.save();
        canvas.translate(pos.dx + cardOffset.dx, pos.dy + cardOffset.dy);
        canvas.rotate(angle);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 35, height: 50), const Radius.circular(5)),
            _p..color = const Color(0xFF1A237E));
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 35, height: 50), const Radius.circular(5)),
            _p..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

        game.logoSprite.render(canvas,
            position: Vector2(-12, -17),
            size: Vector2(24, 24));
        canvas.restore();
      }


      canvas.drawCircle(pos + const Offset(20, -40), 12,
          _p..color = (active ? Colors.yellow : Colors.white24)..style = PaintingStyle.fill);
      TextPainter(
          text: TextSpan(
              text: '$cardCount',
              style: TextStyle(
                  fontSize: 13,
                  color: active ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr)
        ..layout()
        ..paint(canvas, pos + const Offset(12, -48));
    }


    TextPainter(
        text: const TextSpan(
            text: 'Player 1 (YOU)',
            style: TextStyle(
                fontSize: 16,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(20, h - 155));


    if (game.gameLog.isNotEmpty) {
      final logRect = Rect.fromLTWH(20, 100, 220, 20 + game.gameLog.length * 20.0);
      canvas.drawRRect(RRect.fromRectAndRadius(logRect, const Radius.circular(8)), 
        Paint()..color = Colors.black54);
      canvas.drawRRect(RRect.fromRectAndRadius(logRect, const Radius.circular(8)), 
        Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1);
      
      double ly = 105;
      for (int i = 0; i < game.gameLog.length; i++) {
        final tp = TextPainter(
          text: TextSpan(text: game.gameLog[i], style: TextStyle(color: i == 0 ? Colors.white : Colors.white60, fontSize: 13, fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal)),
          textDirection: TextDirection.ltr
        )..layout();
        tp.paint(canvas, Offset(30, ly));
        ly += 20;
      }
    }


    if (game._waitingForColorChoice) {

      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black54);
      

      final titleTp = TextPainter(
        text: const TextSpan(
          text: 'CHOOSE A COLOR',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 15)]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      titleTp.paint(canvas, Offset(w / 2 - titleTp.width / 2, h / 2 - 80));
      

      final pickerColors = [Colors.red, Colors.green, Colors.blue, Colors.yellow];
      final labels = ['RED', 'GREEN', 'BLUE', 'YELLOW'];
      const boxSize = 70.0;
      const gapSize = 10.0;
      for (int i = 0; i < 4; i++) {
        final bx = w / 2 - (2 * boxSize + 1.5 * gapSize) + i * (boxSize + gapSize);
        final by = h / 2 - boxSize / 2;
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, boxSize, boxSize), const Radius.circular(12));
        canvas.drawRRect(r, Paint()..color = pickerColors[i]);
        canvas.drawRRect(r, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
        
        final labelTp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        labelTp.paint(canvas, Offset(bx + boxSize / 2 - labelTp.width / 2, by + boxSize + 6));
      }
    }
  }

  void _drawCard(Canvas canvas, Offset o, double cw, double ch, UnoCard card,
      {bool isPlayable = true, bool hideFace = false}) {
    final rect = Rect.fromLTWH(o.dx, o.dy, cw, ch);
    if (hideFace) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          Paint()..color = const Color(0xFF2C3E50));
      

      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(8)),
          Paint()
            ..color = Colors.white24
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);


      canvas.drawCircle(rect.center, cw * 0.35, Paint()..color = Colors.redAccent.withValues(alpha: 0.8));
      canvas.drawCircle(rect.center, cw * 0.35, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

      game.logoSprite.render(canvas,
          position: Vector2(rect.center.dx - cw * 0.2, rect.center.dy - cw * 0.2),
          size: Vector2.all(cw * 0.4));
          
      final tp = TextPainter(
          text: const TextSpan(
              text: 'UNO',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, rect.center - Offset(tp.width / 2, -cw * 0.22));
      return;
    }
    final baseColor = UnoLightGame._colors[card.color]
        .withValues(alpha: isPlayable ? 1.0 : 0.4);
    final labelSize = max(16.0, cw * 0.35);
    final playableGlow = Paint()
      ..color = Colors.white.withValues(alpha: isPlayable ? 0.25 : 0.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPlayable ? 3 : 0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);


    canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.shift(const Offset(2, 2)), const Radius.circular(10)),
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));


    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()..color = baseColor);


    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);


    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-pi / 10);
    final ovalRect = Rect.fromCenter(
        center: Offset.zero, width: cw * 0.85, height: ch * 0.65);
    canvas.drawOval(
        ovalRect, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.restore();


    String label;
    switch (card.type) {
      case UnoCardType.number:
        label = '${card.value}';
        break;
      case UnoCardType.skip:
        label = 'SKIP';
        break;
      case UnoCardType.reverse:
        label = 'REV';
        break;
      case UnoCardType.drawTwo:
        label = '+2';
        break;
      case UnoCardType.wild:
        label = 'WILD';
        break;
      case UnoCardType.wildDrawFour:
        label = '+4';
        break;
    }

    if (card.type == UnoCardType.wildDrawFour || card.type == UnoCardType.wild) {

      _drawFourColors(canvas, rect.center, cw * 0.45, isPlusFour: card.type == UnoCardType.wildDrawFour);
    } else {
      final tp = TextPainter(
          text: TextSpan(
              text: label,
              style: TextStyle(
                  color: baseColor == const Color(0xFFFBC02D) ? Colors.black : Colors.white,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
    }


    if (isPlayable && game.turn == 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(14)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(12)),
          playableGlow);
    }


    final cornerStyle = TextStyle(
        color: Colors.white, fontSize: cw * 0.22, fontWeight: FontWeight.bold);
    void drawCorner(double tx, double ty, bool flipped) {
      if (card.type == UnoCardType.wild || card.type == UnoCardType.wildDrawFour) {
          canvas.save();
          canvas.translate(tx, ty);
          if (flipped) canvas.rotate(pi);
          _drawFourColors(canvas, Offset.zero, cw * 0.25, isPlusFour: false);
          canvas.restore();
          return;
      }
      canvas.save();
      canvas.translate(tx, ty);
      if (flipped) canvas.rotate(pi);
      final ctp = TextPainter(
          text: TextSpan(text: label, style: cornerStyle),
          textDirection: TextDirection.ltr)
        ..layout();
      ctp.paint(canvas, Offset(-ctp.width / 2, -ctp.height / 2));
      canvas.restore();
    }

    drawCorner(o.dx + 12, o.dy + 12, false);
    drawCorner(o.dx + cw - 12, o.dy + ch - 12, true);


    if (isPlayable && game.turn == 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(12)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  void _drawFourColors(Canvas canvas, Offset center, double size, {bool isPlusFour = true}) {
    final colors = [
      UnoLightGame._colors[0],
      UnoLightGame._colors[1],
      UnoLightGame._colors[2],
      UnoLightGame._colors[3]
    ];
    final rectSize = size * 0.6;
    final offsets = [
      Offset(-size / 4, -size / 4),
      Offset(size / 4, -size / 4),
      Offset(-size / 4, size / 4),
      Offset(size / 4, size / 4)
    ];
    for (int i = 0; i < 4; i++) {
      final r = Rect.fromCenter(
          center: center + offsets[i], width: rectSize, height: rectSize * 1.2);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()..color = colors[i]);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
    if (isPlusFour) {

      final tp = TextPainter(
          text: const TextSpan(
              text: '+4',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }
}

class UnoTurnOverlay extends Component with HasGameReference<UnoLightGame> {
  double _timer = 0;
  String floatingMessage = '';
  double floatingAge = 0;
  @override
  void update(double dt) {
    if (game.turn == 0) {
      _timer += dt;
    } else {
      _timer = 0;
    }
    if (floatingMessage.isNotEmpty) {
      floatingAge += dt;
      if (floatingAge > 2.0) floatingMessage = '';
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.turn != 0 || game.gameOver || game._isDealing) return;
    

    final opacity = (0.2 + 0.2 * sin(_timer * 5)).clamp(0.0, 1.0);
    final paint = Paint()..color = Colors.cyanAccent.withValues(alpha: opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, game.size.x, game.size.y), paint);
    
    final tp = TextPainter(
      text: const TextSpan(
        text: 'YOUR TURN',
        style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 15)])
      ),
      textDirection: TextDirection.ltr
    )..layout();
    tp.paint(canvas, Offset(game.size.x / 2 - tp.width / 2, game.size.y / 2 - tp.height / 2));


    if (_timer < 3.0) {
      final titleTp = TextPainter(
        text: const TextSpan(
          text: 'UNO RUSH',
          style: TextStyle(color: Colors.white10, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: 10)
        ),
        textDirection: TextDirection.ltr
      )..layout();
      titleTp.paint(canvas, Offset(game.size.x / 2 - titleTp.width / 2, game.size.y * 0.3));
    }
    

    game.logoSprite.render(canvas,
      position: Vector2(game.size.x - 60, 20),
      size: Vector2.all(40),
      overridePaint: Paint()..color = Colors.white.withValues(alpha: 0.25));


    if (floatingMessage.isNotEmpty) {
      final alpha = (1.0 - (floatingAge / 2.0)).clamp(0.0, 1.0);
      final msgTp = TextPainter(
        text: TextSpan(
          text: floatingMessage,
          style: TextStyle(
            color: Colors.yellow.withValues(alpha: alpha),
            fontSize: 64,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black.withValues(alpha: alpha), blurRadius: 20)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final yOff = game.size.y * 0.35 - floatingAge * 30;
      msgTp.paint(canvas, Offset(game.size.x / 2 - msgTp.width / 2, yOff));
    }
  }
}

class _AtmosphericBackground extends Component with HasGameReference<UnoLightGame> {
  Color _currentColor = const Color(0xFF0D47A1);
  @override
  void render(Canvas canvas) {
    final target = game.top.color == 4 
      ? const Color(0xFF212121) 
      : UnoLightGame._colors[game.top.color].darken(0.6);
    
    _currentColor = Color.lerp(_currentColor, target, 0.05)!;
    
    final rect = game.size.toRect();
    canvas.drawRect(rect, Paint()..color = _currentColor);
    

    canvas.drawCircle(
      game.size.toOffset() / 2, 
      game.size.x * 0.7, 
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent],
        ).createShader(rect)
    );
  }
}

class FloatingText extends PositionComponent {
  final String text;
  final Color color;
  double life = 1.0;
  FloatingText(this.text, Vector2 position, this.color) {
    this.position = position;
  }
  @override
  void update(double dt) {
     position.y -= 70 * dt;
     life -= dt;
     if (life <= 0) removeFromParent();
  }
  @override
  void render(Canvas canvas) {
     final tp = TextPainter(
       text: TextSpan(text: text, style: TextStyle(color: color.withValues(alpha: life.clamp(0, 1)), fontSize: 44, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black.withValues(alpha: life.clamp(0,1)), blurRadius: 15)])),
       textDirection: TextDirection.ltr)..layout();
     tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}

