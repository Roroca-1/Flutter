import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/models.dart';
import '../../data/api/requests.dart';
import '../../data/providers.dart';

Future<void> showBookContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required BookListItem book,
  required Offset globalPosition,
  VoidCallback? onSelect,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final local = overlay.globalToLocal(globalPosition);
  final onShelf = ref.read(shelfProvider).value?.books.any((item) => item.id == book.id) == true;
  final action = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(local.dx, local.dy, 1, 1),
      Offset.zero & overlay.size,
    ),
    items: <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'read', child: ListTile(leading: Icon(Icons.play_arrow), title: Text('阅读'))),
      PopupMenuItem(
        value: 'series',
        enabled: book.seriesTitle?.trim().isNotEmpty == true,
        child: const ListTile(leading: Icon(Icons.library_books_outlined), title: Text('搜索系列')),
      ),
      PopupMenuItem(
        value: onShelf ? 'remove' : 'add',
        child: ListTile(
          leading: Icon(onShelf ? Icons.remove_circle_outline : Icons.bookmark_add_outlined),
          title: Text(onShelf ? '移出书架' : '添加到书架'),
        ),
      ),
      PopupMenuItem(
        value: 'select',
        enabled: onSelect != null,
        child: const ListTile(leading: Icon(Icons.checklist_outlined), title: Text('多选')),
      ),
    ],
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case 'read':
      context.push('/reader/${book.id}/1${book.type == BookType.comic ? '?type=Comic' : ''}');
    case 'series':
      context.push(Uri(path: '/books/series', queryParameters: <String, String>{'name': book.seriesTitle!.trim(), 'order': BookListOrder.latest.wire}).toString());
    case 'add':
      await ref.read(shelfProvider.notifier).addBooks(<int>[book.id]);
    case 'remove':
      await ref.read(shelfProvider.notifier).removeBooks(<int>[book.id]);
    case 'select':
      onSelect?.call();
  }
}
