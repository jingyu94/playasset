import 'package:flutter/material.dart';

class ComplementaryAccent extends StatelessWidget {
  const ComplementaryAccent({
    required this.icon,
    required this.primary,
    required this.secondary,
    super.key,
  });

  final IconData icon;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF2A3D62) : const Color(0xFFD3E0F8);
    final iconColor =
        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1B2C4D);

    return SizedBox(
      width: 54,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -6,
            top: -7,
            child: _glowDot(primary.withOpacity(0.34), 14),
          ),
          Positioned(
            left: -5,
            bottom: -7,
            child: _glowDot(secondary.withOpacity(0.3), 12),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  primary.withOpacity(0.17),
                  secondary.withOpacity(0.14),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 14, color: iconColor),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowDot(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, const Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}
