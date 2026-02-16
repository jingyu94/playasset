import 'package:flutter/material.dart';

class FancyBackground extends StatelessWidget {
  const FancyBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const [Color(0xFF0D1526), Color(0xFF0A1020), Color(0xFF080E19)]
        : const [Color(0xFFEFF4FF), Color(0xFFF7FAFF), Color(0xFFE9F1FF)];
    final orb1 = isDark ? const Color(0x334C8DFF) : const Color(0x334989FF);
    final orb2 = isDark ? const Color(0x22FF6B81) : const Color(0x22FF8A6B);
    final orb3 = isDark ? const Color(0x224A78D2) : const Color(0x2244D5C9);

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
        Positioned(top: -120, left: -70, child: _orb(orb1, 260)),
        Positioned(top: 180, right: -90, child: _orb(orb2, 240)),
        Positioned(bottom: -130, left: 40, child: _orb(orb3, 280)),
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
