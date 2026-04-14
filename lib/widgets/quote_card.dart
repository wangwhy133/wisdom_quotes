import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../providers/providers.dart';

class QuoteCard extends ConsumerWidget {
  final Quote quote;
  final VoidCallback? onTap;

  const QuoteCard({super.key, required this.quote, this.onTap});

  String _getCategoryName(QuoteCategory category) {
    switch (category) {
      case QuoteCategory.classicLiterature:
        return '经典名著';
      case QuoteCategory.poetry:
        return '诗词';
      case QuoteCategory.investment:
        return '投资名言';
    }
  }

  Color _getCategoryColor(QuoteCategory category) {
    switch (category) {
      case QuoteCategory.classicLiterature:
        return const Color(0xFF8B4513);
      case QuoteCategory.poetry:
        return const Color(0xFF2E8B57);
      case QuoteCategory.investment:
        return const Color(0xFF4169E1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(quote.category).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCategoryName(quote.category),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCategoryColor(quote.category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      quote.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: quote.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () {
                      ref
                          .read(databaseProvider)
                          .toggleFavorite(quote.id, !quote.isFavorite);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '"${quote.content}"',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '— ${quote.author}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (quote.source != null && quote.source!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '《${quote.source}》',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
