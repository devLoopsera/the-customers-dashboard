import 'package:flutter/material.dart';

class GlowingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color glowColor;

  const GlowingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.glowColor = const Color(0xFF309278),
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: glowColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: glowColor.withOpacity(0.2)),
        ),
      ),
      child: child,
    );
  }
}
