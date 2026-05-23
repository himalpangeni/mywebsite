import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';
import 'dart:math';

class Car {
  final List<Vector2> path;
  Vector2 position;
  double angle = 0;
  int targetIndex = 1;
  bool isParked = false;
  final Color color;

  Car({required this.path, required this.color})
      : position = path.first.clone();
}

class CarParkingGame extends FlameGame with PanDetector {

  final GameDifficulty difficulty;
  int score = 0;
  bool gameOver = false;
  late TextComponent hud;

  final List<Car> cars = [];
  final List<Vector2> activePath = [];
  Rect parkingSpot = Rect.zero;

  CarParkingGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFF263238);

  @override
  Future<void> onLoad() async {

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
    cars.clear();
    activePath.clear();
    _spawnParkingSpot();

    hud = TextComponent(
      text: 'PARKED: 0',
      position: Vector2(20, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
    add(hud);
    add(_ParkingRenderer());
    resumeEngine();
  }

  void _spawnParkingSpot() {
    final w = size.x;
    final h = size.y;
    final rx = Random().nextDouble() * (w - 120) + 60;
    final ry = Random().nextDouble() * (h * 0.4) + 100;
    parkingSpot =
        Rect.fromCenter(center: Offset(rx, ry), width: 70, height: 110);
  }

  void resumeGame() {
    gameOver = false;
    activePath.clear();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _lose() {
    gameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);

    for (final c in cars) {
      if (c.isParked) continue;

      if (c.targetIndex < c.path.length) {
        final target = c.path[c.targetIndex];
        final dir = (target - c.position);
        final dist = dir.length;

        if (dist < 8) {

          c.targetIndex++;
        } else {
          dir.normalize();
          c.position += dir * 180 * difficulty.speedMultiplier * dt;
          c.angle = atan2(dir.y, dir.x) + pi / 2;
        }
      } else {
        c.isParked = true;

        if (parkingSpot
            .inflate(10)
            .contains(Offset(c.position.x, c.position.y))) {
          score++;
          hud.text = 'PARKED: $score';
          _spawnParkingSpot();
        } else {
          _lose();
        }
      }
    }


    for (int i = 0; i < cars.length; i++) {
      for (int j = i + 1; j < cars.length; j++) {
        if (!cars[i].isParked || !cars[j].isParked) {

          if (cars[i].position.distanceTo(cars[j].position) < 35) {
            _lose();
          }
        }
      }
    }
  }

  @override
  void onPanDown(DragDownInfo info) {
    if (gameOver) return;
    activePath.clear();

    final p = info.eventPosition.global;
    if (p.y > size.y * 0.6) {
      activePath.add(p);
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (gameOver || activePath.isEmpty) return;
    final current = info.eventPosition.global;
    if (activePath.last.distanceTo(current) > 5) {

      activePath.add(current);
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (gameOver || activePath.length < 5) {
      activePath.clear();
      return;
    }

    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.amberAccent
    ];
    cars.add(Car(
        path: List.from(activePath),
        color: colors[cars.length % colors.length]));
    activePath.clear();
  }
}

class _ParkingRenderer extends Component with HasGameReference<CarParkingGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;


    final rrect =
        RRect.fromRectAndRadius(g.parkingSpot, const Radius.circular(8));

    canvas.drawRRect(
        rrect.inflate(4),
        _p
          ..color = Colors.yellowAccent.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    canvas.drawRRect(
        rrect,
        _p
          ..color = Colors.yellowAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    final tp = TextPainter(
        text: const TextSpan(
            text: 'P',
            style: TextStyle(
                color: Colors.yellowAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(
        canvas,
        Offset(g.parkingSpot.center.dx - tp.width / 2,
            g.parkingSpot.center.dy - tp.height / 2));


    if (g.activePath.isNotEmpty) {
      final path = Path()..moveTo(g.activePath.first.x, g.activePath.first.y);
      for (final p in g.activePath) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(
          path,
          _p
            ..color = Colors.white.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }


    for (final c in g.cars) {
      canvas.save();
      canvas.translate(c.position.x, c.position.y);
      canvas.rotate(c.angle);

      final carRect =
          Rect.fromCenter(center: Offset.zero, width: 32, height: 60);
      final carRRect =
          RRect.fromRectAndRadius(carRect, const Radius.circular(8));


      canvas.drawRRect(
          carRRect.shift(const Offset(4, 6)), _p..color = Colors.black45);


      canvas.drawRRect(
          carRRect,
          _p
            ..shader = LinearGradient(
                    colors: [c.color, c.color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                .createShader(carRect));


      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: const Offset(0, -10), width: 26, height: 16),
              const Radius.circular(4)),
          _p..color = Colors.black87);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: const Offset(0, 15), width: 26, height: 10),
              const Radius.circular(3)),
          _p..color = Colors.black87);


      canvas.drawCircle(
          const Offset(-10, -28),
          4,
          _p
            ..color = Colors.yellowAccent
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
      canvas.drawCircle(
          const Offset(10, -28),
          4,
          _p
            ..color = Colors.yellowAccent
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));

      canvas.restore();
    }
  }
}
