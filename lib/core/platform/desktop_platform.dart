import 'package:flutter/foundation.dart';

bool get isDesktopPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.linux || TargetPlatform.windows => true,
  _ => false,
};
