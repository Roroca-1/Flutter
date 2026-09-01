import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

class BackgroundImageLayer extends StatefulWidget {
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
  State<BackgroundImageLayer> createState() => _BackgroundImageLayerState();
}

class _BackgroundImageLayerState extends State<BackgroundImageLayer> {
  ImageProvider? _provider;
  String? _loadedPath;

  void _updateProvider() {
    final value = widget.path;
    if (value == _loadedPath) return;
    _loadedPath = value;
    if (value == null || value.isEmpty || !File(value).existsSync()) {
      _provider = null;
      return;
    }
    // Keep one stable cache key and one decoded frame across route changes.
    _provider = ResizeImage(FileImage(File(value)), width: 720);
  }

  @override
  void initState() {
    super.initState();
    _updateProvider();
  }

  @override
  void didUpdateWidget(covariant BackgroundImageLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateProvider();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    if (provider == null) {
      return const SizedBox.shrink();
    }
    final image = ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        widget.brightness, 0, 0, 0, 0,
        0, widget.brightness, 0, 0, 0,
        0, 0, widget.brightness, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Image(
        image: provider,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        // 模糊背景不需要按屏幕分辨率解码；小纹理放大后再做低半径模糊，
        // 能显著减少 GPU 离屏采样和图片内存。
        filterQuality: FilterQuality.low,
      ),
    );
    return RepaintBoundary(
      child: ClipRect(
        child: widget.blur <= 0
            ? image
            : ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: widget.blur.clamp(0.0, 3.0),
                  sigmaY: widget.blur.clamp(0.0, 3.0),
                ),
                child: Transform.scale(scale: 1.08, child: image),
              ),
      ),
    );
  }
}
