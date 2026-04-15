import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart' show Quote, QuoteCategory;
import '../providers/providers.dart';
import '../widgets/quote_card.dart';
import 'quote_detail_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'batch_translate_screen.dart';
import 'ai_generate_screen.dart';
import 'interpret_screen.dart';

// Refactor: ConsumerWidget eliminates initState async race condition.
// dailyQuoteProvider (FutureProvider) handles async loading — no manual setState needed.
// Previous bug: _loadDailyQuote() called ref.read(databaseProvider) AFTER await in initState.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final quotesAsync = ref.watch(filteredQuotesProvider);
    final dailyQuoteAsync = ref.watch(dailyQuoteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '智慧名言',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(filteredQuotesProvider);
          ref.invalidate(dailyQuoteProvider); // Refresh daily quote
        },
        child: CustomScrollView(
          slivers: [
            // Daily quote card — uses dailyQuoteProvider for proper async handling
            dailyQuoteAsync.when(
              data: (quote) => quote != null
                  ? SliverToBoxAdapter(child: _DailyQuoteCard(quote: quote))
                  : const SliverToBoxAdapter(child: SizedBox.shrink()),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Category filter
            SliverToBoxAdapter(
              child: Container(
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _CategoryChip(
                      label: '全部',
                      isSelected: selectedCategory == null,
                      onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                    ),
                    _CategoryChip(
                      label: '💰 投资名言',
                      isSelected: selectedCategory == QuoteCategory.investment,
                      onTap: () => ref.read(selectedCategoryProvider.notifier).state = QuoteCategory.investment,
                    ),
                    _CategoryChip(
                      label: '📚 经典名著',
                      isSelected: selectedCategory == QuoteCategory.classicLiterature,
                      onTap: () => ref.read(selectedCategoryProvider.notifier).state = QuoteCategory.classicLiterature,
                    ),
                    _CategoryChip(
                      label: '📜 诗词',
                      isSelected: selectedCategory == QuoteCategory.poetry,
                      onTap: () => ref.read(selectedCategoryProvider.notifier).state = QuoteCategory.poetry,
                    ),
                  ],
                ),
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.auto_awesome,
                        label: 'AI生成',
                        color: Colors.purple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiGenerateScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.translate,
                        label: '批量翻译',
                        color: Colors.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BatchTranslateScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.psychology,
                        label: '名言解读',
                        color: Colors.indigo,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InterpretScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.format_list_bulleted, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      selectedCategory == null ? '全部名言'
                          : selectedCategory == QuoteCategory.investment ? '💰 投资名言'
                          : selectedCategory == QuoteCategory.classicLiterature ? '📚 经典名著'
                          : '📜 诗词',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            // Quotes list
            quotesAsync.when(
              data: (quotes) => quotes.isEmpty
                  ? SliverFillRemaining(child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('暂无名言', style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                            child: const Text('去导入'),
                          ),
                        ],
                      ),
                    ))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: QuoteCard(
                            quote: quotes[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuoteDetailScreen(quote: quotes[index]),
                              ),
                            ),
                          ),
                        ),
                        childCount: quotes.length,
                      ),
                    ),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('加载失败: $e'))),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _DailyQuoteCard extends StatelessWidget {
  final Quote quote;
  const _DailyQuoteCard({required this.quote});

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuoteDetailScreen(quote: quote)),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getCategoryColor(quote.category).withAlpha(230),
              _getCategoryColor(quote.category).withAlpha(180),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getCategoryColor(quote.category).withAlpha(77),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '每日名言',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCategoryName(quote.category),
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '"${quote.content}"',
              style: const TextStyle(
                fontSize: 20,
                height: 1.6,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '— ${quote.author}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(230),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.brown[100],
        checkmarkColor: Colors.brown[700],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
