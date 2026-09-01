import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/theme/app_theme.dart';
import '../../shared/cover_seed.dart';

class ImportedBackgroundImage {
  const ImportedBackgroundImage(this.path, this.seedColorValue);
  final String path;
  final String? seedColorValue;
}

class BackgroundImageRepository {
  const BackgroundImageRepository();

  Future<String?> extractSeed(String path) async {
    final seed = await resolveCoverSeedColor(
      FileImage(File(path)),
      size: const Size(128, 128),
    );
    return seed == null ? null : formatHexColor(seed);
  }

  Future<ImportedBackgroundImage?> pickAndImport(String slot) async {
    final XFile? picked;
    if (Platform.isAndroid) {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
        // A full-resolution camera photo wastes memory and decode time when it
        // is only ever used as a dimmed app background.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 68,
      );
    } else {
      picked = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[
          XTypeGroup(
            label: '图片',
            extensions: <String>['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
          ),
        ],
      );
    }
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) throw const FormatException('图片文件为空。');
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}background-images',
    );
    await directory.create(recursive: true);
    final extension = picked.name.split('.').last.toLowerCase();
    final target = File(
      '${directory.path}${Platform.pathSeparator}$slot.$extension',
    );
    await target.writeAsBytes(bytes, flush: true);
    return ImportedBackgroundImage(target.path, await extractSeed(target.path));
  }
}
