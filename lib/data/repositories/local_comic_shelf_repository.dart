import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../providers.dart';

const String _localComicShelfKey = 'lightnovel.local_comic_shelf.v1';

class LocalShelfComic {
  const LocalShelfComic({
    required this.id,
    required this.title,
    required this.seriesTitle,
    required this.coverUrl,
    required this.coverPlaceholder,
    required this.authorName,
    required this.lastUpdatedAt,
    required this.addedAt,
  });

  final int id;
  final String title;
  final String seriesTitle;
  final String coverUrl;
  final String? coverPlaceholder;
  final String? authorName;
  final DateTime lastUpdatedAt;
  final DateTime addedAt;

  BookListItem toBookListItem() => BookListItem(
    id: id,
    type: BookType.comic,
    title: title,
    seriesTitle: seriesTitle,
    coverUrl: coverUrl,
    coverPlaceholder: coverPlaceholder,
    authorName: authorName,
    lastUpdatedAt: lastUpdatedAt,
    level: null,
    interiorLevel: null,
    category: null,
  );

  Map<String, Object?> encode() => <String, Object?>{
    'id': id,
    'title': title,
    'seriesTitle': seriesTitle,
    'coverUrl': coverUrl,
    'coverPlaceholder': coverPlaceholder,
    'authorName': authorName,
    'lastUpdatedAt': lastUpdatedAt.toUtc().toIso8601String(),
    'addedAt': addedAt.toUtc().toIso8601String(),
  };

  static LocalShelfComic? decode(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final title = value['title'];
    final seriesTitle = value['seriesTitle'];
    final coverUrl = value['coverUrl'];
    final lastUpdatedAt = DateTime.tryParse('${value['lastUpdatedAt'] ?? ''}');
    final addedAt = DateTime.tryParse('${value['addedAt'] ?? ''}');
    if (id is! num ||
        title is! String ||
        seriesTitle is! String ||
        coverUrl is! String ||
        lastUpdatedAt == null ||
        addedAt == null) {
      return null;
    }
    return LocalShelfComic(
      id: id.toInt(),
      title: title,
      seriesTitle: seriesTitle,
      coverUrl: coverUrl,
      coverPlaceholder: value['coverPlaceholder'] as String?,
      authorName: value['authorName'] as String?,
      lastUpdatedAt: lastUpdatedAt,
      addedAt: addedAt,
    );
  }
}

class LocalComicShelfController extends AsyncNotifier<List<LocalShelfComic>> {
  @override
  Future<List<LocalShelfComic>> build() async {
    final raw = await ref.read(appRuntimeProvider).keyValueStore.read(
      _localComicShelfKey,
    );
    if (raw == null || raw.isEmpty) return const <LocalShelfComic>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <LocalShelfComic>[];
      return decoded
          .map(LocalShelfComic.decode)
          .whereType<LocalShelfComic>()
          .toList();
    } catch (_) {
      return const <LocalShelfComic>[];
    }
  }

  Future<bool> toggle(LocalShelfComic comic) async {
    final current = await future;
    final exists = current.any((item) => item.id == comic.id);
    final next = exists
        ? current.where((item) => item.id != comic.id).toList()
        : <LocalShelfComic>[comic, ...current];
    state = AsyncValue.data(next);
    await ref.read(appRuntimeProvider).keyValueStore.write(
      _localComicShelfKey,
      jsonEncode(next.map((item) => item.encode()).toList()),
    );
    return !exists;
  }
}

final localComicShelfProvider =
    AsyncNotifierProvider<LocalComicShelfController, List<LocalShelfComic>>(
      LocalComicShelfController.new,
    );

