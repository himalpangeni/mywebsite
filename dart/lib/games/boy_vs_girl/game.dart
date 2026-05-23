
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';
import 'bg_renderer.dart';

enum GameMode { pvp, pve }
enum FighterState { idle, hitting, hurt, kO }

class BoyVsGirlGame extends FlameGame with TapCallbacks, HasGameReference {
  final GameDifficulty difficulty;
  final GameMode mode;
  
  late Fighter boy;
  late Fighter girl;
  
  double gameTimer = 99.0;
  bool isPlaying = false;
  bool isStarting = true;
  int currentTurn = 0;
  int selectedPower = 1;
  static int _roundCount = 0;
  late PowerMeter _powerMeter;
  bool gameOver = false;
  String winner = '';
  double flashTimer = 0;
  final List<_EffectParticle> _particles = [];
  
  late ScreenShake shaker;
  
  BoyVsGirlGame({required this.difficulty, this.mode = GameMode.pve});

  @override
  Color backgroundColor() => const Color(0xFFFFF9E1);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    shaker = ScreenShake();
    add(shaker);
    restart();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c != shaker && c is! CameraComponent) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    
    gameTimer = 60.0;
    isPlaying = true;
    isStarting = false;
    gameOver = false;
    winner = '';
    currentTurn = _roundCount % 2;
    _roundCount++;
    _particles.clear();
    selectedPower = 1;

    add(DarkBgRenderer());


    final centerX = size.x / 2;
    final groundY = size.y * 0.7;

    add(boy = Fighter(
      isBoy: true,
      position: Vector2(centerX - 80, groundY),
      anchor: Anchor.bottomCenter,
    ));

    add(girl = Fighter(
      isBoy: false,
      position: Vector2(centerX + 80, groundY),
      anchor: Anchor.bottomCenter,
    ));

    add(CinematicOverlay());
    add(_BattleHUD());
    
    _powerMeter = PowerMeter();
    add(_powerMeter);
    _powerMeter.isVisible = true;
    _powerMeter.start();
    
    resumeEngine();
    SensoryService.success();
  }

  void resumeGame() {
    gameTimer = 60.0;
    boy.health = 50;
    girl.health = 50;
    gameOver = false;
    isPlaying = true;
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    for (int i = _particles.length - 1; i >= 0; i--) {
        _particles[i].update(dt);
        if (_particles[i].life <= 0) _particles.removeAt(i);
    }
    if (flashTimer > 0) flashTimer -= dt;

    if (!isPlaying || gameOver || isStarting) return;


    if (mode == GameMode.pve && currentTurn == 1 && !girl.isKO) {
        if (!_powerMeter.isStopped) {
           final aiReaction = 0.5 + Random().nextDouble() * 1.5;
           if (_powerMeter.timeActive > aiReaction) {
               _handleTap();
           }
        }
    }

    if ((boy.health <= 0) && isPlaying) {
        _endGame('GIRL WINS!');
    } else if ((girl.health <= 0) && isPlaying) {
        _endGame('BOY WINS!');
    }
  }



  void _endGame(String msg) {
    if (gameOver) return;
    gameOver = true;
    winner = msg;
    isPlaying = false;
    _powerMeter.isVisible = false;
    
    if (msg.contains('BOY')) {
      girl.knockout();
    } else {
      boy.knockout();
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
        if (!gameOver) return;
        pauseEngine();
        overlays.add('GameOver');
    });
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isStarting || gameOver || !isPlaying) return;
    

    if (mode == GameMode.pve && currentTurn == 1) return;
    
    _handleTap();
  }

  void _handleTap() {
      if (_powerMeter.isStopped) return;
      _powerMeter.stop();
      
      final power = _powerMeter.powerValue;
      final baseDmg = selectedPower == 0 ? 7.0 : 5.0;
      if (currentTurn == 0) {

          boy.tap();
          _applyImpact(girl, true);
          girl.applyDamage(power * baseDmg);
          girl.position.x += power * 2;
          SensoryService.lightImpact();
          shaker.shake(intensity: power * 2, duration: 0.1);
      } else {

          girl.tap();
          _applyImpact(boy, false);
          boy.applyDamage(power * baseDmg);
          boy.position.x -= power * 2;
          SensoryService.lightImpact();
          shaker.shake(intensity: power * 2, duration: 0.1);
      }
      

      Future.delayed(const Duration(milliseconds: 1200), () {
          if (gameOver) return;
          currentTurn = currentTurn == 0 ? 1 : 0;
          _powerMeter.start();
      });
  }

  void _applyImpact(Fighter target, bool fromLeft) {
      flashTimer = 0.1;
      final impactPos = target.position + Vector2(fromLeft ? -20 : 20, -100);
      for(int i=0; i<8; i++) {
          _particles.add(_EffectParticle(
              pos: impactPos,
              vel: Vector2((Random().nextDouble()-0.5)*300, (Random().nextDouble()-0.8)*400),
              color: fromLeft ? Colors.blueAccent : Colors.pinkAccent,
          ));
      }
  }
}

