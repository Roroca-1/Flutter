import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ImportedReaderFont {
  const ImportedReaderFont(this.path, this.name, this.family);

  final String path;
  final String name;
  final String family;
}

/// Imports one user font into application storage and registers it at runtime.
/// Flutter performs glyph fallback to the platform fonts when a glyph is absent.
class UserFontRepository {
  UserFontRepository._();

  static final UserFontRepository instance = UserFontRepository._();
  final Map<String, String> _families = <String, String>{};

  static const List<String> supportedExtensions = <String>[
    'ttf', 'otf', 'ttc', 'otc', 'woff', 'woff2',
  ];

  Future<ImportedReaderFont?> pickAndImport() async {
    final picked = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: '字体', extensions: supportedExtensions),
      ],
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) throw const FormatException('字体文件为空。');
    final extension = picked.name.split('.').last.toLowerCase();
    if (!supportedExtensions.contains(extension)) {
      throw const FormatException('不支持此字体格式。');
    }
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}${Platform.pathSeparator}reader-fonts');
    await directory.create(recursive: true);
    final digest = sha256.convert(bytes).toString();
    final path = '${directory.path}${Platform.pathSeparator}$digest.$extension';
    final file = File(path);
    if (!await file.exists()) await file.writeAsBytes(bytes, flush: true);
    final family = await load(path);
    return ImportedReaderFont(path, picked.name, family);
  }

  Future<String> load(String path) async {
    final cached = _families[path];
    if (cached != null) return cached;
    final file = File(path);
    if (!await file.exists()) throw const FileSystemException('字体文件不存在');
    final bytes = await file.readAsBytes();
    final family = 'UserReaderFont-${sha256.convert(bytes).toString().substring(0, 16)}';
    await loadFontFromList(Uint8List.fromList(bytes), fontFamily: family);
    _families[path] = family;
    return family;
  }

  String? loadedFamily(String? path) => path == null ? null : _families[path];
}
