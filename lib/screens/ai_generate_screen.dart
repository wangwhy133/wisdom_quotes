import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/model_providers.dart' show currentLlmProviderProvider;
import '../providers/providers.dart';
import '../services/quote_generator_service.dart';
import '../services/llm_service.dart';

class AiGenerateScreen extends ConsumerStatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  ConsumerState<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends ConsumerState<AiGenerateScreen> {
  final _themeController = TextEditingController();
  bool _isGenerating = false;
  GeneratedQuote? _currentQuote;
  String? _error;

  static const List<String> _quickThemes = [
    '人生智慧',
    '投资哲学',
    '勇气与坚持',
    '时间管理',
    '学习成长',
    '友情与爱情',
    '自由与责任',
    '金钱与财富',
  ];

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _generateQuote({String? theme}) async {
    // Refactor: use currentLlmProviderProvider — provider always current, no manual selection
    final provider = ref.read(currentLlmProviderProvider);
    if (provider == null) {
      setState(() => _error = '请先添加AI模型配置');
      return;
    }

    LlmService().setProvider(provider);
    QuoteGeneratorService().setProvider(provider);

    setState(() {
      _isGenerating = true;
      _error = null;
      _currentQuote = null;
    });

    final quote = await QuoteGeneratorService().generateQuote(
      theme: theme ?? _themeController.text,
    );

    setState(() {
      _isGenerating = false;
      _currentQuote = quote;
      if (quote == null) {
        _error = '生成失败，请检查AI模型配置是否正确';
      }
    });
  }

  Future<void> _saveToLibrary() async {
    if (_currentQuote == null) return;

    try {
      final db = ref.read(databaseProvider);
      await db.insertQuote(_currentQuote!.toMap());
      ref.invalidate(allQuotesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到名言库')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refactor: single provider source for active LLM config
    final provider = ref.watch(currentLlmProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 名言生成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模型状态
            if (provider == null)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '请先添加AI模型配置',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('去添加'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        '当前模型: ${provider.name}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // 主题输入
            const Text(
              '输入生成主题（可选）',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _themeController,
              decoration: const InputDecoration(
                hintText: '例如：人生意义、投资哲学、勇气...',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),

            const SizedBox(height: 16),

            // 快速主题
            const Text(
              '快速选择',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickThemes.map((theme) => ActionChip(
                label: Text(theme),
                onPressed: () => _generateQuote(theme: theme),
              )).toList(),
            ),

            const SizedBox(height: 24),

            // 生成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : () => _generateQuote(),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? '生成中...' : '生成名言'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // 错误信息
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 生成结果
            if (_currentQuote != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                '生成结果',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '"${_currentQuote!.content}"',
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '—— ${_currentQuote!.author}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_currentQuote!.source.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '《${_currentQuote!.source}》',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isGenerating ? null : () => _generateQuote(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('再生成'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _saveToLibrary,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('保存'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // 使用说明
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '使用说明',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• 支持 OpenAI、MiniMax 等兼容 API\n'
                      '• 每次生成一条名言\n'
                      '• 生成后可保存到本地名言库\n'
                      '• 无主题时随机生成',
                      style: TextStyle(
                        color: Colors.blue[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
