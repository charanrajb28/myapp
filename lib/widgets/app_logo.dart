import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;
  final String? heroTag;

  const AppLogo({
    super.key,
    this.size = 80,
    this.fit = BoxFit.contain,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.school_rounded,
          size: size,
          color: const Color(0xFF0F172A),
        );
      },
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: image,
      );
    }

    return image;
  }
}
