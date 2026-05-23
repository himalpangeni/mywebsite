
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/difficulty.dart';
import '../../services/sensory.dart';

class NeonTankGame extends FlameGame with KeyboardEvents, HasCollisionDetection {


  late Tank player;
  late JoystickComponent joystick;
  late HudButtonComponent fireButton;
  int score = 0;
  bool isGameOver = false;
  late TextComponent scoreText;
  late Sprite logoSprite;
  
  final GameDifficulty difficulty;
  double speedMultiplier = 1.0;
  double _progressionTimer = 0;

  NeonTankGame({required this.difficulty}) : super() {
    speedMultiplier = difficulty.speedMultiplier;
  }

  @override
  Future<void> onLoad() async {
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
        if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    score = 0;
    isGameOver = false;
    _progressionTimer = 0;
    speedMultiplier = difficulty.speedMultiplier;

    player = Tank(isPlayer: true);
    add(player);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 28, paint: Paint()..color = Colors.limeAccent),
      background: CircleComponent(
          radius: 55,
          paint: Paint()
            ..color = Colors.limeAccent.withValues(alpha: 0.1)
            ..style = PaintingStyle.fill),
      margin: const EdgeInsets.only(left: 35, bottom: 35),
    );
    add(joystick);

    fireButton = HudButtonComponent(
      button: CircleComponent(
          radius: 35,
          paint: Paint()..color = Colors.redAccent.withValues(alpha: 0.4)),
      buttonDown: CircleComponent(
          radius: 35, paint: Paint()..color = Colors.redAccent),
      margin: const EdgeInsets.only(right: 35, bottom: 35),
      onPressed: player.fire,
    );
    add(fireButton);
    

    add(TextComponent(
      text: '🔥',
      position: size - Vector2(70, 70),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 30)),
    ));

    scoreText = TextComponent(
      text: 'WINS: 0',
      position: Vector2(size.x / 2, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.limeAccent, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
    add(scoreText);
    

    add(TextComponent(
      text: 'NEON TANK',
      position: Vector2(size.x / 2, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.limeAccent.withValues(alpha: 0.1), fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 10)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(50),
      position: Vector2(size.x / 2, 40),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.limeAccent.withValues(alpha: 0.4),
    ));

    add(TextComponent(
      text: 'JOYSTICK to move • FIRE BUTTON to shoot',
      position: Vector2(size.x / 2, size.y - 130),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white70, fontSize: 16)),
    ));

    _showInstructions();


    for (int i = 0; i < (difficulty == GameDifficulty.easy ? 1 : 2); i++) {
        _spawnEnemy();
    }

    resumeEngine();
  }

  void _showInstructions() {
      final hint = TextComponent(
          text: 'DRAG TO MOVE • TAP TO FIRE\nELIMINATE THE ENEMY TANKS',
          position: size / 2 + Vector2(0, 100),
          anchor: Anchor.center,
          textRenderer: TextPaint(style: const TextStyle(color: Colors.white60, fontSize: 16)),
      );
      add(hint);
      Future.delayed(const Duration(seconds: 4), () => hint.removeFromParent());
  }

  void _spawnEnemy() {
      add(Tank(isPlayer: false));
  }

  bool _isLeft = false;
  bool _isRight = false;
  bool _isUp = false;
  bool _isDown = false;

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    _progressionTimer += dt;
    if (_progressionTimer >= 15.0) {
      _progressionTimer = 0;
      speedMultiplier += 0.2;
    }


    if (_isLeft || _isRight || _isUp || _isDown) {
      double dx = 0;
      double dy = 0;
      if (_isLeft) dx -= 1;
      if (_isRight) dx += 1;
      if (_isUp) dy -= 1;
      if (_isDown) dy += 1;

      if (dx != 0 || dy != 0) {
        final vec = Vector2(dx, dy).normalized();
        player.position += vec * 200 * dt;
        player.angle = atan2(dy, dx);
      }
    }


    if (!joystick.delta.isZero()) {
      player.position.add(joystick.relativeDelta * 200 * dt);
      player.angle = joystick.delta.screenAngle();
    }
  }

  void resumeGame() {
    isGameOver = false;
    for (var c in children.whereType<TankBullet>().toList()) {
      c.removeFromParent();
    }
    overlays.remove('GameOver');
    resumeEngine();
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void addScore() {
    score++;
    scoreText.text = 'WINS: $score';
    _spawnEnemy();
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (isGameOver) return KeyEventResult.ignored;

    _isLeft = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    _isRight = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    _isUp = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW);
    _isDown = keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS);

    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      player.fire();
    }

    return KeyEventResult.handled;
  }
}

