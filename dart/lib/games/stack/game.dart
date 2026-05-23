import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';

class Block {
  double x, y, z, w, h, d;
  Color color;
  Block({
    required this.x,
    required this.y,
    required this.z,
    required this.w,
    required this.h,
    required this.d,
    required this.color,
  });
}

class Debris extends Component with HasGameReference<StackGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  Vector2 pos;
  Vector2 size;
  Vector2 velocity;
  Color color;
  double life = 1.0;

  Debris({required this.pos, required this.size, required this.velocity, required this.color});

  @override
  void update(double dt) {
    pos += velocity * dt;
    velocity.y += 800 * dt;
    life -= dt * 0.8;
    if (life <= 0 || pos.y > game.size.y) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(pos.x, pos.y, size.x, size.y),
      _p..color = color.withValues(alpha: life.clamp(0, 1)),
    );
  }
}

class StackGame extends FlameGame with TapCallbacks {
  late final Random _random;
  final GameDifficulty difficulty;
  int score = 0;
  int combo = 0;
  bool gameOver = false;
  
  final List<Block> stack = [];
  late Block current;
  double speed = 250;
  int direction = 1; 
  bool axisX = true;

  late TextComponent scoreText;
  late TextComponent comboText;
  late ScreenShake shaker;

  StackGame({required this.difficulty}) : super();

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    _random = Random();
    await super.onLoad();
    restart();
  }

  void restart() {
    stack.clear();
    score = 0;
    combo = 0;
    gameOver = false;
    speed = 250 * difficulty.speedMultiplier;
    axisX = true;
    for (final child in children.toList()) {
      if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    shaker = ScreenShake();
    add(shaker);
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');



    stack.add(Block(x: size.x / 2 - 80, y: size.y - 120, z: 0, w: 160, h: 40, d: 160, color: Colors.blueGrey));
    _spawnNext();

    scoreText = TextComponent(
      text: '0',
      position: Vector2(size.x / 2, 100),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 80,
          fontWeight: FontWeight.w900,
          letterSpacing: -2,
          shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 20)],
        ),
      ),
    );
    add(scoreText);

    comboText = TextComponent(
      text: '',
      position: Vector2(size.x / 2, 180),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)),
    );
    add(comboText);
    
    add(CinematicOverlay());
    add(_StackRenderer());
    resumeEngine();
  }

  void _spawnNext() {
    final prev = stack.last;
    final hue = (score * 12) % 360.0;
    final color = HSVColor.fromAHSV(1.0, hue, 0.7, 0.9).toColor();
    
    axisX = !axisX;
    if (axisX) {
      current = Block(x: -prev.w, y: prev.y - 40, z: prev.z, w: prev.w, h: 40, d: prev.d, color: color);
      direction = 1;
    } else {
      current = Block(x: prev.x, y: prev.y - 40, z: -prev.d, w: prev.w, h: 40, d: prev.d, color: color);
      direction = 1;
    }
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);
    
    if (axisX) {
      current.x += speed * direction * dt;
      if (current.x > size.x / 2 + 150) direction = -1;
      if (current.x < size.x / 2 - 150 - current.w) direction = 1;
    } else {
      current.z += speed * direction * dt;
      if (current.z > 200) direction = -1;
      if (current.z < -200) direction = 1;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) return;
    
    final prev = stack.last;
    bool perfect = false;

    if (axisX) {
      double diff = current.x - prev.x;
      if (diff.abs() < 10) {
        current.x = prev.x; perfect = true;
      } else if (diff.abs() > prev.w) {
        _endGame(); return;
      } else {

        double sliceW = diff.abs();
        _spawnDebris(current.x + (diff > 0 ? current.w - sliceW : 0), current.y, sliceW, current.d, current.color);
        current.w -= sliceW;
        if (diff > 0) { } else { current.x = prev.x; }
      }
    } else {
      double diff = current.z - prev.z;
      if (diff.abs() < 10) {
        current.z = prev.z; perfect = true;
      } else if (diff.abs() > prev.d) {
        _endGame(); return;
      } else {

        double sliceD = diff.abs();
        _spawnDebris(current.x, current.y, current.w, sliceD, current.color);
        current.d -= sliceD;
        if (diff > 0) { } else { current.z = prev.z; }
      }
    }

    if (perfect) {
      combo++;
      if (combo >= 3) {

        current.w = (current.w + 10).clamp(0, 160);
        current.d = (current.d + 10).clamp(0, 160);
        comboText.text = 'COMBO x$combo! SIZE UP';
      } else {
        comboText.text = 'PERFECT!';
      }
      shaker.shake(duration: 0.15, intensity: 5);
      add(SparkEmitter(position: Vector2(size.x / 2, current.y), color: Colors.white, count: 15));
    } else {
      combo = 0;
      comboText.text = '';
      shaker.shake(duration: 0.1, intensity: 2);
    }

    stack.add(current);
    score++;
    scoreText.text = '$score';
    

    if (stack.length > 8) {
      for (var b in stack) {
        b.y += 40;
      }
    }
    
    speed = (250 + score * 5) * difficulty.speedMultiplier;
    _spawnNext();
  }

  void _spawnDebris(double x, double y, double w, double d, Color color) {
    add(Debris(
      pos: Vector2(x, y),
      size: Vector2(w, 20),
      velocity: Vector2((_random.nextDouble() - 0.5) * 200, -100),
      color: color,
    ));
  }

  void resumeGame() {
    gameOver = false;
    axisX = true;
    _spawnNext();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _endGame() {
    gameOver = true;
    shaker.shake(duration: 0.6, intensity: 15);
    pauseEngine();
    overlays.add('GameOver');
  }
}

class _StackRenderer extends Component with HasGameReference<StackGame> {

  @override
  void render(Canvas canvas) {
    final g = game;

    for (var i = 0; i < g.stack.length; i++) {
      _drawBlock(canvas, g.stack[i], i);
    }
    if (!g.gameOver) {
      _drawBlock(canvas, g.current, g.stack.length);
    }
  }

  void _drawBlock(Canvas canvas, Block b, int index) {

    double px = b.x + b.z * 0.3;
    double py = b.y - b.z * 0.2;
    double pw = b.w;
    double ph = b.h;

    final rect = Rect.fromLTWH(px, py, pw, ph);
    

    final sidePaint = Paint()..color = b.color.withValues(alpha: 0.6);
    final sidePath = Path()
      ..moveTo(px, py + ph)
      ..lineTo(px - 15, py + ph + 15)
      ..lineTo(px + pw - 15, py + ph + 15)
      ..lineTo(px + pw, py + ph)
      ..close();
    canvas.drawPath(sidePath, sidePaint);

    final leftPaint = Paint()..color = b.color.withValues(alpha: 0.8);
    final leftPath = Path()
      ..moveTo(px, py)
      ..lineTo(px - 15, py + 15)
      ..lineTo(px - 15, py + ph + 15)
      ..lineTo(px, py + ph)
      ..close();
    canvas.drawPath(leftPath, leftPaint);


    canvas.drawRect(rect, Paint()..color = b.color);
    

    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(rect);
    canvas.drawRect(rect, gloss);

    canvas.drawRect(rect, Paint()..style = PaintingStyle.stroke..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 1);
  }
}
