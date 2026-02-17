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
        isDark ? const Color(0xFF2A3B59) : const Color(0xFFD3E0F8);
    final iconColor =
        isDark ? const Color(0xFFEAF1FF) : const Color(0xFF1B2C4D);

    return SizedBox(
      width: 50,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -5,
            top: -6,
            child: _glowDot(primary.withOpacity(0.12), 8),
          ),
          Positioned(
            left: -4,
            bottom: -6,
            child: _glowDot(secondary.withOpacity(0.1), 8),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  primary.withOpacity(isDark ? 0.11 : 0.17),
                  secondary.withOpacity(isDark ? 0.09 : 0.14),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 13, color: iconColor),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 5,
                  height: 5,
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
