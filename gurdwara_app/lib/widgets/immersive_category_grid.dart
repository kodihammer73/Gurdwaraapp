import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// A modern, immersive, card-based category grid inspired by the Apple App Store
/// browse page. Each card features vibrant gradients, layered composition,
/// glassmorphism effects, and 3D floating depth.
class ImmersiveCategoryGrid extends StatelessWidget {
  const ImmersiveCategoryGrid({
    super.key,
    required this.categories,
    this.crossAxisCount = 2,
    this.aspectRatio = 4 / 3,
    this.cardBorderRadius = 20.0,
  });

  final List<ImmersiveCategory> categories;
  final int crossAxisCount;
  final double aspectRatio;
  final double cardBorderRadius;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _ImmersiveCategoryCard(
          category: categories[index],
          borderRadius: cardBorderRadius,
        );
      },
    );
  }
}

/// Data model for an immersive category card.
class ImmersiveCategory {
  const ImmersiveCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    this.onTap,
    this.accentColor,
    this.geometricShapes = const [],
    this.customContentBuilder,
    this.fullContentBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final Color? accentColor;
  final List<ImmersiveShape> geometricShapes;

  /// Optional builder for custom content below the title/subtitle area.
  /// Useful for cards that need to display dynamic data (e.g., countdowns).
  final Widget Function(BuildContext context)? customContentBuilder;

  /// Optional builder that replaces the entire foreground content.
  /// When set, [title], [subtitle], [icon], and [customContentBuilder] are ignored.
  /// The builder receives the parallax animation offset for consistent animations.
  final Widget Function(BuildContext context, Animation<Offset> parallaxAnimation)?
      fullContentBuilder;
}

/// A geometric shape to render in the midground layer of a card.
class ImmersiveShape {
  const ImmersiveShape({
    required this.type,
    required this.left,
    required this.top,
    required this.size,
    this.color,
    this.opacity = 0.15,
    this.rotation = 0.0,
  });

  final ShapeType type;
  final double left;
  final double top;
  final double size;
  final Color? color;
  final double opacity;
  final double rotation;
}

enum ShapeType { circle, square, triangle, pill }

class _ImmersiveCategoryCard extends StatefulWidget {
  const _ImmersiveCategoryCard({
    required this.category,
    required this.borderRadius,
  });

  final ImmersiveCategory category;
  final double borderRadius;

  @override
  State<_ImmersiveCategoryCard> createState() => _ImmersiveCategoryCardState();
}

class _ImmersiveCategoryCardState extends State<_ImmersiveCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _parallaxAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _parallaxAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -4),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final borderRadius = widget.borderRadius;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          category.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: category.gradientColors.last.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: category.gradientColors.first.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              children: [
                // Background Layer: Vibrant gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: category.gradientColors,
                      ),
                    ),
                  ),
                ),

                // Midground Layer: Abstract geometric shapes
                ...category.geometricShapes.map((shape) =>
                    _buildGeometricShape(shape, borderRadius)),

                // Default decorative shapes if none provided
                if (category.geometricShapes.isEmpty)
                  ..._buildDefaultShapes(category.gradientColors),

                // Foreground Layer: Glassmorphism overlay + content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: category.fullContentBuilder != null
                        ? AnimatedBuilder(
                            animation: _parallaxAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _parallaxAnimation.value,
                                child: category.fullContentBuilder!(
                                    context, _parallaxAnimation),
                              );
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon with glassmorphism background
                              AnimatedBuilder(
                                animation: _parallaxAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: _parallaxAnimation.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          category.icon,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Custom content or spacer
                              if (category.customContentBuilder != null)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child:
                                        category.customContentBuilder!(context),
                                  ),
                                )
                              else
                                const Spacer(),

                              // Title with glassmorphism
                              AnimatedBuilder(
                                animation: _parallaxAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      -_parallaxAnimation.value.dy * 0.5,
                                    ),
                                    child: child,
                                  );
                                },
                                child: Text(
                                  category.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Subtitle with glassmorphism
                              AnimatedBuilder(
                                animation: _parallaxAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      -_parallaxAnimation.value.dy * 0.3,
                                    ),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 6,
                                        sigmaY: 6,
                                      ),
                                      child: Text(
                                        category.subtitle,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeometricShape(ImmersiveShape shape, double borderRadius) {
    return Positioned(
      left: shape.left,
      top: shape.top,
      child: Transform.rotate(
        angle: shape.rotation * math.pi / 180,
        child: Opacity(
          opacity: shape.opacity,
          child: Container(
            width: shape.size,
            height: shape.size,
            decoration: BoxDecoration(
              color: shape.color ?? Colors.white,
              borderRadius: shape.type == ShapeType.circle
                  ? BorderRadius.circular(shape.size / 2)
                  : shape.type == ShapeType.pill
                      ? BorderRadius.circular(shape.size / 2)
                      : shape.type == ShapeType.square
                          ? BorderRadius.circular(4)
                          : null,
            ),
            child: shape.type == ShapeType.triangle
                ? CustomPaint(
                    painter: _TrianglePainter(
                      color: shape.color ?? Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDefaultShapes(List<Color> gradientColors) {
    final shapes = <Widget>[];
    final accent = gradientColors.length > 1
        ? gradientColors[1].withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.15);

    // Large circle top-right
    shapes.add(
      Positioned(
        right: -20,
        top: -20,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(60),
          ),
        ),
      ),
    );

    // Small circle bottom-left
    shapes.add(
      Positioned(
        left: -10,
        bottom: 30,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );

    // Pill shape mid-right
    shapes.add(
      Positioned(
        right: 10,
        bottom: 40,
        child: Transform.rotate(
          angle: 30 * math.pi / 180,
          child: Container(
            width: 80,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );

    // Small square top-left
    shapes.add(
      Positioned(
        left: 40,
        top: 50,
        child: Transform.rotate(
          angle: 15 * math.pi / 180,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );

    return shapes;
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
