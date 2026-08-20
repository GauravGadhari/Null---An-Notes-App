import 'package:flutter/material.dart';

/// The signature Null glowing white ring widget.
/// Minimalist, refined size matching the icon and Apple aesthetic.
class NullGlowingRing extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double glowOpacity;
  final VoidCallback? onTap;

  const NullGlowingRing({
    super.key,
    this.size = 68.0,
    this.strokeWidth = 2.4,
    this.glowOpacity = 0.35,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ring = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF000000),
        boxShadow: [
          // Soft outer diffuse halo
          BoxShadow(
            color: Colors.white.withValues(alpha: glowOpacity * 0.45),
            blurRadius: size * 0.4,
            spreadRadius: 1,
          ),
          // Subtle inner glow
          BoxShadow(
            color: Colors.white.withValues(alpha: glowOpacity * 0.8),
            blurRadius: size * 0.15,
            spreadRadius: 0.5,
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: strokeWidth,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ring,
      );
    }

    return ring;
  }
}
