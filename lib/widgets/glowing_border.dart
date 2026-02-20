import 'package:flutter/material.dart';

class GlowingBorder extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double glowSpread;
  final double borderWidth;

  const GlowingBorder({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.glowSpread = 16,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: glowSpread,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
