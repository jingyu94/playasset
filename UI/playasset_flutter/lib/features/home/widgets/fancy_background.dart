import 'package:flutter/material.dart';

class FancyBackground extends StatelessWidget {
  const FancyBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D1526),
                Color(0xFF0A1020),
                Color(0xFF080E19),
              ],
            ),
          ),
        ),
        Positioned(top: -120, left: -70, child: _orb(const Color(0x334C8DFF), 260)),
        Positioned(top: 180, right: -90, child: _orb(const Color(0x22FF6B81), 240)),
        Positioned(bottom: -130, left: 40, child: _orb(const Color(0x224A78D2), 280)),
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
