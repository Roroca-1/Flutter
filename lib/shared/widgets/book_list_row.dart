import 'package:flutter/material.dart';

import '../../data/api/models.dart';
import '../format.dart';
import 'book_image.dart';

/// Compact vertical book entry used by list-mode catalog screens.
class BookListRow extends StatelessWidget {
  const BookListRow({
    super.key,
    required this.book,
    required this.onTap,
    this.subtitle,
    this.onLongPress,
    this.selected = false,
  });

  final BookListItem book;
  final VoidCallback onTap;
  final String? subtitle;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final author = book.authorName?.trim();
    final secondary = subtitle ??
        <String>[
          if (author?.isNotEmpty == true) author!,
          '更新于 ${formatShortDate(book.lastUpdatedAt)}',
        ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 78,
                  child: BookImage(
                    url: book.coverUrl,
                    displayHeight: 78,
                    blurHash: book.coverPlaceholder,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
