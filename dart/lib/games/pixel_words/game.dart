
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/difficulty.dart';
import '../../widgets/cinematic_effects.dart';
import '../../services/sensory.dart';

enum IngredientType { bread, cheese, tomato, meat, lettuce }

class PixelWordsGame extends FlameGame with TapCallbacks, HasCollisionDetection {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  late final Random _random;
  final GameDifficulty difficulty;
  List<IngredientType> currentOrder = [];
  int currentStep = 0;
  int ordersCompleted = 0;
  bool isGameOver = false;

  late TextComponent scoreText;
  late OrderDisplay orderDisplay;
  late ScreenShake shaker;
  late Sprite logoSprite;

  double speedMultiplier = 1.0;
  double _progressionTimer = 0;
  double _spawnTimer = 0;

  PixelWordsGame({required this.difficulty}) : super() {
    speedMultiplier = difficulty.speedMultiplier;
  }

  @override
  Color backgroundColor() => const Color(0xFF2D1B1B);

  @override
  Future<void> onLoad() async {
    _random = Random();
    await super.onLoad();
    logoSprite = await loadSprite('logo.png');
    restart();
  }

  void restart() {
    for (final child in children.toList()) {
      if (child is! CameraComponent && !child.runtimeType.toString().contains('Dispatcher')) child.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    ordersCompleted = 0;
    isGameOver = false;
    _progressionTimer = 0;
    speedMultiplier = difficulty.speedMultiplier;

    shaker = ScreenShake();
    add(shaker);
    scoreText = TextComponent(
      text: 'ORDERS: 0',
      position: Vector2(size.x / 2, 80),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2)),
    );
    add(scoreText);


    add(TextComponent(
      text: 'PIXEL WORDS',
      position: Vector2(size.x / 2, size.y * 0.4),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 10)),
    ));
    add(SpriteComponent(
      sprite: logoSprite,
      size: Vector2.all(40),
      position: Vector2(size.x - 45, 45),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.25),
    ));

    orderDisplay = OrderDisplay();
    add(orderDisplay);

    _newOrder();
    resumeEngine();
  }

  void resumeGame() {
    isGameOver = false;
    currentStep = 0;
    _spawnTimer = 0;
    for (final child in children.whereType<Ingredient>().toList()) {
      child.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _newOrder() {
    currentStep = 0;
    final random = Random();
    int size = (difficulty == GameDifficulty.easy
        ? 2
        : (difficulty == GameDifficulty.medium ? 3 : 4));
    currentOrder = List.generate(
        size,
        (_) => IngredientType
            .values[random.nextInt(IngredientType.values.length)]);
    if (orderDisplay.isLoaded) orderDisplay.updateOrder(currentOrder);
  }

  @override
  void update(double dt) {
    if (isGameOver) return;
    super.update(dt);

    _progressionTimer += dt;
    if (_progressionTimer >= 15.0) {
      _progressionTimer = 0;
      speedMultiplier += 0.15;
    }

    _spawnTimer += dt;
    double spawnInterval = (1.2 / speedMultiplier).clamp(0.4, 1.5);
    if (_spawnTimer >= spawnInterval) {
      _spawnTimer = 0;
      add(Ingredient(
          type: IngredientType
              .values[_random.nextInt(IngredientType.values.length)]));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;

    for (final child in children) {
      if (child is Ingredient) {

        final center = size.x / 2;
        final targetY = size.y - 120;
        if ((child.position.x - center).abs() < 60 &&
            (child.position.y - targetY).abs() < 60) {
          if (child.type == currentOrder[currentStep]) {
            currentStep++;
            child.removeFromParent();
            shaker.shake(duration: 0.1, intensity: 3);
            if (currentStep >= currentOrder.length) {
              ordersCompleted++;
              scoreText.text = 'ORDERS: $ordersCompleted';
              _newOrder();
            }
            return;
          } else {
            gameOver();
            return;
          }
        }
      }
    }
  }

  void gameOver() {
    SensoryService.heavyImpact();
    isGameOver = true;
    shaker.shake(duration: 0.5, intensity: 10);
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void render(Canvas canvas) {

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
        rect,
        _p
          ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3E2723), Color(0xFF1B1B1B)])
              .createShader(rect));


    final beltRect = Rect.fromLTWH(0, size.y - 150, size.x, 60);
    canvas.drawRect(beltRect, _p..color = Colors.black45);
    canvas.drawRect(
        beltRect,
        _p
          ..color = Colors.white10
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);


    final markerPaint = _p
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(size.x / 2, size.y - 120), 50, markerPaint);

    super.render(canvas);
  }
}

