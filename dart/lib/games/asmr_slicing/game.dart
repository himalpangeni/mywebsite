import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/difficulty.dart';

class ASMRSlicingGame extends FlameGame with PanDetector {
  final GameDifficulty difficulty;
  int score = 0;
  late Vector2 bladePos;
  final List<SliceableObject> objects = [];

  ASMRSlicingGame({required this.difficulty});

  @override
  Color backgroundColor() => const Color(0xFFB0BEC5);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    await super.onLoad();
    restart();
  }

  void restart() {
    for (var c in children.toList()) {
      if (c is! CameraComponent && !c.runtimeType.toString().contains('Dispatcher')) c.removeFromParent();
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    overlays.remove('GameOver');

    score = 0;
    bladePos = size / 2;
    objects.clear();
    

    _spawnBlock();
    
    add(_SliceRenderer());
    resumeEngine();
  }

  void resumeGame() {
    score = score - 10;
    objects.clear();
    _spawnBlock();
    overlays.remove('GameOver');
    resumeEngine();
  }

  void _spawnBlock() {
      objects.add(SliceableObject(rect: Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: 220, height: 350), color: Colors.pinkAccent));
  }

  @override
  void update(double dt) {
    if (overlays.isActive('GameOver')) return;
    super.update(dt);
    
    for (int i = objects.length - 1; i >= 0; i--) {
        final obj = objects[i];
        if (obj.isFalling) {
            obj.fallSpeed += 1200 * dt;
            obj.rect = obj.rect.translate(obj.sideSpeed * dt, obj.fallSpeed * dt);
            if (obj.rect.top > size.y) objects.removeAt(i);
        }
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final p = info.eventPosition.global;
    bladePos = p;
    

    for (int i = 0; i < objects.length; i++) {
        final obj = objects[i];
        if (obj.rect.contains(p.toOffset()) && !obj.isSlicing) {

            _sliceObject(obj, p.y);
            break;
        }
    }
  }

  void _sliceObject(SliceableObject obj, double sliceY) {
      if (obj.rect.height < 10) return;
      
      objects.remove(obj);
      score += 1;
      

      objects.add(SliceableObject(rect: Rect.fromLTRB(obj.rect.left, obj.rect.top, obj.rect.right, sliceY - 5), color: obj.color));

      objects.add(SliceableObject(
          rect: Rect.fromLTRB(obj.rect.left, sliceY - 5, obj.rect.right, sliceY + 5), 
          color: obj.color, 
          isFalling: true,
          sideSpeed: (Random().nextDouble() - 0.5) * 400));

      objects.add(SliceableObject(rect: Rect.fromLTRB(obj.rect.left, sliceY + 5, obj.rect.right, obj.rect.bottom), color: obj.color));
      
      if (score > 100) {
          overlays.add('GameOver');
      }
  }
}

class SliceableObject {
    Rect rect;
    Color color;
    bool isSlicing = false;
    bool isFalling = false;
    double fallSpeed = 0;
    double sideSpeed = 0;
    SliceableObject({required this.rect, required this.color, this.isFalling = false, this.sideSpeed = 0});
}

class _SliceRenderer extends Component with HasGameReference<ASMRSlicingGame> {
  final _cachedPaint = Paint();
  Paint get _p => _cachedPaint..maskFilter = null..shader = null..style = PaintingStyle.fill..strokeWidth = 1;
  @override
  void render(Canvas canvas) {
    final g = game;
    

    canvas.drawRect(Rect.fromLTWH(0, g.size.y / 2 + 180, g.size.x, 30), _p..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawRect(Rect.fromLTWH(0, g.size.y / 2 + 180, g.size.x, 20), _p..color = Colors.grey.shade300);

    for (final obj in g.objects) {
        if (obj.isFalling) {
            canvas.drawRRect(RRect.fromRectAndRadius(obj.rect, const Radius.circular(2)), _p..color = obj.color.withValues(alpha: 0.8));
        } else {

            final sandPaint = _p..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [obj.color, obj.color.withValues(alpha: 0.8)],
            ).createShader(obj.rect);
            canvas.drawRRect(RRect.fromRectAndRadius(obj.rect, const Radius.circular(4)), sandPaint);
            

            final grainP = _p..color = Colors.black.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 1.5;
            for (double y = obj.rect.top; y < obj.rect.bottom; y += 6) {
                canvas.drawLine(Offset(obj.rect.left, y), Offset(obj.rect.right, y), grainP);
            }
        }
    }


    canvas.drawRect(Rect.fromCenter(center: g.bladePos.toOffset() + const Offset(5, 5), width: 280, height: 6), _p..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    final bladePaint = _p..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: g.bladePos.toOffset(), width: 280, height: 4), bladePaint);
    canvas.drawRect(Rect.fromCenter(center: g.bladePos.toOffset() - const Offset(0, 3), width: 280, height: 2), _p..color = Colors.white70);
  }
}