class PowerMeter extends PositionComponent with HasGameReference<BoyVsGirlGame> {
    double pointerOffset = 0;
    int pointerDir = 1;
    bool isVisible = false;
    bool isStopped = true;
    double powerValue = 0;
    double timeActive = 0;
    
    @override
    void update(double dt) {
        if (!isVisible || isStopped) return;
        timeActive += dt;
        final baseSpeed = 3.0 * game.difficulty.speedMultiplier;
        final speed = game.selectedPower == 2 ? baseSpeed * 0.7 : baseSpeed;
        pointerOffset += speed * pointerDir * dt;
        if (pointerOffset > 1.0) {
            pointerOffset = 1.0;
            pointerDir = -1;
        } else if (pointerOffset < -1.0) {
            pointerOffset = -1.0;
            pointerDir = 1;
        }
    }
    
    void start() {
        isStopped = false;
        pointerOffset = 0;
        pointerDir = 1;
        powerValue = 0;
        timeActive = 0;
    }
    
    void stop() {
        isStopped = true;


        powerValue = 1.0 + (1.0 - pointerOffset.abs()) * 4.0;
    }
    
    @override
    void render(Canvas canvas) {
        if (!isVisible) return;
        
        final center = Vector2(game.size.x / 2, 180);
        const width = 240.0;
        const height = 24.0;
        final rect = Rect.fromCenter(center: center.toOffset(), width: width, height: height);
        
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), Paint()..color = Colors.black54);
        

        final spotW = game.selectedPower == 1 ? width * 0.35 : width * 0.2;
        final sweetSpot = Rect.fromCenter(center: center.toOffset(), width: spotW, height: height);
        canvas.drawRRect(RRect.fromRectAndRadius(sweetSpot, const Radius.circular(12)), Paint()..color = Colors.greenAccent);
        

        final pX = center.x + (pointerOffset * width / 2);
        canvas.drawRect(Rect.fromCenter(center: Offset(pX, center.y), width: 6, height: height + 10), Paint()..color = Colors.white);
        
        if (isStopped) {
            final tp = TextPainter(
                text: TextSpan(text: '${powerValue.toStringAsFixed(1)}x POWER!', style: const TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4)])),
                textDirection: TextDirection.ltr
            )..layout();
            tp.paint(canvas, Offset(center.x - tp.width/2, center.y - 40));
        } else {
            final tp = TextPainter(
                text: TextSpan(text: game.currentTurn == 0 ? 'BOY: TAP TO HIT!' : 'GIRL: TAP TO HIT!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                textDirection: TextDirection.ltr
            )..layout();
            tp.paint(canvas, Offset(center.x - tp.width/2, center.y - 40));
        }
    }
}

class _EffectParticle {
    Vector2 pos;
    Vector2 vel;
    double life = 1.0;
    Color color;
    _EffectParticle({required this.pos, required this.vel, required this.color});
    void update(double dt) {
        pos += vel * dt;
        vel.y += 800 * dt;
        life -= dt * 2;
    }
}

class Fighter extends PositionComponent with HasGameReference<BoyVsGirlGame> {
  final bool isBoy;
  double health = 100;
  FighterState state = FighterState.idle;
  double stateTimer = 0;
  double bounceTimer = 0;
  