class Ingredient extends PositionComponent with HasGameReference<PixelWordsGame> {


  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  final IngredientType type;
  Ingredient({required this.type})
      : super(size: Vector2(70, 70), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {


    position = Vector2(game.size.x + 100, game.size.y - 120);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) return;
    position.x -= 350 * dt * game.speedMultiplier;
    if (position.x < -100) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final rrect =
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(12));


    canvas.drawRRect(
        rrect.shift(const Offset(4, 4)), _p..color = Colors.black26);


    canvas.drawRRect(
        rrect,
        _p
          ..shader = LinearGradient(
                  colors: [_getTopColor(type), _getBottomColor(type)])
              .createShader(size.toRect()));


    canvas.drawRRect(
        rrect,
        _p
          ..color = Colors.white30
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);


    final iconText = type.name.substring(0, 1).toUpperCase();
    TextPaint(
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)]))
        .render(canvas, iconText, Vector2(size.x / 2 - 12, size.y / 2 - 20));
  }

  Color _getTopColor(IngredientType t) {
    switch (t) {
      case IngredientType.bread:
        return const Color(0xFFFFCC80);
      case IngredientType.cheese:
        return const Color(0xFFFFF176);
      case IngredientType.tomato:
        return const Color(0xFFE57373);
      case IngredientType.meat:
        return const Color(0xFF8D6E63);
      case IngredientType.lettuce:
        return const Color(0xFF81C784);
    }
  }

  Color _getBottomColor(IngredientType t) {
    switch (t) {
      case IngredientType.bread:
        return const Color(0xFFEF6C00);
      case IngredientType.cheese:
        return const Color(0xFFFBC02D);
      case IngredientType.tomato:
        return const Color(0xFFC62828);
      case IngredientType.meat:
        return const Color(0xFF4E342E);
      case IngredientType.lettuce:
        return const Color(0xFF2E7D32);
    }
  }
}

class OrderDisplay extends PositionComponent with HasGameReference<PixelWordsGame> {


  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  final _cachedPaint = Paint();
  OrderDisplay() : super(size: Vector2(300, 100), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {


    position = Vector2(game.size.x / 2, 200);
  }

  void updateOrder(List<IngredientType> newOrder) {}

  @override
  void render(Canvas canvas) {
    final order = game.currentOrder;
    final step = game.currentStep;


    final plateRect =
        Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y);
    canvas.drawRRect(
        RRect.fromRectAndRadius(plateRect, const Radius.circular(20)),
        _p..color = Colors.white10);

    TextPaint(
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5))
        .render(canvas, 'RECIPE', Vector2(-size.x / 2 + 20, -size.y / 2 + 10));

    double startX = -((order.length - 1) * 50) / 2;
    for (int i = 0; i < order.length; i++) {
      final color = (i < step) ? Colors.white24 : _getColor(order[i]);
      final circlePos = Offset(startX + i * 50, 10);

      canvas.drawCircle(circlePos, 22, _p..color = Colors.black26);
      canvas.drawCircle(circlePos, 20, _p..color = color);

      final label = order[i].name.substring(0, 1).toUpperCase();
      TextPaint(
              style: TextStyle(
                  color: (i < step) ? Colors.white12 : Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w900))
          .render(canvas, label, Vector2(circlePos.dx - 8, circlePos.dy - 12));

      if (i == step) {
        canvas.drawCircle(
            circlePos,
            25,
            _p
              ..color = Colors.cyanAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
  }

  Color _getColor(IngredientType t) {
    switch (t) {
      case IngredientType.bread:
        return const Color(0xFFFFB74D);
      case IngredientType.cheese:
        return const Color(0xFFFFF176);
      case IngredientType.tomato:
        return const Color(0xFFE57373);
      case IngredientType.meat:
        return const Color(0xFF8D6E63);
      case IngredientType.lettuce:
        return const Color(0xFF81C784);
    }
  }
}
