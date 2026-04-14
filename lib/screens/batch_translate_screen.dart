import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../providers/providers.dart';
import '../services/translation_service.dart';


class BatchTranslateScreen extends ConsumerStatefulWidget {
  const BatchTranslateScreen({super.key});

  @override
  ConsumerState<BatchTranslateScreen> createState() => _BatchTranslateScreenState();
}

class _BatchTranslateScreenState extends ConsumerState<BatchTranslateScreen> {
  bool _isLoading = false;
  bool _isTranslating = false;
  String _selectedLang = 'zh';
  String _selectedFont = 'Default';
  List<_QuoteWithTranslation> _quotes = [];

  static const List<String> _availableFonts = [
    'Default',
    'Serif',
    'Monospace',
    'Cursive',
    'Fantasy',
  ];

  static const Map<String, String> _langNames = {
    'zh': '中文',
    'en': '英文',
  };

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
      _quotes = all.take(5).map((q) => _QuoteWithTranslation(quote: q)).toList();
      _isLoading = false;
    });
  }

  Future<void> _translateAll() async {
    setState(() => _isTranslating = true);

    final translator = TranslationService();
    final targetLang = _selectedLang == 'zh' ? 'zh-CN' : 'en';

    for (var i = 0; i < _quotes.length; i++) {
      final quote = _quotes[i].quote;
      final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(quote.content);
      String? translated;

      if (isChinese) {
        translated = await translator.zhToEn(quote.content);
      } else {
        translated = await translator.enToZh(quote.content);
      }

      setState(() {
        _quotes[i] = _quotes[i].copyWith(translation: translated);
      });
    }

    setState(() => _isTranslating = false);
  }

  void _refreshQuotes() {
    _loadQuotes();
  }

  TextStyle _getFontStyle(String font, {double fontSize = 18}) {
    switch (font) {
      case 'Serif': return TextStyle(fontFamily: 'serif', fontSize: fontSize, height: 1.6);
      case 'Monospace': return TextStyle(fontFamily: 'monospace', fontSize: fontSize, height: 1.6);
      case 'Cursive': return TextStyle(fontFamily: 'cursive', fontSize: fontSize, height: 1.6);
      case 'Fantasy': return TextStyle(fontFamily: 'fantasy', fontSize: fontSize, height: 1.6);
      default: return TextStyle(fontSize: fontSize, height: 1.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量翻译'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQuotes,
            tooltip: '换一组',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                // Language selector
                Expanded(
                  child: SegmentedButton<String>(
                    segments: _langNames.entries
                        .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                        .toList(),
                    selected: {_selectedLang},
                    onSelectionChanged: (s) => setState(() => _selectedLang = s.first),
                  ),
                ),
                const SizedBox(width: 12),
                // Font selector
                PopupMenuButton<String>(
                  initialValue: _selectedFont,
                  onSelected: (f) => setState(() => _selectedFont = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.font_download, size: 18),
                        const SizedBox(width: 6),
                        Text(_selectedFont),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => _availableFonts
                      .map((f) => PopupMenuItem(value: f, child: Text(f)))
                      .toList(),
                ),
              ],
            ),
          ),
          // Translate button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTranslating ? null : _translateAll,
                icon: _isTranslating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.translate),
                label: Text(_isTranslating ? '翻译中...' : '一键翻译5条名言'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          // Quote list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _quotes.length,
                    itemBuilder: (ctx, i) => _buildQuoteCard(_quotes[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(_QuoteWithTranslation item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${index + 1}',
                style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            // Original
            Text(
              '"${item.quote.content}"',
              style: _getFontStyle(_selectedFont),
            ),
            const SizedBox(height: 8),
            Text(
              '— ${item.quote.author}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            // Translation
            if (item.translation != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.translate, size: 16, color: Colors.blue[400]),
                        const SizedBox(width: 4),
                        Text('翻译', style: TextStyle(fontSize: 12, color: Colors.blue[400], fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${item.translation}"',
                      style: _getFontStyle(_selectedFont),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                '点击"一键翻译"获取翻译',
                style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuoteWithTranslation {
  final Quote quote;
  final String? translation;

  _QuoteWithTranslation({required this.quote, this.translation});

  _QuoteWithTranslation copyWith({Quote? quote, String? translation}) {
    return _QuoteWithTranslation(
      quote: quote ?? this.quote,
      translation: translation ?? this.translation,
    );
  }
}