  Fighter({required this.isBoy, required super.position, required super.anchor});

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2(120, 180);
  }

  void tap() {
    if (isKO) return;
    state = FighterState.hitting;
    stateTimer = 0.15;
    bounceTimer = 0.5;
  }

  void applyDamage(double dmg) {
    if (isKO) return;
    health -= dmg;
    state = FighterState.hurt;
    stateTimer = 0.2;
  }

  void knockout() {
    state = FighterState.kO;
    stateTimer = 999;
  }

  bool get isKO => state == FighterState.kO;

  @override
  void update(double dt) {
    super.update(dt);
    if (stateTimer > 0) {
        stateTimer -= dt;
        if (stateTimer <= 0 && !isKO) {
            state = FighterState.idle;
        }
    }
    bounceTimer += dt * 10;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..strokeWidth = 3..style = PaintingStyle.fill;
    

    final breathe = isKO ? 0.0 : sin(bounceTimer) * 0.05;
    canvas.save();
    canvas.translate(size.x/2, size.y);
    canvas.scale(1.0 + breathe, 1.0 - breathe);
    canvas.translate(-size.x/2, -size.y);


    paint.color = isBoy ? Colors.blue.shade300 : Colors.pink.shade300;
    const bodyRect = Rect.fromLTWH(30, 80, 60, 100);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(20)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(20)), Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 4);
    

    const headCenter = Offset(60, 50);
    paint.color = const Color(0xFFFFCC99);
    canvas.drawCircle(headCenter, 45, paint);
    canvas.drawCircle(headCenter, 45, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 4);
    

    final eyePaint = Paint()..color = Colors.black..strokeCap = StrokeCap.round;
    if (state == FighterState.hurt) {

        canvas.drawLine(headCenter + const Offset(-25, -5), headCenter + const Offset(-10, 5), eyePaint..strokeWidth = 6);
        canvas.drawLine(headCenter + const Offset(25, -5), headCenter + const Offset(10, 5), eyePaint);

        canvas.drawLine(headCenter + const Offset(-30, -20), headCenter + const Offset(-5, -10), eyePaint..strokeWidth = 4);
        canvas.drawLine(headCenter + const Offset(30, -20), headCenter + const Offset(5, -10), eyePaint);

        canvas.drawCircle(headCenter + const Offset(25, 20), 12, Paint()..color = Colors.purple.withValues(alpha: 0.5));

        canvas.drawCircle(headCenter + const Offset(-25, 20), 10, Paint()..color = Colors.redAccent.withValues(alpha: 0.4));
    } else if (isKO) {

        canvas.drawLine(headCenter + const Offset(-15, -15), headCenter + const Offset(-5, -5), eyePaint..strokeWidth = 5);
        canvas.drawLine(headCenter + const Offset(-5, -15), headCenter + const Offset(-15, -5), eyePaint);
        canvas.drawLine(headCenter + const Offset(15, -15), headCenter + const Offset(5, -5), eyePaint);
        canvas.drawLine(headCenter + const Offset(5, -15), headCenter + const Offset(15, -5), eyePaint);

        paint.color = Colors.white;
        canvas.drawRect(Rect.fromCenter(center: headCenter + const Offset(0, -30), width: 30, height: 10), paint);
        canvas.drawRect(Rect.fromCenter(center: headCenter + const Offset(0, -30), width: 30, height: 10), Paint()..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {

        canvas.drawCircle(headCenter + const Offset(-18, -2), 6, eyePaint);
        canvas.drawCircle(headCenter + const Offset(18, -2), 6, eyePaint);

        canvas.drawLine(headCenter + const Offset(-25, -15), headCenter + const Offset(-5, -5), eyePaint..strokeWidth = 4);
        canvas.drawLine(headCenter + const Offset(25, -15), headCenter + const Offset(5, -5), eyePaint);

        canvas.drawArc(Rect.fromCenter(center: headCenter + const Offset(0, 25), width: 25, height: 10), 0, -pi, false, paint..style = PaintingStyle.stroke..color = Colors.black87..strokeWidth = 3);
    }


    if (isBoy) {
        final hairPath = Path()
          ..moveTo(headCenter.dx - 45, headCenter.dy - 10)
          ..quadraticBezierTo(headCenter.dx, headCenter.dy - 70, headCenter.dx + 45, headCenter.dy - 10)
          ..close();
        canvas.drawPath(hairPath, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 4);
    } else {

        final hairPaint = Paint()..color = Colors.deepOrangeAccent;
        final outlinePaint = Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 4;
        
        canvas.drawCircle(headCenter + const Offset(-35, -35), 25, hairPaint);
        canvas.drawCircle(headCenter + const Offset(-35, -35), 25, outlinePaint);
        canvas.drawCircle(headCenter + const Offset(35, -35), 25, hairPaint);
        canvas.drawCircle(headCenter + const Offset(35, -35), 25, outlinePaint);
        canvas.drawCircle(headCenter + const Offset(0, -45), 45, hairPaint);
        canvas.drawCircle(headCenter + const Offset(0, -45), 45, outlinePaint);
    }


    final armPaint = Paint()..color = const Color(0xFFFFCC99);
    final armOutline = Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 4;
    if (state == FighterState.hitting) {
        const armRect = Rect.fromLTWH(60, 85, 80, 20);
        canvas.drawRRect(RRect.fromRectAndRadius(armRect, const Radius.circular(10)), armPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(armRect, const Radius.circular(10)), armOutline);
    } else {
        const lArm = Rect.fromLTWH(10, 100, 25, 60);
        const rArm = Rect.fromLTWH(85, 100, 25, 60);
        canvas.drawRRect(RRect.fromRectAndRadius(lArm, const Radius.circular(10)), armPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(lArm, const Radius.circular(10)), armOutline);
        canvas.drawRRect(RRect.fromRectAndRadius(rArm, const Radius.circular(10)), armPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(rArm, const Radius.circular(10)), armOutline);
    }

    canvas.restore();
  }
}

