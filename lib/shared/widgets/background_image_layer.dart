import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

class BackgroundImageLayer extends StatelessWidget {
  const BackgroundImageLayer({
    super.key,
    required this.path,
    required this.blur,
    required this.brightness,
  });

  final String? path;
  final double blur;
  final double brightness;

  @override
  Widget build(BuildContext context) {
    final value = path;
    if (value == null || value.isEmpty || !File(value).existsSync()) {
      return const SizedBox.shrink();
    }
    final image = ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        brightness, 0, 0, 0, 0,
        0, brightness, 0, 0, 0,
        0, 0, brightness, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Image.file(
        File(value),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
    return ClipRect(
      child: blur <= 0
          ? image
          : ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Transform.scale(scale: 1.08, child: image),
            ),
    );
  }
}
