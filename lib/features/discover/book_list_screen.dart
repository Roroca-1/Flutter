import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_client.dart';
import '../../data/api/models.dart';
import '../../shared/widgets/paged_grid.dart';
import '../../shared/widgets/book_context_menu.dart';
import '../../shared/widgets/book_list_row.dart';
import '../../shared/widgets/state_views.dart';
import 'catalog_providers.dart';
import 'widgets/book_grid.dart';
import 'widgets/novel_order_selector.dart';
import 'widgets/novel_series_tile.dart';

/// 全部小说的展示方式：平铺或按系列分组。
enum BookListViewMode { grid, list, series }

/// 全部小说：展示方式与排序切换，无限滚动。
class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key});

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  BookListOrder _order = BookListOrder.latest;
  BookListViewMode _mode = BookListViewMode.grid;

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
    if (_mode == BookListViewMode.list) {
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
        _ViewModeMenu(
          mode: _mode,
          onChanged: (mode) => setState(() => _mode = mode),
        ),
        const SizedBox(width: 4),
      ],
    ),
    body: _mode == BookListViewMode.series ? _seriesBody() : _flatBody(),
  );
}

/// 展示方式切换：标题栏图标按钮加下拉菜单。
class _ViewModeMenu extends StatelessWidget {
  const _ViewModeMenu({required this.mode, required this.onChanged});

  final BookListViewMode mode;
  final ValueChanged<BookListViewMode> onChanged;

  static const Map<BookListViewMode, (IconData, String)> _specs =
      <BookListViewMode, (IconData, String)>{
        BookListViewMode.grid: (Icons.grid_view_outlined, '网格'),
        BookListViewMode.list: (Icons.view_list_outlined, '列表'),
        BookListViewMode.series: (Icons.folder_copy_outlined, '系列'),
      };

  @override
  Widget build(BuildContext context) => PopupMenuButton<BookListViewMode>(
    tooltip: '展示方式',
    icon: Icon(_specs[mode]!.$1),
    position: PopupMenuPosition.under,
    onSelected: onChanged,
    itemBuilder: (_) => <PopupMenuEntry<BookListViewMode>>[
      for (final entry in _specs.entries)
        PopupMenuItem<BookListViewMode>(
          value: entry.key,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(entry.value.$1),
            title: Text(entry.value.$2),
            trailing: entry.key == mode ? const Icon(Icons.check) : null,
          ),
        ),
    ],
  );
}
