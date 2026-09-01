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
        // 模糊背景不需要按屏幕分辨率解码；小纹理放大后再做低半径模糊，
        // 能显著减少 GPU 离屏采样和图片内存。
        cacheWidth: blur > 0 ? 384 : null,
        filterQuality: blur > 0 ? FilterQuality.low : FilterQuality.medium,
      ),
    );
    return RepaintBoundary(
      child: ClipRect(
        child: blur <= 0
            ? image
            : ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blur.clamp(0.0, 5.0),
                  sigmaY: blur.clamp(0.0, 5.0),
                ),
                child: Transform.scale(scale: 1.08, child: image),
              ),
      ),
    );
  }
}