class _BattleHUD extends Component with HasGameReference<BoyVsGirlGame> {
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;


    for (var p in g._particles) {
        final paint = Paint()..color = p.color.withValues(alpha: p.life)..style = PaintingStyle.fill;
        canvas.drawCircle(p.pos.toOffset(), 5 * p.life, paint);

        canvas.drawRect(Rect.fromCenter(center: p.pos.toOffset(), width: 15 * p.life, height: 2 * p.life), paint);
        canvas.drawRect(Rect.fromCenter(center: p.pos.toOffset(), width: 2 * p.life, height: 15 * p.life), paint);
    }


    if (g.flashTimer > 0) {
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white.withValues(alpha: g.flashTimer * 5));
    }


    _drawHealthBar(canvas, const Offset(20, 50), w * 0.4, g.boy.health, Colors.blueAccent, 'BOY');
    _drawHealthBar(canvas, Offset(w - 20 - w * 0.4, 50), w * 0.4, g.girl.health, Colors.pinkAccent, 'GIRL', rightAlign: true);


    final modeText = g.mode == GameMode.pvp ? 'LOCAL 2P' : 'VS AI';
    final modeTp = TextPainter(
        text: TextSpan(text: modeText, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)..layout();
    modeTp.paint(canvas, Offset(w / 2 - modeTp.width / 2, 15));


    final timerTp = TextPainter(
        text: TextSpan(text: g.gameTimer.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF3E2723), fontSize: 32, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)..layout();
    timerTp.paint(canvas, Offset(w/2 - timerTp.width/2, 45));

    if (g.gameOver) {
        final winTp = TextPainter(
            text: TextSpan(text: g.winner, style: const TextStyle(color: Colors.redAccent, fontSize: 48, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 10, color: Colors.black26)])),
            textDirection: TextDirection.ltr)..layout();
        winTp.paint(canvas, Offset(w/2 - winTp.width/2, h/2 - 100));
    }
  }

  void _drawHealthBar(Canvas canvas, Offset pos, double width, double health, Color color, String name, {bool rightAlign = false}) {
    final bgPaint = Paint()..color = Colors.black12;
    final hpPaint = Paint()..color = color;
    
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx, pos.dy, width, 16), const Radius.circular(8)), bgPaint);
    final hpWidth = (width * (health / 100)).clamp(0.0, width);
    if (rightAlign) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx + (width - hpWidth), pos.dy, hpWidth, 16), const Radius.circular(8)), hpPaint);
    } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx, pos.dy, hpWidth, 16), const Radius.circular(8)), hpPaint);
    }

    final tp = TextPainter(
        text: TextSpan(text: name, style: const TextStyle(color: Color(0xFF3E2723), fontSize: 16, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(pos.dx + (rightAlign ? width - tp.width : 0), pos.dy - 22));
  }
}
