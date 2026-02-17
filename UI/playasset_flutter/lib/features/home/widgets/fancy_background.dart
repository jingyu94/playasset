import 'package:flutter/material.dart';

class FancyBackground extends StatelessWidget {
  const FancyBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const [Color(0xFF060D18), Color(0xFF091323), Color(0xFF0B1628)]
        : const [Color(0xFFEFF4FF), Color(0xFFF7FAFF), Color(0xFFE9F1FF)];
    final orb1 = isDark ? const Color(0x10395D9A) : const Color(0x1F4989FF);
    final orb2 = isDark ? const Color(0x0D2E4A73) : const Color(0x16FF8A6B);
    final orb3 = isDark ? const Color(0x0D4F6B8A) : const Color(0x1644D5C9);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: background,
            ),
          ),
        ),
        Positioned(top: -76, left: -42, child: _orb(orb1, 150)),
        Positioned(top: 270, right: -64, child: _orb(orb2, 138)),
        Positioned(bottom: -84, left: 34, child: _orb(orb3, 162)),
        child,
      ],
    );
  }

  Widget _orb(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              const Color(0x00000000),
            ],
          ),
        ),
      ),
    );
  }
}
