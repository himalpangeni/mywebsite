import 'dart:ui' hide TextStyle;
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/difficulty.dart';


enum Suit { hearts, diamonds, clubs, spades }

class CardData {
  final int rank;
  final Suit suit;
  bool isFaceUp = false;
  CardData(this.rank, this.suit);
  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;
  
  String get rankStr => rank == 1 ? 'A' : (rank == 11 ? 'J' : (rank == 12 ? 'Q' : (rank == 13 ? 'K' : rank.toString())));
  String get suitStr => suit == Suit.hearts ? '♥' : (suit == Suit.diamonds ? '♦' : (suit == Suit.clubs ? '♣' : '♠'));
}

class Pile {
  final List<CardData> cards = [];
  double x, y;
  Pile(this.x, this.y);
}

class SolitaireBoardState {
  final List<CardData> stock;
  final List<CardData> waste;
  final List<List<CardData>> foundations;
  final List<List<CardData>> tableaus;
  SolitaireBoardState(this.stock, this.waste, this.foundations, this.tableaus);
}

class SolitaireGame extends FlameGame with TapCallbacks, DragCallbacks {
  late Sprite logoSprite;
  
  List<CardData> deck = [];
  Pile stock = Pile(0,0);
  Pile waste = Pile(0,0);
  List<Pile> foundations = [];
  List<Pile> tableaus = [];
  
  List<CardData> draggedStack = [];
  Pile? sourcePile;
  Vector2 dragOffset = Vector2.zero();
  Vector2 currentDragPos = Vector2.zero();
  
  bool isGameOver = false;

  List<SolitaireBoardState> moveHistory = [];
  late SolitaireBoardState initialState;
  CardData? hintedCard;
  double hintTimer = 0;


  double cardW = 70;
  double cardH = 100;
  double colSpacing = 80;
  double _padding = 10;

