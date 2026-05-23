import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';


class CinematicOverlay extends Component with HasGameReference {
  late Paint _vignettePaint;
  final _random = Random();
  final List<Offset> _grainPoints = [];

  Vector2? _lastSize;
  
  @override
  void render(Canvas canvas) {
    final sz = game.size;
    if (sz.x <= 0 || sz.y <= 0) return;
    
    if (_lastSize != sz) {
      _lastSize = sz.clone();

      _vignettePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent, 
            Colors.black.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.7)
          ],
          stops: const [0.5, 0.8, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, sz.x, sz.y));
      
      _grainPoints.clear();
      for (int i = 0; i < 24; i++) {
        _grainPoints.add(Offset(_random.nextDouble() * sz.x, _random.nextDouble() * sz.y));
      }
    }

    canvas.drawRect(Rect.fromLTWH(0, 0, sz.x, sz.y), _vignettePaint);
    

    final grainPaint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    if (_random.nextDouble() < 0.15) {
       for (int i = 0; i < _grainPoints.length; i++) {
         _grainPoints[i] = Offset(_random.nextDouble() * sz.x, _random.nextDouble() * sz.y);
       }
    }

    for (final p in _grainPoints) {
      canvas.drawRect(Rect.fromLTWH(p.dx, p.dy, 1.5, 1.5), grainPaint);
    }
  }
}


class ScreenShake extends Component with HasGameReference {
  double _timer = 0;
  double _intensity = 0;
  final _random = Random();

  void shake({double duration = 0.3, double intensity = 8.0}) {
    _timer = duration;
    _intensity = intensity;
  }

  void reset() {
    _timer = 0;
    _intensity = 0;
    game.camera.viewfinder.position = Vector2.zero();
  }

  @override
  void onRemove() {
    try {
      game.camera.viewfinder.position = Vector2.zero();
    } catch (_) {}
    super.onRemove();
  }

  @override
  void update(double dt) {
    if (_timer > 0) {
      _timer -= dt;
      game.camera.viewfinder.position = Vector2(
        (_random.nextDouble() - 0.5) * _intensity,
        (_random.nextDouble() - 0.5) * _intensity,
      );
      if (_timer <= 0) {
        game.camera.viewfinder.position = Vector2.zero();
      }
    }
  }
}


class SparkParticle extends PositionComponent {
  Vector2 velocity;
  double life;
  final Color color;
  final double _gravity = 320;

  SparkParticle({
    required Vector2 position,
    required this.velocity,
    required this.color,
    this.life = 1.0,
  }) {
    this.position = position;
  }

  @override
  void update(double dt) {
    position += velocity * dt;
    velocity.y += _gravity * dt;
    life -= dt * 2.2;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = life.clamp(0.0, 1.0);
    final radius = 3.5 * alpha;
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius),
    );
  }
}


class SparkEmitter extends Component with HasGameReference {
  final Vector2 position;
  final Color color;
  final int count;

  SparkEmitter({required this.position, required this.color, this.count = 8});

  final _random = Random();
  @override
  void onLoad() {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 60 + _random.nextDouble() * 200;
      game.add(SparkParticle(
        position: position.clone(),
        velocity: Vector2(cos(angle), sin(angle)) * speed,
        color: color,
        life: 0.4 + _random.nextDouble() * 0.6,
      ));
    }
    removeFromParent();
  }
}


class NeonTrail extends Component with HasGameReference {
  final List<Offset> points = [];
  final Color color;
  final double strokeWidth;
  final int maxLength;

  NeonTrail({required this.color, this.strokeWidth = 3.0, this.maxLength = 15});

  void addPoint(Offset p) {
    points.add(p);
    if (points.length > maxLength) points.removeAt(0);
  }

  @override
  void render(Canvas canvas) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      paint.color = color.withValues(alpha: i / points.length);
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }
}


class CyberGlintPainter extends CustomPainter {
  final double progress;
  final Color color;

  CyberGlintPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [
          (progress - 0.2).clamp(0.0, 1.0),
          progress.clamp(0.0, 1.0),
          (progress + 0.2).clamp(0.0, 1.0)
        ],
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CyberGlintPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ConfettiEmitter extends Component with HasGameReference {
  final _random = Random();
  final int count;
  ConfettiEmitter({this.count = 40});

  @override
  void onLoad() {
    for (int i = 0; i < count; i++) {
      final x = _random.nextDouble() * game.size.x;
      final speed = 150 + _random.nextDouble() * 250;
      final color = Colors.primaries[_random.nextInt(Colors.primaries.length)];
      game.add(_ConfettiPiece(
        position: Vector2(x, -50),
        velocity: Vector2((_random.nextDouble() - 0.5) * 100, speed),
        color: color,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      ));
    }
    removeFromParent();
  }
}

class _ConfettiPiece extends PositionComponent {
  Vector2 velocity;
  final Color color;
  final double rotationSpeed;
  double _time = 0;

  _ConfettiPiece({required Vector2 position, required this.velocity, required this.color, required this.rotationSpeed}) {
    this.position = position;
    size = Vector2(8, 12);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    _time += dt;
    position += velocity * dt;
    angle += rotationSpeed * dt;
    velocity.x += sin(_time * 3) * 20 * dt;
    if (position.y > 1000) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = color);
  }
}
