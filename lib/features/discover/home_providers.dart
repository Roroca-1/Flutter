import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_client.dart';
import '../../data/api/models.dart';
import '../../data/providers.dart';
import '../../data/settings/app_settings.dart';
import '../../shared/content_filter.dart';

const Map<HomeRankType, int> rankPeriodDays = <HomeRankType, int>{
  HomeRankType.daily: 1,
  HomeRankType.weekly: 7,
  HomeRankType.monthly: 31,
};

const Map<HomeRankType, String> rankPeriodLabels = <HomeRankType, String>{
  HomeRankType.daily: '日榜',
  HomeRankType.weekly: '周榜',
  HomeRankType.monthly: '月榜',
};

/// 拉取条数大于展示条数，用于抵消本地过滤的缺口。
const int _homeLatestFetchSize = 12;

const int _homePreviewCount = 6;

/// 只订阅影响列表结果的设置项，避免字号等变化触发重新拉取。
AppSettings watchContentSettings(Ref ref) {
  ref.watch(
    appSettingsProvider.select(
      (settings) => (settings.ignoreAI, settings.ignoreJapanese),
    ),
  );
  return ref.read(appSettingsProvider);
}

final FutureProvider<List<BookListItem>> homeRankingProvider =
    FutureProvider<List<BookListItem>>((ref) async {
      final api = ref.watch(apiClientProvider);
      final period = ref.watch(
        appSettingsProvider.select((settings) => settings.homeRankType),
      );
      final settings = watchContentSettings(ref);
      final cache = ref.read(bookMetadataCacheProvider);
      final cacheName = 'ranking-${period.name}';
      final cached = await cache.readList(cacheName, const Duration(minutes: 15));
      if (cached != null) return applyContentFilter(cached, settings);
      final items = await api.getRank(rankPeriodDays[period]!);
      await cache.writeList(cacheName, items);
      return applyContentFilter(items, settings);
    }, isAutoDispose: true);

final FutureProvider<List<BookListItem>> homeLatestBooksProvider =
    FutureProvider<List<BookListItem>>((ref) async {
      final api = ref.watch(apiClientProvider);
      final settings = watchContentSettings(ref);
      final cache = ref.read(bookMetadataCacheProvider);
      final cached = await cache.readList('latest', const Duration(minutes: 15));
      if (cached != null) return applyContentFilter(cached, settings).take(_homePreviewCount).toList();
      final page = await api.getBookList(
        page: 1,
        size: _homeLatestFetchSize,
        order: BookListOrder.latest,
        ignoreJapanese: settings.ignoreJapanese,
        ignoreAI: settings.ignoreAI,
      );
      final filtered = applyContentFilter(page.items, settings);
      await cache.writeList('latest', page.items);
      return filtered.take(_homePreviewCount).toList();
    }, isAutoDispose: true);

final FutureProvider<List<BookListItem>> homeComicsProvider =
    FutureProvider<List<BookListItem>>((ref) async {
      final api = ref.watch(apiClientProvider);
      final cache = ref.read(bookMetadataCacheProvider);
      final cached = await cache.readList('comics', const Duration(minutes: 15));
      if (cached != null) return cached;
      final page = await api.getComicList(
        page: 1,
        order: ComicOrder.latest,
        size: _homePreviewCount,
      );
      // 后端没有漫画的分类信息，不做内容过滤。
      final books = page.items.map((item) => item.toBookListItem()).toList();
      await cache.writeList('comics', books);
      return books;
    }, isAutoDispose: true);

final FutureProvider<OnlineInfo> onlineInfoProvider =
    FutureProvider<OnlineInfo>((ref) async {
      final api = ref.watch(apiClientProvider);
      return api.getOnlineInfo();
    }, isAutoDispose: true);

final FutureProvider<List<AnnouncementItem>> homeAnnouncementsProvider =
    FutureProvider<List<AnnouncementItem>>((ref) async {
      final api = ref.watch(apiClientProvider);
      final page = await api.getAnnouncementList(page: 1, size: 5);
      return page.items;
    }, isAutoDispose: true);
