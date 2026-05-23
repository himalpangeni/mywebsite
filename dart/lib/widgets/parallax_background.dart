import 'dart:math';
import 'package:flutter/material.dart';

class ParallaxBackground extends StatefulWidget {
  final ScrollController? scrollController;
  const ParallaxBackground({super.key, this.scrollController});

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final List<_Star> _stars = List.generate(100, (_) => _Star());

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {

  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        if (widget.scrollController != null) widget.scrollController!,
      ]),
      builder: (context, child) {
        return CustomPaint(
          painter: _ParallaxPainter(
            stars: _stars,
            scrollOffset: widget.scrollController?.hasClients == true ? widget.scrollController!.offset : 0,
            pulse: _pulseController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Star {
  final double x = Random().nextDouble();
  final double y = Random().nextDouble();
  final double size = 1 + Random().nextDouble() * 3;
  final double depth = 0.2 + Random().nextDouble() * 0.8;
  final Color color = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.blueAccent,
    Colors.amberAccent
  ][Random().nextInt(5)];
}

class _ParallaxPainter extends CustomPainter {
  final List<_Star> stars;
  final double scrollOffset;
  final double pulse;

  _ParallaxPainter({required this.stars, required this.scrollOffset, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || size.width.isInfinite || size.height.isInfinite) return;

    final bgPaint = Paint()..shader = LinearGradient(

      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(const Color(0xFF02020A), const Color(0xFF050518), pulse)!,
        const Color(0xFF000000),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);



    final center = Offset(size.width / 2, size.height * 0.4);
    const rayCount = 16;
    final rayPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.15 + 0.05 * pulse)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pulse * 0.2);
    
    const rayAngle = (2 * pi) / rayCount;
    for (int i = 0; i < rayCount; i++) {
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(cos(i * rayAngle - 0.2) * 2000, sin(i * rayAngle - 0.2) * 2000)
          ..lineTo(cos(i * rayAngle + 0.2) * 2000, sin(i * rayAngle + 0.2) * 2000)
          ..close();
        canvas.drawPath(path, rayPaint);
    }
    canvas.restore();


    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.yellow.withValues(alpha: 0.1), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: 600));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(_ParallaxPainter oldDelegate) => true;
}
