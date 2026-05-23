import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../services/sensory.dart';
import 'cinematic_effects.dart';

class DepthGridTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ScrollController scrollController;
  final double xPos;
  final double yPos;
  final String? imageAsset;

  const DepthGridTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.scrollController,
    required this.xPos,
    required this.yPos,
    this.imageAsset,
  });

  @override
  State<DepthGridTile> createState() => _DepthGridTileState();
}

class _DepthGridTileState extends State<DepthGridTile>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _glintController;

  @override
  void initState() {
    super.initState();
    _glintController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _glintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final viewportWidth = MediaQuery.sizeOf(context).width;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          SensoryService.lightImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.scrollController, _glintController]),
          builder: (context, child) {
            final scrollOffset = widget.scrollController.hasClients ? widget.scrollController.offset : 0.0;
            final progress = ((widget.yPos - scrollOffset) / viewportHeight).clamp(0.0, 1.0);
            final xProgress = (widget.xPos / viewportWidth).clamp(0.0, 1.0);


            const perspective = 0.0015;
            final rotationX = (progress - 0.5) * 0.4;
            final rotationY = (xProgress - 0.5) * -0.3;
            
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 1.0, end: _isHovered ? 1.08 : 1.0),
              builder: (context, s, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, perspective)
                    ..rotateX(rotationX)
                    ..rotateY(rotationY)
                    ..scaleByVector3(Vector3(s, s, 1.0)),
                  child: child,
                );
              },
              child: child,
            );
          },
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1E26),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.8),
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [

                    CustomPaint(
                      painter: CyberGlintPainter(
                        progress: _glintController.value,
                        color: widget.color,
                      ),
                      size: Size.infinite,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.color.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: widget.color.withValues(alpha: 0.3),
                                  width: 2),
                            ),
                            child: widget.imageAsset != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.asset(widget.imageAsset!,
                                        width: 48, height: 48, fit: BoxFit.cover))
                                : Icon(widget.icon,
                                    size: 48, color: widget.color),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      offset: Offset(1, 1)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
