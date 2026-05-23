
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

class DriveMeGame extends FlameGame with PanDetector, TapCallbacks {
  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  
  double carX = 0;
  double carAngle = 0;
  double speed = 400;
  final List<RoadObject> obstacles = [];
  double spawnTimer = 0;
  double traveledDist = 0;
  
  late TextComponent hud;
  late ScreenShake shaker;
  late Sprite logoSprite;

  DriveMeGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
      if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    shaker = ScreenShake();
    add(shaker);
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    
    score = 0;
    gameOver = false;
    carX = size.x / 2;
    carAngle = 0;
    speed = 400 * difficulty.speedMultiplier;
    obstacles.clear();
    spawnTimer = 0;
    traveledDist = 0;

    hud = TextComponent(
      text: "SPEED: ${speed.toInt()} MPH",
      position: Vector2(20, 60),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)),
    );
    add(hud);


    add(TextComponent(
      text: 'DRIVE ME',
      position: Vector2(size.x / 2, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.1), fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 10)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 45, 45),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.cyanAccent.withValues(alpha: 0.25),
    ));

    add(_DriveRenderer());
    add(CinematicOverlay());
    resumeEngine();
  }

  void resumeGame() {
    gameOver = false;
    obstacles.clear();
    spawnTimer = 0;
    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    
    traveledDist += speed * dt;
    score = (traveledDist / 10).floor();
    

    speed += 5 * dt;
    hud.text = "SCORE: $score  •  ${speed.toInt()} KM/H";


    spawnTimer -= dt;
    if (spawnTimer <= 0) {
      spawnTimer = (1.5 / (speed / 400)).clamp(0.4, 2.0);
      obstacles.add(RoadObject(
        pos: Vector2(Random().nextDouble() * (size.x - 100) + 50, -100),
        type: Random().nextBool() ? ObjectType.obstacle : ObjectType.coin,
      ));
    }


    for (int i = obstacles.length - 1; i >= 0; i--) {
      final o = obstacles[i];
      o.pos.y += speed * dt;
      if (o.pos.y > size.y + 100) obstacles.removeAt(i);
      

      if (o.pos.distanceTo(Vector2(carX, size.y - 120)) < 40) {
        if (o.type == ObjectType.obstacle) {
          _lose();
        } else {
          score += 100;
          traveledDist += 500;
          obstacles.removeAt(i);
          shaker.shake(duration: 0.1, intensity: 5);
        }
      }
    }
    

    carAngle *= 0.9;
  }

  void _lose() {
    gameOver = true;
    shaker.shake(duration: 0.5, intensity: 15);
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameOver) return;
    double delta = info.delta.global.x;
    carX = (carX + delta).clamp(40.0, size.x - 40.0);
    carAngle = (delta * 0.05).clamp(-0.4, 0.4);
  }
}

enum ObjectType { obstacle, coin }
class RoadObject {
  Vector2 pos;
  ObjectType type;
  RoadObject({required this.pos, required this.type});
}

class _DriveRenderer extends Component with HasGameReference<DriveMeGame> {
  @override
  void render(Canvas canvas) {
    final g = game;
    final w = g.size.x;
    final h = g.size.y;
    

    final roadPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawRect(Rect.fromLTWH(20, 0, w - 40, h), roadPaint);
    
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 4;
    double lineSpacing = 100;
    double offset = (g.traveledDist % lineSpacing);
    for (double y = -lineSpacing + offset; y < h; y += lineSpacing) {
      canvas.drawLine(Offset(w / 2, y), Offset(w / 2, y + 50), linePaint);
    }
    

    for (final o in g.obstacles) {
      if (o.type == ObjectType.obstacle) {
        final rect = Rect.fromCenter(center: o.pos.toOffset(), width: 60, height: 40);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), Paint()..color = Colors.redAccent);
        canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(4)), Paint()..color = Colors.black26);
      } else {
        canvas.drawCircle(o.pos.toOffset(), 15, Paint()..color = Colors.yellowAccent..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5));
        canvas.drawCircle(o.pos.toOffset(), 10, Paint()..color = Colors.white);
      }
    }
    

    canvas.save();
    canvas.translate(g.carX, h - 120);
    canvas.rotate(g.carAngle);
    
    final carRect = Rect.fromCenter(center: Offset.zero, width: 50, height: 80);
    final carPaint = Paint()..color = Colors.cyanAccent;
    canvas.drawRRect(RRect.fromRectAndRadius(carRect, const Radius.circular(12)), carPaint);
    

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -10), width: 35, height: 30), const Radius.circular(8)), Paint()..color = Colors.black54);
    

    final glow = Paint()..color = Colors.cyanAccent.withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 45), width: 30, height: 20), glow);
    
    canvas.restore();
  }
}
