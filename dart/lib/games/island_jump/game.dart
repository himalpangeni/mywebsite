import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import 'dart:math';

class IslandJumpGame extends FlameGame with PanDetector {
  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;

  double pX = 50, pY = 0;
  double pVx = 0, pVy = 0;
  bool isJumping = false;
  double charge = 0;

  final List<Rect> islands = [];
  double offsetCamera = 0;

  IslandJumpGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF102218);

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
    overlays.remove('GameOver');

    gameOver = false;
    score = 0;
    pX = 60;
    pY = size.y - 140;
    pVx = 0;
    pVy = 0;
    isJumping = false;
    charge = 0;
    offsetCamera = 0;

    islands.clear();
    islands.add(Rect.fromLTWH(20, size.y - 120, 80, 120));
    _addIsland(180);
    _addIsland(350);

    hud = TextComponent(text: 'SCORE: 0', position: Vector2(25, 45), 
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)));
    add(hud);
    add(_IslandRenderer());
    resumeEngine();
  }

  void _addIsland(double x) {
    double w = Random().nextDouble() * 50 + 40; 
    islands.add(Rect.fromLTWH(x, size.y - 120, w, 120));
  }

  void resumeGame() {
    gameOver = false;
    isJumping = false;
    pY = size.y - 140;
    pVx = 0; pVy = 0;
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _lose() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void _launch() {
    if (!isJumping && !gameOver && charge > 0) {
        isJumping = true;
        pVx = charge * 0.85;
        pVy = -charge * 0.95 - 250;
        charge = 0;
    }
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    
    if (charge > 0 && !isJumping) {
        charge += 800 * dt;
        if (charge > 1100) charge = 1100;
    }
    
    if (isJumping) {
        pVy += 1900 * dt; 
        pX += pVx * dt;
        pY += pVy * dt;

        if (pY > size.y + 100) {
            _lose();
            return;
        }

        if (pVy > 0) { 
           for (final isl in islands) {
               if (pX + 20 > isl.left && pX - 20 < isl.right && pY + 20 >= isl.top && pY - 20 <= isl.top + 30) {
                   pY = isl.top - 20;
                   isJumping = false;
                   pVx = 0;
                   pVy = 0;
                   score++;
                   hud.text = 'SCORE: $score';
                   
                   if (islands.last.left - pX < size.x) {
                       _addIsland(islands.last.right + _random.nextDouble() * 140 + 70);
                   }
                   break;
               }
           }
        }
    }

    final targetOffset = pX - size.x / 4;
    if (targetOffset > offsetCamera && !isJumping) {
        offsetCamera += (targetOffset - offsetCamera) * 10 * dt;
    }
  }

  @override
  void onPanDown(DragDownInfo info) {
    if (gameOver || isJumping) return;
    charge = 250; 
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _launch();
  }

  @override
  void onPanCancel() {
    _launch();
  }
}

class _IslandRenderer extends Component with HasGameReference<IslandJumpGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    
    canvas.save();
    canvas.translate(-g.offsetCamera, 0);


    canvas.drawRect(Rect.fromLTWH(g.offsetCamera, g.size.y - 40, g.size.x, 40), _p..shader = const LinearGradient(colors: [Color(0x880277BD), Color(0x8801579B)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, g.size.y - 40, 10, 40)));

    for (final isl in g.islands) {
        final rrect = RRect.fromRectAndCorners(isl, topLeft: const Radius.circular(8), topRight: const Radius.circular(8));
        

        canvas.drawRRect(rrect.shift(const Offset(4, 15)), _p..color = Colors.black26);
        

        canvas.drawRRect(rrect, _p..color = const Color(0xFF795548));

        final grassRect = RRect.fromRectAndCorners(Rect.fromLTWH(isl.left, isl.top, isl.width, 20), topLeft: const Radius.circular(8), topRight: const Radius.circular(8));
        canvas.drawRRect(grassRect, _p..shader = const LinearGradient(colors: [Color(0xFF81C784), Color(0xFF4CAF50)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(grassRect.outerRect));
    }
    

    canvas.drawOval(Rect.fromCenter(center: Offset(g.pX, g.isJumping ? g.size.y - 100 : g.pY + 15), width: 24, height: 8), _p..color = Colors.black38);
    

    canvas.drawCircle(Offset(g.pX, g.pY), 15, _p..shader = const RadialGradient(colors: [Color(0xFFFF8A65), Color(0xFFC62828)], center: Alignment(-0.3, -0.3)).createShader(Rect.fromCircle(center: Offset(g.pX, g.pY), radius: 15)));


    if (g.charge > 0) {
        final chargeRatio = (g.charge - 200) / 800;
        final sweepAngle = 2 * pi * chargeRatio;
        final rect = Rect.fromCircle(center: Offset(g.pX, g.pY), radius: 28);
        canvas.drawArc(rect, -pi/2, sweepAngle, false, _p..color = Colors.orangeAccent..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
    }
    
    canvas.restore();
  }
}
