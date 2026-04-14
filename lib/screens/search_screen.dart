import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/quote_card.dart';
import 'quote_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索名言、作者、出处...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '输入关键词搜索',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : searchResults.when(
              data: (quotes) {
                if (quotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '未找到相关名言',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
    );
  }
}
