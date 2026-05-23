import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

class PerfectCreamGame extends FlameGame with TapCallbacks {


  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  int lives = 3;
  bool isDispensing = false;
  final List<Dessert> desserts = [];
  final List<CreamDrop> drops = [];
  double traveledDist = 0;
  late ScreenShake shaker;
  
  Color currentCreamColor = Colors.white;

  static const List<Color> _pastryColors = [
    Color(0xFF8D6E63), Color(0xFFD7CCC8), Color(0xFFFFCC80), 
    Color(0xFFE6EE9C), Color(0xFFFFAB91)
  ];
  
  static const List<Color> _creamColors = [
    Colors.white, Color(0xFFFFCDD2), Color(0xFFC8E6C9), 
    Color(0xFFBBDEFB), Color(0xFFFFF9C4), Color(0xFFE1BEE7)
  ];

  PerfectCreamGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFFFFF3E0);

  @override
  Future<void> onLoad() async {
    _random = Random();
    await super.onLoad();
    shaker = ScreenShake();
    add(shaker);
    restart();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c != shaker && c is! CameraComponent) {
        c.removeFromParent();
      }
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    score = 0;
    lives = 3;
    traveledDist = 0;
    desserts.clear();
    drops.clear();
    _pickNewCreamColor();
    
    for (int i = 0; i < 5; i++) {
        desserts.add(Dessert(x: i * 300.0 + 400.0, color: _pickRandomColor(_pastryColors)));
    }
    
    add(_KitchenRenderer());
    add(CinematicOverlay());
    resumeEngine();
  }
  
  Color _pickRandomColor(List<Color> palette) => palette[_random.nextInt(palette.length)];
  
  void _pickNewCreamColor() {
      currentCreamColor = _pickRandomColor(_creamColors);
  }

  @override
  void update(double dt) {
    if (lives <= 0) return;
    super.update(dt);

    double speed = 200.0 + min(score * 2.0, 300.0);
    traveledDist += speed * dt;


    for (int i = desserts.length - 1; i >= 0; i--) {
        desserts[i].x -= speed * dt;
        if (desserts[i].x < -100) {

            if (desserts[i].creamLevel < 0.2) {
                _loseLife();
            }
            desserts.removeAt(i);
            desserts.add(Dessert(x: desserts.last.x + 300, color: _pickRandomColor(_pastryColors)));

            if (_random.nextDouble() < 0.4) _pickNewCreamColor();
        }
    }

    if (isDispensing) {
        if (_random.nextDouble() < 0.3) {
            drops.add(CreamDrop(pos: Vector2(size.x / 2, 150), velocity: Vector2(0, 450), color: currentCreamColor));
        }
    }

    for (int i = drops.length - 1; i >= 0; i--) {
        drops[i].pos += drops[i].velocity * dt;
        
        bool hitCake = false;
        for (var d in desserts) {

            if (drops[i].pos.distanceTo(Vector2(d.x, size.y - 200)) < 50) {
                d.creamLevel = (d.creamLevel + 0.05).clamp(0.0, 1.0);
                d.creamColor = drops[i].color;
                score++;
                drops.removeAt(i);
                hitCake = true;
                break;
            }
        }

        if (!hitCake && drops[i].pos.y > size.y - 180) {
            _loseLife();
            drops.removeAt(i);
        }
    }
  }
  
  void _loseLife() {
    lives--;
    shaker.shake(duration: 0.3, intensity: 8);
    if (lives <= 0) {
      overlays.add('GameOver');
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    isDispensing = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    isDispensing = false;
  }
  
  @override
  void onTapCancel(TapCancelEvent event) {
    isDispensing = false;
  }
}



class Dessert {
    double x;
    double creamLevel = 0;
    Color color;
    Color? creamColor;
    Dessert({required this.x, required this.color});
}

class CreamDrop {
    Vector2 pos;
    Vector2 velocity;
    Color color;
    CreamDrop({required this.pos, required this.velocity, required this.color});
}

class _KitchenRenderer extends Component with HasGameReference<PerfectCreamGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    

    canvas.drawRect(Rect.fromLTWH(0, g.size.y - 250, g.size.x, 300), _p..color = const Color(0xFFE0F7FA));
    

    canvas.drawRect(Rect.fromLTWH(0, g.size.y - 180, g.size.x, 40), _p..color = Colors.grey.shade800);
    canvas.drawRect(Rect.fromLTWH(0, g.size.y - 180, g.size.x, 5), _p..color = Colors.grey.shade400);


    for (final d in g.desserts) {

        final cakeRect = Rect.fromCenter(center: Offset(d.x, g.size.y - 195), width: 80, height: 30);
        canvas.drawRRect(RRect.fromRectAndRadius(cakeRect, const Radius.circular(5)), _p..color = d.color);
        

        if (d.creamLevel > 0 && d.creamColor != null) {
            double h = 60 * d.creamLevel;
            double topY = g.size.y - 210 - h/2;
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(d.x, topY), width: 70 * d.creamLevel, height: h), const Radius.circular(20)), _p..color = d.creamColor!);
        }
    }


    final dispX = g.size.x / 2;

    if (g.isDispensing) {
      canvas.drawCircle(Offset(dispX, 90), 45, _p..color = g.currentCreamColor.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(dispX, 60), width: 60, height: 120), const Radius.circular(10)), _p..color = g.isDispensing ? Colors.blueGrey.shade300 : Colors.blueGrey);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(dispX, 120), width: 20, height: 40), const Radius.circular(5)), _p..color = Colors.grey.shade300);

    canvas.drawCircle(Offset(dispX, 60), 16, _p..color = g.currentCreamColor);
    canvas.drawCircle(Offset(dispX, 54), 5, _p..color = Colors.white.withValues(alpha: 0.6));

    TextPainter(
      text: TextSpan(text: g.isDispensing ? 'DISPENSING...' : 'HOLD TO DISPENSE',
        style: TextStyle(color: g.isDispensing ? g.currentCreamColor : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, Offset(dispX - 65, 145));



    for (final drop in g.drops) {
        final glow = _p..color = drop.color.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(drop.pos.toOffset(), 18, glow);
        canvas.drawCircle(drop.pos.toOffset(), 10, _p..color = drop.color);
        canvas.drawCircle(drop.pos.toOffset() - const Offset(3, 3), 3, _p..color = Colors.white.withValues(alpha: 0.7));
    }

    

    _drawText(canvas, 'SCORE: ${g.score}', Offset(g.size.x / 2, 30), 24, Colors.black87, bold: true);
    

    for (int i=0; i<3; i++) {
        IconData icon = i < g.lives ? Icons.favorite : Icons.favorite_border;
        TextPainter(
          text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontFamily: icon.fontFamily, fontSize: 32, color: Colors.red)),
          textDirection: TextDirection.ltr
        )..layout()..paint(canvas, Offset(20 + i * 35.0, 20));
    }
  }
  
  void _drawText(Canvas canvas, String text, Offset pos, double size, Color color, {bool bold = false}) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.w900 : FontWeight.normal)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }
}