  final GameDifficulty difficulty;
  SolitaireGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF0A5C1C);

  @override
  Future<void> onLoad() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    logoSprite = await loadSprite('logo.png');
    _computeLayout();
    _initGame();
  }

  @override
  void onRemove() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _computeLayout();
  }

  void _computeLayout() {

    _padding = size.x * 0.02;
    colSpacing = (size.x - _padding * 2) / 7;
    cardW = colSpacing - 8;
    cardH = cardW * 1.45;

    cardW = cardW.clamp(45, 90);
    cardH = cardH.clamp(65, 130);
    colSpacing = cardW + 8;

    final startX = (size.x - 7 * colSpacing) / 2 + 4;

    stock.x = startX; stock.y = _padding + 10;
    waste.x = startX + colSpacing; waste.y = _padding + 10;

    if (foundations.isEmpty) {
      foundations = [
        Pile(startX + 3 * colSpacing, _padding + 10),
        Pile(startX + 4 * colSpacing, _padding + 10),
        Pile(startX + 5 * colSpacing, _padding + 10),
        Pile(startX + 6 * colSpacing, _padding + 10),
      ];
    } else {
      for (int i = 0; i < 4; i++) {
        foundations[i].x = startX + (3 + i) * colSpacing;
        foundations[i].y = _padding + 10;
      }
    }

    if (tableaus.isEmpty) {
      tableaus = List.generate(7, (i) => Pile(startX + i * colSpacing, _padding + cardH + 30));
    } else {
      for (int i = 0; i < 7; i++) {
        tableaus[i].x = startX + i * colSpacing;
        tableaus[i].y = _padding + cardH + 30;
      }
    }
  }

  void _initGame() {
    deck.clear();
    isGameOver = false;
    for (var f in foundations) {
      f.cards.clear();
    }
    for (var t in tableaus) {
      t.cards.clear();
    }

    for (var suit in Suit.values) {
      for (int r = 1; r <= 13; r++) {
        deck.add(CardData(r, suit));
      }
    }
    deck.shuffle();
    
    stock.cards.clear();
    waste.cards.clear();

    for (int i = 0; i < 7; i++) {
      for (int j = 0; j <= i; j++) {
        var c = deck.removeLast();
        if (j == i) c.isFaceUp = true;
        tableaus[i].cards.add(c);
      }
    }
    stock.cards.addAll(deck);
    deck.clear();
    overlays.remove('GameOver');
    overlays.remove('DeadEnd');
    overlays.add('SolitaireControls');
    moveHistory.clear();
    initialState = SolitaireBoardState(
      stock.cards.map((c) => CardData(c.rank, c.suit)..isFaceUp = c.isFaceUp).toList(),
      waste.cards.map((c) => CardData(c.rank, c.suit)..isFaceUp = c.isFaceUp).toList(),
      foundations.map((p) => p.cards.map((c) => CardData(c.rank, c.suit)..isFaceUp = c.isFaceUp).toList()).toList(),
      tableaus.map((p) => p.cards.map((c) => CardData(c.rank, c.suit)..isFaceUp = c.isFaceUp).toList()).toList(),
    );
  }

  void _saveState() {
    moveHistory.add(SolitaireBoardState(
      stock.cards.map((c) => CardData(c.rank, c.suit)..isFaceUp = c.isFaceUp).toList(),
      waste.cards.map((c) => CardData(c.rank, c.suit)..isFaceUp = c.isFaceUp).toList(),
      foundations.map((p) => p.cards.map((c) => CardData(c.rank, c.suit)..isFaceUp = c.isFaceUp).toList()).toList(),
      tableaus.map((p) => p.cards.map((c) => CardData(c.rank, c.suit)..isFaceUp = c.isFaceUp).toList()).toList(),
    ));
    if (moveHistory.length > 50) moveHistory.removeAt(0);
  }

  void undoLastMove() {
    if (moveHistory.isEmpty || foundations.every((f) => f.cards.length == 13)) return;
    final state = moveHistory.removeLast();
    stock.cards.clear(); stock.cards.addAll(state.stock);
    waste.cards.clear(); waste.cards.addAll(state.waste);
    for (int i = 0; i < 4; i++) {
       foundations[i].cards.clear();
       foundations[i].cards.addAll(state.foundations[i]);
    }
    for (int i = 0; i < 7; i++) {
       tableaus[i].cards.clear();
       tableaus[i].cards.addAll(state.tableaus[i]);
    }
    hintedCard = null;
    isGameOver = false;
    overlays.remove('DeadEnd');
  }

  void undoAllMoves() {
    if (foundations.every((f) => f.cards.length == 13)) return;
    stock.cards.clear(); stock.cards.addAll(initialState.stock);
    waste.cards.clear(); waste.cards.addAll(initialState.waste);
    for (int i = 0; i < 4; i++) {
       foundations[i].cards.clear();
       foundations[i].cards.addAll(initialState.foundations[i]);
    }
    for (int i = 0; i < 7; i++) {
       tableaus[i].cards.clear();
       tableaus[i].cards.addAll(initialState.tableaus[i]);
    }
    hintedCard = null;
    moveHistory.clear();
    isGameOver = false;
    overlays.remove('DeadEnd');
  }

  bool _hasMoves() {

    if (stock.cards.isNotEmpty) return true;
    if (waste.cards.isNotEmpty) {
      final c = waste.cards.last;
      for (var f in foundations) {
        if ((f.cards.isEmpty && c.rank == 1) ||
            (f.cards.isNotEmpty && f.cards.last.suit == c.suit && f.cards.last.rank + 1 == c.rank)) {
          return true;
        }
      }
      for (var t in tableaus) {
        if ((t.cards.isEmpty && c.rank == 13) ||
            (t.cards.isNotEmpty && t.cards.last.isFaceUp && t.cards.last.isRed != c.isRed && t.cards.last.rank - 1 == c.rank)) {
          return true;
        }
      }
    }
    for (var t1 in tableaus) {
      if (t1.cards.isEmpty) continue;
      final c = t1.cards.last;
      for (var f in foundations) {
        if ((f.cards.isEmpty && c.rank == 1) ||
            (f.cards.isNotEmpty && f.cards.last.suit == c.suit && f.cards.last.rank + 1 == c.rank)) {
          return true;
        }
      }
      
      int splitIdx = t1.cards.indexWhere((c) => c.isFaceUp);
      if (splitIdx != -1) {
        final sc = t1.cards[splitIdx];
        for (var t2 in tableaus) {
          if (t1 == t2) continue;
          if ((t2.cards.isEmpty && sc.rank == 13 && splitIdx > 0) ||
              (t2.cards.isNotEmpty && t2.cards.last.isFaceUp && t2.cards.last.isRed != sc.isRed && t2.cards.last.rank - 1 == sc.rank)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _checkDeadEnd() {
    if (isGameOver) return;
    if (!_hasMoves()) {
      isGameOver = true;
      overlays.add('DeadEnd');
    }
  }

  void showHint() {
    if (isGameOver) return;

    if (waste.cards.isNotEmpty) {
      final c = waste.cards.last;
      for (var f in foundations) {
        if ((f.cards.isEmpty && c.rank == 1) ||
            (f.cards.isNotEmpty && f.cards.last.suit == c.suit && f.cards.last.rank + 1 == c.rank)) {
          hintedCard = c;
          hintTimer = 2.0;
          return;
        }
      }
    }

    for (var t in tableaus) {
      if (t.cards.isNotEmpty) {
        final c = t.cards.last;
        for (var f in foundations) {
          if ((f.cards.isEmpty && c.rank == 1) ||
              (f.cards.isNotEmpty && f.cards.last.suit == c.suit && f.cards.last.rank + 1 == c.rank)) {
            hintedCard = c;
            hintTimer = 2.0;
            return;
          }
        }
      }
    }

    if (waste.cards.isNotEmpty) {
      final c = waste.cards.last;
      for (var t in tableaus) {
        if ((t.cards.isEmpty && c.rank == 13) ||
            (t.cards.isNotEmpty && t.cards.last.isFaceUp && t.cards.last.isRed != c.isRed && t.cards.last.rank - 1 == c.rank)) {
          hintedCard = c;
          hintTimer = 2.0;
          return;
        }
      }
    }

    for (var t1 in tableaus) {
      if (t1.cards.isEmpty) continue;

      int splitIdx = t1.cards.indexWhere((c) => c.isFaceUp);
      if (splitIdx == -1) continue;
      final c = t1.cards[splitIdx];

      if (splitIdx == 0 && c.rank == 13) continue;
      
      for (var t2 in tableaus) {
        if (t1 == t2) continue;
        if ((t2.cards.isEmpty && c.rank == 13) ||
            (t2.cards.isNotEmpty && t2.cards.last.isFaceUp && t2.cards.last.isRed != c.isRed && t2.cards.last.rank - 1 == c.rank)) {
          hintedCard = c;
          hintTimer = 2.0;
          return;
        }
      }
    }

    if (stock.cards.isNotEmpty) {
      hintedCard = stock.cards.last; hintTimer = 2.0; return;
    } else if (waste.cards.isNotEmpty) {

      hintTimer = 2.0; hintedCard = CardData(0, Suit.spades);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hintTimer > 0) {
       hintTimer -= dt;
       if (hintTimer <= 0) hintedCard = null;
    }
  }

  void resumeGame() {
    isGameOver = false;
    overlays.remove('GameOver');
    overlays.remove('DeadEnd');
    resumeEngine();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    _computeLayout();
    _initGame();
    resumeEngine();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);


    final feltPaint = Paint()..color = const Color(0xFF0A5C1C);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), feltPaint);

    final stitchPaint = Paint()
      ..color = const Color(0xFF0D7A24).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, size.x - 8, size.y - 8), const Radius.circular(12)),
      stitchPaint,
    );

    // Draw Difficulty Label
    final diffTp = TextPainter(
      text: TextSpan(
        text: 'LEVEL: ${difficulty.label}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    diffTp.paint(canvas, Offset(size.x - diffTp.width - 20, size.y - diffTp.height - 20));


    _drawPileBase(canvas, stock.x, stock.y, isStock: true, hasCards: stock.cards.isNotEmpty);
    _drawPileBase(canvas, waste.x, waste.y);
    

    final suitSymbols = ['♥', '♦', '♣', '♠'];
    final suitColors = [Colors.red, Colors.red, Colors.black54, Colors.black54];
    for (int i = 0; i < foundations.length; i++) {
      _drawPileBase(canvas, foundations[i].x, foundations[i].y, isFoundation: true);
      if (foundations[i].cards.isEmpty) {
        final tp = TextPainter(
          text: TextSpan(text: suitSymbols[i], style: TextStyle(color: suitColors[i].withValues(alpha: 0.25), fontSize: cardW * 0.5)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(foundations[i].x + cardW / 2 - tp.width / 2, foundations[i].y + cardH / 2 - tp.height / 2));
      }
    }
    for (var t in tableaus) {
      _drawPileBase(canvas, t.x, t.y);
    }


    if (stock.cards.isNotEmpty) {
      int stackSize = (stock.cards.length / 8).ceil().clamp(1, 4);
      for (int i = 0; i < stackSize; i++) {
        _drawCard(canvas, stock.cards.last, stock.x + i * 1.5, stock.y - i * 1.5, faceDown: true);
      }

      final count = stock.cards.length;
      final badgeX = stock.x + cardW - 6;
      final badgeY = stock.y + 6;
      canvas.drawCircle(Offset(badgeX, badgeY), 12, Paint()..color = Colors.redAccent);
      final tp = TextPainter(
        text: TextSpan(text: '$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(badgeX - tp.width / 2, badgeY - tp.height / 2));
    } else {

      final tp = TextPainter(
        text: TextSpan(text: '↺', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: cardW * 0.55)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(stock.x + cardW / 2 - tp.width / 2, stock.y + cardH / 2 - tp.height / 2));
    }
    

    if (waste.cards.isNotEmpty) {
      double wx = waste.x;
      final fanCount = min(3, waste.cards.length);
      final startI = waste.cards.length - fanCount;
      for (int i = startI; i < waste.cards.length; i++) {
        _drawCard(canvas, waste.cards[i], wx, waste.y);
        wx += min(20, colSpacing * 0.25);
      }
    }
    

    for (var f in foundations) {
      if (f.cards.isNotEmpty) _drawCard(canvas, f.cards.last, f.x, f.y);
    }
    

    final faceDownStep = max(6.0, cardH * 0.08);
    final faceUpStep = max(18.0, cardH * 0.22);
    for (var t in tableaus) {
      double ty = t.y;
      for (var c in t.cards) {
        if (!draggedStack.contains(c)) {
          _drawCard(canvas, c, t.x, ty);
        }
        ty += c.isFaceUp ? faceUpStep : faceDownStep;
      }
    }
    

    if (draggedStack.isNotEmpty) {
      double dy = 0;
      for (int i = 0; i < draggedStack.length; i++) {
        _drawCard(canvas, draggedStack[i], currentDragPos.x, currentDragPos.y + dy);
        dy += faceUpStep;
      }
    }
  }
  
  void _drawPileBase(Canvas canvas, double x, double y, {bool isStock = false, bool hasCards = false, bool isFoundation = false}) {
    final r = Rect.fromLTWH(x, y, cardW, cardH);

    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(8)),
      Paint()..color = const Color(0xFF073D12),
    );
    final borderColor = isFoundation ? Colors.amber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(8)),
      Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
  }

  void _drawCard(Canvas canvas, CardData c, double x, double y, {bool faceDown = false}) {
    final r = Rect.fromLTWH(x, y, cardW, cardH);

    canvas.drawRRect(
      RRect.fromRectAndRadius(r.translate(1.5, 2), const Radius.circular(8)),
      Paint()..color = Colors.black26,
    );
    if (!c.isFaceUp || faceDown) {

      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = const Color(0xFF1565C0));
      canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(6)), 
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

      final center = r.center;
      final dp = Paint()..color = Colors.white.withValues(alpha: 0.08);
      for (int i = -2; i <= 2; i++) {
        for (int j = -3; j <= 3; j++) {
          canvas.drawCircle(Offset(center.dx + i * 12, center.dy + j * 10), 2, dp);
        }
      }

      final logoSize = cardW * 0.45;
      logoSprite.render(canvas, position: Vector2(x + cardW / 2 - logoSize / 2, y + cardH / 2 - logoSize / 2), size: Vector2(logoSize, logoSize));
    } else {

      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = Colors.white);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), 
        Paint()..color = Colors.black12..style = PaintingStyle.stroke..strokeWidth = 0.8);
      
      final col = c.isRed ? const Color(0xFFCC0000) : Colors.black87;
      final fontSize = (cardW * 0.22).clamp(10.0, 18.0);
      final centerFontSize = (cardW * 0.5).clamp(20.0, 40.0);
      

      final tp = TextPainter(
         text: TextSpan(text: '${c.rankStr}\n${c.suitStr}', style: TextStyle(color: col, fontSize: fontSize, fontWeight: FontWeight.bold, height: 1.0)),
         textDirection: TextDirection.ltr, textAlign: TextAlign.center
      )..layout();
      tp.paint(canvas, Offset(x + 4, y + 4));
      

      final centerTp = TextPainter(
         text: TextSpan(text: c.suitStr, style: TextStyle(color: col, fontSize: centerFontSize)),
         textDirection: TextDirection.ltr
      )..layout();
      centerTp.paint(canvas, Offset(x + cardW / 2 - centerTp.width / 2, y + cardH / 2 - centerTp.height / 2));


      canvas.save();
      canvas.translate(x + cardW - 4, y + cardH - 4);
      canvas.rotate(pi);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
    

    if (hintedCard != null && hintedCard!.rank == c.rank && hintedCard!.suit == c.suit && hintTimer > 0) {
       final glow = Paint()..color = Colors.yellowAccent.withValues(alpha: 0.5 + 0.3 * sin(hintTimer * 15))..style = PaintingStyle.stroke..strokeWidth = 4;
       canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(8)), glow);
    }

    if (hintedCard != null && hintedCard!.rank == 0 && hintTimer > 0) {
       if (stock.cards.isEmpty) {
          final r = Rect.fromLTWH(stock.x, stock.y, cardW, cardH);
          final glow = Paint()..color = Colors.yellowAccent.withValues(alpha: 0.5 + 0.3 * sin(hintTimer * 15))..style = PaintingStyle.stroke..strokeWidth = 4;
          canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(8)), glow);
       }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) {
      _initGame();
      return;
    }
    hintedCard = null; hintTimer = 0;
    
    final p = event.localPosition;
    if (Rect.fromLTWH(stock.x, stock.y, cardW, cardH).contains(p.toOffset())) {
      _saveState();
      if (stock.cards.isNotEmpty) {
        var c = stock.cards.removeLast();
        c.isFaceUp = true;
        waste.cards.add(c);
      } else {
        while (waste.cards.isNotEmpty) {
          var c = waste.cards.removeLast();
          c.isFaceUp = false;
          stock.cards.add(c);
        }
      }
      _checkDeadEnd();
    }


    if (waste.cards.isNotEmpty) {
      final topWaste = waste.cards.last;
      for (var f in foundations) {
        if ((f.cards.isEmpty && topWaste.rank == 1) ||
            (f.cards.isNotEmpty && f.cards.last.suit == topWaste.suit && f.cards.last.rank + 1 == topWaste.rank)) {
          final wasteBounds = Rect.fromLTWH(waste.x, waste.y, cardW + 50, cardH);
          if (wasteBounds.contains(p.toOffset())) {
            _saveState();
            f.cards.add(waste.cards.removeLast());
            _checkWin();
            if (!isGameOver) _checkDeadEnd();
            return;
          }
        }
      }
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    hintedCard = null; hintTimer = 0;
    if (isGameOver) return;
    final p = event.localPosition;
    
    if (waste.cards.isNotEmpty) {
       double wx = waste.x + max(0, min(2, waste.cards.length - 1)) * min(20, colSpacing * 0.25);
       if (Rect.fromLTWH(wx, waste.y, cardW, cardH).contains(p.toOffset())) {
         draggedStack = [waste.cards.last];
         sourcePile = waste;
         currentDragPos = Vector2(wx, waste.y);
         dragOffset = currentDragPos - p;
         return;
       }
    }
    
    final faceDownStep = max(6.0, cardH * 0.08);
    final faceUpStep = max(18.0, cardH * 0.22);
    for (var t in tableaus) {
      if (t.cards.isEmpty) continue;
      double ty = t.y;
      for (int i = 0; i < t.cards.length; i++) {
        var c = t.cards[i];
        double cy = ty;
        ty += c.isFaceUp ? faceUpStep : faceDownStep;
        
        if (c.isFaceUp) {
           double h = (i == t.cards.length - 1) ? cardH : faceUpStep;
           if (Rect.fromLTWH(t.x, cy, cardW, h).contains(p.toOffset())) {
               draggedStack = t.cards.sublist(i).toList();
               sourcePile = t;
               currentDragPos = Vector2(t.x, cy);
               dragOffset = currentDragPos - p;
               return;
           }
        }
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (draggedStack.isNotEmpty) {
      currentDragPos += event.localDelta;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (draggedStack.isEmpty) return;
    

    if (draggedStack.length == 1) {
       for (var f in foundations) {
         if (Rect.fromLTWH(f.x - 10, f.y - 10, cardW + 20, cardH + 20).contains((currentDragPos + Vector2(cardW / 2, cardH / 2)).toOffset())) {
            var c = draggedStack.first;
            if ((f.cards.isEmpty && c.rank == 1) || 
                (f.cards.isNotEmpty && f.cards.last.suit == c.suit && f.cards.last.rank + 1 == c.rank)) {
                _saveState();
                sourcePile!.cards.removeLast();
                f.cards.add(c);
                _endDrag();
                return;
            }
         }
       }
    }
    

    final faceUpStep = max(18.0, cardH * 0.22);
    for (var t in tableaus) {
       double ty = t.cards.isEmpty ? t.y : t.y + (t.cards.length - 1) * faceUpStep;
       if (Rect.fromLTWH(t.x - 10, ty - 20, cardW + 20, cardH + 40).contains((currentDragPos + Vector2(cardW / 2, 20)).toOffset())) {
           var c = draggedStack.first;
           if ((t.cards.isEmpty && c.rank == 13) ||
               (t.cards.isNotEmpty && t.cards.last.isFaceUp && t.cards.last.isRed != c.isRed && t.cards.last.rank - 1 == c.rank)) {
               _saveState();
               sourcePile!.cards.removeRange(sourcePile!.cards.length - draggedStack.length, sourcePile!.cards.length);
               t.cards.addAll(draggedStack);
               _endDrag();
               return;
           }
       }
    }
    
    _cancelDrag();
  }

  void _endDrag() {
    if (sourcePile != null && sourcePile!.cards.isNotEmpty && sourcePile != waste) {
       sourcePile!.cards.last.isFaceUp = true;
    }
    draggedStack.clear();
    sourcePile = null;
    _checkWin();
    if (!isGameOver) _checkDeadEnd();
  }
  
  void _cancelDrag() {
    draggedStack.clear();
    sourcePile = null;
  }
  
  void _checkWin() {
     if (foundations.every((f) => f.cards.length == 13)) {
         isGameOver = true;
         overlays.add('GameOver');
     }
  }
}
