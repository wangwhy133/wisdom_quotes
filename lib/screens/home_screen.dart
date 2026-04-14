import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../providers/providers.dart';
import '../widgets/quote_card.dart';
import 'quote_detail_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'batch_translate_screen.dart';
import 'interpret_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Quote? _dailyQuote;

  @override
  void initState() {
    super.initState();
    _loadDailyQuote();
  }

  Future<void> _loadDailyQuote() async {
    final db = ref.read(databaseProvider);
    final quote = await db.getRandomQuote();
    setState(() => _dailyQuote = quote);
  }

  Future<void> _refreshDailyQuote() async {
    final db = ref.read(databaseProvider);
    final quote = await db.getRandomQuote();
    setState(() => _dailyQuote = quote);
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
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final quotesAsync = ref.watch(filteredQuotesProvider);

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
          await _refreshDailyQuote();
        },
        child: CustomScrollView(
          slivers: [
            // Daily quote card
            if (_dailyQuote != null)
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuoteDetailScreen(quote: _dailyQuote!),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryColor(_dailyQuote!.category).withAlpha(230),
                          _getCategoryColor(_dailyQuote!.category).withAlpha(180),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(_dailyQuote!.category).withAlpha(77),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '每日名言',
                                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
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
                                _getCategoryName(_dailyQuote!.category),
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '"${_dailyQuote!.content}"',
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
                                '— ${_dailyQuote!.author}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(230),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                              onPressed: _refreshDailyQuote,
                              tooltip: '换一条',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Category filter
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildCategoryChip(ref, null, '全部', selectedCategory),
                    _buildCategoryChip(ref, QuoteCategory.classicLiterature, '经典名著', selectedCategory),
                    _buildCategoryChip(ref, QuoteCategory.poetry, '诗词', selectedCategory),
                    _buildCategoryChip(ref, QuoteCategory.investment, '投资名言', selectedCategory),
                  ],
                ),
              ),
            ),
            // Quote list
            quotesAsync.when(
              data: (quotes) {
                if (quotes.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('暂无名言')),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final quote = quotes[index];
                      return QuoteCard(
                        quote: quote,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => QuoteDetailScreen(quote: quote)),
                        ),
                      );
                    },
                    childCount: quotes.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BatchTranslateScreen()),
                ),
                icon: const Icon(Icons.translate, size: 20),
                label: const Text('批量翻译'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InterpretScreen()),
                ),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('AI解读'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    WidgetRef ref,
    QuoteCategory? category,
    String label,
    QuoteCategory? selected,
  ) {
    final isSelected = category == selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(selectedCategoryProvider.notifier).state = category;
        },
        selectedColor: Colors.blue.withAlpha(51),
        checkmarkColor: Colors.blue,
      ),
    );
  }
}
