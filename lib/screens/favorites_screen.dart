import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/quote_card.dart';
import 'quote_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
      ),
      body: favoritesAsync.when(
        data: (quotes) {
          if (quotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无收藏',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击名言卡片中的心形图标收藏',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final quote = quotes[index];
              return QuoteCard(
                quote: quote,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuoteDetailScreen(quote: quote),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