class Tank extends PositionComponent with HasGameReference<NeonTankGame>, CollisionCallbacks {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final bool isPlayer;
  Tank({required this.isPlayer}) : super(size: Vector2(60, 60), anchor: Anchor.center);
  double _fireTimer = 0;

  @override
  Future<void> onLoad() async {
    if (isPlayer) {
        position = game.size / 2;
    } else {
        final random = Random();
        position = Vector2(random.nextDouble() * game.size.x, random.nextDouble() * game.size.y);

        if (position.distanceTo(game.player.position) < 150) position.add(Vector2(200, 200));
    }
    add(CircleHitbox(radius: 28, anchor: Anchor.center, position: Vector2(30, 30)));
  }

  void fire() {
    final direction = Vector2(cos(angle), sin(angle));
    game.add(TankBullet(position: position + direction * 40, direction: direction, isPlayer: isPlayer));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;

    if (!isPlayer) {

        final toPlayer = (game.player.position - position).normalized();
        position += toPlayer * 100 * dt * game.speedMultiplier;
        angle = atan2(toPlayer.y, toPlayer.x);

        _fireTimer += dt;
        double fireInterval = (3.0 / game.speedMultiplier).clamp(0.5, 5.0);
        if (_fireTimer >= fireInterval) {
            _fireTimer = 0;
            fire();
        }
    }

    position.x = position.x.clamp(30, game.size.x - 30);
    position.y = position.y.clamp(30, game.size.y - 30);
  }

  @override
  void render(Canvas canvas) {
    final bodyColor = isPlayer ? Colors.limeAccent : Colors.redAccent;
    final shadowPaint = _p..color = Colors.black45;
    

    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect().shift(const Offset(4, 4)), const Radius.circular(8)), shadowPaint);
    

    final bodyPaint = _p..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bodyColor, bodyColor.withValues(alpha: 0.7)]
    ).createShader(size.toRect());
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)), bodyPaint);
    

    canvas.drawCircle(Offset(size.x/2, size.y/2), 15, _p..color = Colors.black26);
    canvas.drawCircle(Offset(size.x/2, size.y/2), 12, _p..color = bodyColor);
    

    final barrelRect = Rect.fromLTWH(size.x/2, -5 + size.y/2, 40, 10);
    canvas.drawRect(barrelRect, _p..color = bodyColor);
    canvas.drawRect(barrelRect, _p..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is TankBullet && other.isPlayer != isPlayer) {
        if (!isPlayer) {
            game.addScore();
            removeFromParent();
        } else {
            game.gameOver();
        }
        other.removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class TankBullet extends PositionComponent with HasGameReference<NeonTankGame>, CollisionCallbacks {
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  final Vector2 direction;
  final bool isPlayer;
  TankBullet({required Vector2 position, required this.direction, required this.isPlayer}) : super(position: position, size: Vector2(10, 10), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * 500 * dt * (isPlayer ? 1.0 : game.speedMultiplier);
    if (position.x < 0 || position.x > game.size.x || position.y < 0 || position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 5, _p..color = isPlayer ? Colors.yellow : Colors.deepOrange);
  }
}
