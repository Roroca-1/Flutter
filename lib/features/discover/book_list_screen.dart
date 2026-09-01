import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_client.dart';
import '../../data/api/models.dart';
import '../../shared/widgets/paged_grid.dart';
import '../../shared/widgets/book_context_menu.dart';
import '../../shared/widgets/book_list_row.dart';
import '../../shared/widgets/state_views.dart';
import '../../shared/widgets/book_image.dart';
import '../../shared/format.dart';
import 'catalog_providers.dart';
import 'widgets/book_grid.dart';
import 'widgets/novel_order_selector.dart';
import 'widgets/novel_series_tile.dart';

enum BookListDisplayMode { grid, list }

/// 全部小说：展示方式与排序切换，无限滚动。
class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key});

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  BookListOrder _order = BookListOrder.latest;
  BookListDisplayMode _displayMode = BookListDisplayMode.grid;
  bool _seriesView = false;

  void _openSeries(NovelSeriesListItem series) {
    // 系列名可能带 `/`，走查询参数而不是路径段。
    context.push(
      Uri(
        path: '/books/series',
        queryParameters: <String, String>{
          'name': series.name,
          'order': _order.wire,
        },
      ).toString(),
    );
  }

  Widget _header() => NovelOrderSelector(
    order: _order,
    onChanged: (order) => setState(() => _order = order),
  );

  Widget _flatBody() {
    final state = ref.watch(bookCatalogProvider(_order));
    final controller = ref.read(bookCatalogProvider(_order).notifier);
    if (_displayMode == BookListDisplayMode.list) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 600 &&
                state.hasMore &&
                !state.loading &&
                !state.loadingMore &&
                state.loadMoreError == null) {
              controller.loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                sliver: SliverToBoxAdapter(child: _header()),
              ),
              if (state.items.isEmpty && state.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.items.isEmpty && state.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateView(
                    message: state.error!,
                    onRetry: controller.retry,
                  ),
                )
              else if (state.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.menu_book_outlined,
                    title: '暂无小说',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverList.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final book = state.items[index];
                      return BookListRow(
                        book: book,
                        onTap: () => openBookDetail(context, book),
                        onSecondaryTap: (position) => showBookContextMenu(
                          context: context,
                          ref: ref,
                          book: book,
                          globalPosition: position,
                        ),
                      );
                    },
                  ),
                ),
              if (state.items.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 64,
                    child: ListFooterStatus(
                      loading: state.loadingMore,
                      hasMore: state.hasMore,
                      error: state.loadMoreError,
                      onRetry: controller.loadMore,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return PagedGrid.books(
      header: _header(),
      books: state.items,
      loading: state.loading,
      loadingMore: state.loadingMore,
      // 加载更多失败后停止自动预取，改由底部按钮手动重试。
      hasMore: state.hasMore && state.loadMoreError == null,
      loadMoreError: state.loadMoreError,
      errorMessage: state.error,
      onRetry: controller.retry,
      onRefresh: controller.refresh,
      onLoadMore: controller.loadMore,
      onOpen: (book) => openBookDetail(context, book),
      onSecondaryTap: (book, position) => showBookContextMenu(
        context: context,
        ref: ref,
        book: book,
        globalPosition: position,
      ),
      emptyIcon: Icons.menu_book_outlined,
      emptyTitle: '暂无小说',
      emptyDescription: '当前排序下暂无可显示的小说。',
    );
  }

  Widget _seriesBody() {
    final state = ref.watch(novelSeriesCatalogProvider(_order));
    final controller = ref.read(novelSeriesCatalogProvider(_order).notifier);
    if (_displayMode == BookListDisplayMode.list) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 600 &&
                state.hasMore &&
                !state.loading &&
                !state.loadingMore &&
                state.loadMoreError == null) {
              controller.loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                sliver: SliverToBoxAdapter(child: _header()),
              ),
              if (state.items.isEmpty && state.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.items.isEmpty && state.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorStateView(
                    message: state.error!,
                    onRetry: controller.retry,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverList.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final series = state.items[index];
                      return _NovelSeriesListRow(
                        series: series,
                        onTap: () => _openSeries(series),
                      );
                    },
                  ),
                ),
              if (state.items.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 64,
                    child: ListFooterStatus(
                      loading: state.loadingMore,
                      hasMore: state.hasMore,
                      error: state.loadMoreError,
                      onRetry: controller.loadMore,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return PagedGrid<NovelSeriesListItem>(
      header: _header(),
      items: state.items,
      loading: state.loading,
      loadingMore: state.loadingMore,
      hasMore: state.hasMore && state.loadMoreError == null,
      loadMoreError: state.loadMoreError,
      errorMessage: state.error,
      onRetry: controller.retry,
      onRefresh: controller.refresh,
      onLoadMore: controller.loadMore,
      itemBuilder: (series, _, coverHeight) => NovelSeriesTile(
        key: ValueKey<String>(series.name),
        series: series,
        coverHeight: coverHeight,
        onTap: () => _openSeries(series),
      ),
      emptyIcon: Icons.folder_open_outlined,
      emptyTitle: '暂无系列',
      emptyDescription: '当前排序下暂无可显示的系列。',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('全部小说'),
      actions: <Widget>[
        IconButton(
          tooltip: _seriesView ? '按单本显示' : '按系列显示',
          onPressed: () => setState(() => _seriesView = !_seriesView),
          icon: Icon(
            _seriesView ? Icons.folder_outlined : Icons.description_outlined,
          ),
        ),
        IconButton(
          tooltip: _displayMode == BookListDisplayMode.grid
              ? '切换到列表视图'
              : '切换到网格视图',
          onPressed: () => setState(
            () => _displayMode = _displayMode == BookListDisplayMode.grid
                ? BookListDisplayMode.list
                : BookListDisplayMode.grid,
          ),
          icon: Icon(
            _displayMode == BookListDisplayMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
          ),
        ),
        const SizedBox(width: 4),
      ],
    ),
    body: _seriesView ? _seriesBody() : _flatBody(),
  );
}

class _NovelSeriesListRow extends StatelessWidget {
  const _NovelSeriesListRow({required this.series, required this.onTap});
  final NovelSeriesListItem series;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 78,
                child: series.coverUrl.isEmpty
                    ? const ColoredBox(
                        color: Colors.black12,
                        child: Icon(Icons.folder_open_outlined),
                      )
                    : BookImage(
                        url: series.coverUrl,
                        displayHeight: 78,
                        blurHash: series.coverPlaceholder,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    series.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${series.bookCount} 本 · 更新于 ${formatShortDate(series.lastUpdatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
