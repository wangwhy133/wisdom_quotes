import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../providers/providers.dart';
import '../providers/model_providers.dart' show currentLlmProviderProvider;
import '../services/llm_service.dart';

class InterpretScreen extends ConsumerStatefulWidget {
  const InterpretScreen({super.key});

  @override
  ConsumerState<InterpretScreen> createState() => _InterpretScreenState();
}

class _InterpretScreenState extends ConsumerState<InterpretScreen> {
  bool _isLoading = false;
  bool _isInterpreting = false;
  List<Quote> _quotes = [];
  String? _interpretation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final all = await db.getAllQuotes();
    all.shuffle();
    setState(() {
      _quotes = all.take(10).toList();
      _isLoading = false;
    });
  }

  Future<void> _interpret() async {
    if (_quotes.isEmpty) return;
    final provider = ref.read(currentLlmProviderProvider);
    if (provider == null) return;

    setState(() => _isInterpreting = true);
    // Refactor: provider always current via Riverpod, no manual setProvider needed
    LlmService().setProvider(provider);

    final quote = _quotes[_selectedIndex];
    final result = await LlmService().interpretQuote(
      content: quote.content,
      author: quote.author,
      source: quote.source,
    );

    setState(() {
      _interpretation = result;
      _isInterpreting = false;
    });
  }

  // Bug 27 fix: was calling translateQuotes (translation API) but UI showed 'AI解读'
  // Now calls interpretQuote for each quote and combines results
  // Refactor: uses currentLlmProviderProvider for automatic provider sync
  Future<void> _interpretAll() async {
    if (_quotes.isEmpty) return;
    final provider = ref.read(currentLlmProviderProvider);
    if (provider == null) return;

    setState(() => _isInterpreting = true);
    LlmService().setProvider(provider);

    final results = <String>[];
    for (var i = 0; i < _quotes.length; i++) {
      final quote = _quotes[i];
      final interpretation = await LlmService().interpretQuote(
        content: quote.content,
        author: quote.author,
        source: quote.source,
      );
      if (interpretation != null) {
        results.add('${i + 1}. "${quote.content}"\n💡 $interpretation');
      }
    }

    setState(() {
      _interpretation = results.isEmpty
          ? '解读失败，请检查AI配置'
          : results.join('\n\n');
      _isInterpreting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(currentLlmProviderProvider);
    if (provider == null || provider.apiKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('名言解读')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'AI模型未配置',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '请先在设置页面配置API Key',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('返回设置'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('名言解读'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: '换一组',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quote selector
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _quotes.length,
                    itemBuilder: (ctx, i) => _buildQuoteChip(i),
                  ),
                ),
                const Divider(),
                // Selected quote
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quote display
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.format_quote, size: 32, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                '"${_quotes[_selectedIndex].content}"',
                                style: const TextStyle(fontSize: 18, height: 1.6),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '— ${_quotes[_selectedIndex].author}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isInterpreting ? null : _interpret,
                                icon: _isInterpreting
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.auto_awesome),
                                label: const Text('解读此条'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isInterpreting ? null : _interpretAll,
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('解读全部'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Interpretation result
                        if (_interpretation != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.purple[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.psychology, color: Colors.purple[400]),
                                    const SizedBox(width: 8),
                                    Text('AI解读', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[700])),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _interpretation!,
                                  style: TextStyle(fontSize: 16, height: 1.8, color: Colors.purple[900]),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_isInterpreting && _interpretation == null) ...[
                          const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 16),
                          Center(child: Text('AI正在思考中...', style: TextStyle(color: Colors.grey[600]))),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuoteChip(int index) {
    final quote = _quotes[index];
    final isSelected = index == _selectedIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedIndex = index;
          _interpretation = null;
        }),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.white,
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(fontSize: 10, color: isSelected ? Colors.blue[800] : Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quote.content.length > 60 ? '${quote.content.substring(0, 60)}...' : quote.content,
                style: TextStyle(fontSize: 13, color: isSelected ? Colors.blue[900] : Colors.grey[800]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '— ${quote.author}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
