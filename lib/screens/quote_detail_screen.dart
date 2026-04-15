import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../providers/providers.dart';
import '../providers/model_providers.dart';
import '../services/translation_service.dart';
import '../services/llm_service.dart';

class QuoteDetailScreen extends ConsumerStatefulWidget {
  final Quote quote;

  const QuoteDetailScreen({super.key, required this.quote});

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  bool _isTranslating = false;
  String? _translatedContent;
  String? _translatedAuthor;
  bool _isInterpreting = false;
  String? _interpretation;

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

  void _copyToClipboard() {
    final text = '"${widget.quote.content}"\n\n— ${widget.quote.author}${widget.quote.source != null && widget.quote.source!.isNotEmpty ? '《${widget.quote.source}》' : ''}';
    if (_translatedContent != null) {
      final translatedText = '"$_translatedContent"\n\n— $_translatedAuthor';
      Clipboard.setData(ClipboardData(text: '$text\n\n[翻译]\n$translatedText'));
    } else {
      Clipboard.setData(ClipboardData(text: text));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _translateQuote() async {
    if (_isTranslating) return;
    setState(() => _isTranslating = true);

    try {
      final translator = TranslationService();
      // Detect if Chinese or English
      final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(widget.quote.content);

      if (isChinese) {
        // Translate Chinese to English
        _translatedContent = await translator.zhToEn(widget.quote.content);
        _translatedAuthor = widget.quote.author; // Author usually stays same
      } else {
        // Translate English to Chinese
        _translatedContent = await translator.enToZh(widget.quote.content);
        _translatedAuthor = widget.quote.author;
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('翻译失败: $e')),
        );
      }
    }

    setState(() => _isTranslating = false);
  }

  Future<void> _interpretQuote() async {
    if (_isInterpreting) return;

    final providers = ref.read(modelProvidersProvider);
    if (providers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中添加AI模型配置')),
      );
      return;
    }

    final provider = providers.firstWhere(
      (p) => p.isDefault,
      orElse: () => providers.first,
    );

    setState(() => _isInterpreting = true);
    LlmService().setProvider(provider);

    try {
      _interpretation = await LlmService().interpretQuote(
        content: widget.quote.content,
        author: widget.quote.author,
        source: widget.quote.source,
      );
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解读失败: $e')),
        );
      }
    }

    setState(() => _isInterpreting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isFav = widget.quote.isFavorite;

    return Scaffold(
      appBar: AppBar(
        title: const Text('名言详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: _isTranslating ? null : _translateQuote,
            tooltip: '翻译',
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : null,
            ),
            onPressed: () {
              ref.read(databaseProvider).toggleFavorite(widget.quote.id, !isFav);
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _getCategoryColor(widget.quote.category).withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getCategoryName(widget.quote.category),
                style: TextStyle(
                  fontSize: 14,
                  color: _getCategoryColor(widget.quote.category),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Quote content
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.format_quote, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    widget.quote.content,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.8,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Translation result
            if (_translatedContent != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.translate, size: 20, color: Colors.blue[400]),
                        const SizedBox(width: 8),
                        Text(
                          '翻译',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"$_translatedContent"',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.8,
                        fontWeight: FontWeight.w400,
                        color: Colors.blue[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            if (_isTranslating) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '翻译中...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],

            // AI 解读按钮
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isInterpreting ? null : _interpretQuote,
                icon: _isInterpreting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isInterpreting ? '解读中...' : 'AI 解读'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // 解读结果
            if (_interpretation != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                        Text(
                          'AI 解读',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _interpretation!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Colors.purple[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            // Author info
            _buildInfoRow(Icons.person, '作者', widget.quote.author),
            if (widget.quote.source != null && widget.quote.source!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(Icons.book, '出处', '《${widget.quote.source}》'),
            ],
            if (widget.quote.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTagsRow(widget.quote.tags),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsRow(String tags) {
    final tagList = tags.split(',').where((t) => t.isNotEmpty).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.label, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagList
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag.trim(),
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
