import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/model_providers.dart';

class QuoteGeneratorService {
  static final QuoteGeneratorService _instance = QuoteGeneratorService._internal();
  factory QuoteGeneratorService() => _instance;
  QuoteGeneratorService._internal();

  ModelProvider? _currentProvider;

  void setProvider(ModelProvider provider) {
    _currentProvider = provider;
  }

  ModelProvider? get currentProvider => _currentProvider;

  bool get isConfigured => _currentProvider != null &&
      _currentProvider!.apiKey.isNotEmpty &&
      _currentProvider!.baseUrl.isNotEmpty;

  /// 清理baseUrl，避免空格和末尾斜杠，保留版本路径（/v3 /v4 等）
  String _cleanBaseUrl(String baseUrl) {
    String cleaned = baseUrl.trim();
    cleaned = cleaned.replaceAll(RegExp(r'/[\s]+$'), '');
    return cleaned;
  }

  /// 使用 AI 生成名言
  Future<GeneratedQuote?> generateQuote({
    String? theme,
    String? author,
    String? category,
  }) async {
    if (!isConfigured) return null;

    try {
      String prompt;
      if (theme != null && theme.isNotEmpty) {
        prompt = '''请生成一条关于"$theme"的名言警句。

要求：
1. 文字简洁有力，富有哲理
2. 字数控制在20-50字之间
3. 适合作为座右铭或人生箴言

请以JSON格式返回，不要添加任何markdown标记：
{"content": "名言内容", "author": "作者或佚名", "source": "来源(可选)", "tags": "标签1,标签2"}''';
      } else {
        prompt = '''请随机生成一条有深度的名言警句。

要求：
1. 涵盖智慧、人生、哲学、投资等主题之一
2. 文字简洁有力，富有哲理
3. 字数控制在20-50字之间
4. 适合作为座右铭或人生箴言

请以JSON格式返回，不要添加任何markdown标记：
{"content": "名言内容", "author": "作者或佚名", "source": "来源(可选)", "tags": "标签1,标签2"}''';
      }

      // 尝试多个端点：优先 Zhipu 格式(/chat/completions)，再标准 OpenAI(/v1/chat/completions)，最后 MiniMax
      final endpoints = [
        '${_cleanBaseUrl(_currentProvider!.baseUrl)}/chat/completions',
        '${_cleanBaseUrl(_currentProvider!.baseUrl)}/v1/chat/completions',
        '${_cleanBaseUrl(_currentProvider!.baseUrl)}/text/chatcompletion_v2',
      ];

      final body = json.encode({
        'model': _currentProvider!.modelId,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 300,
        'temperature': 0.9,
      });

      http.Response? response;
      for (var uriStr in endpoints) {
        try {
          response = await http.post(
            Uri.parse(uriStr),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_currentProvider!.apiKey}',
            },
            body: body,
          ).timeout(const Duration(seconds: 30));
          if (response!.statusCode == 200) break;
        } catch (_) {}
      }

      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return _parseQuote(content);
        }
      }
    } catch (_) {}
    return null;
  }

  GeneratedQuote? _parseQuote(String content) {
    try {
      // 尝试解析 JSON
      String jsonStr = content.trim();

      // 移除可能的 markdown 代码块
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0];
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0];
      }

      jsonStr = jsonStr.trim();

      final Map<String, dynamic> map = json.decode(jsonStr);

      return GeneratedQuote(
        content: map['content'] ?? '',
        author: map['author'] ?? '佚名',
        source: map['source'] ?? '',
        tags: map['tags'] ?? '',
      );
    } catch (_) {
      // 如果 JSON 解析失败，尝试简单提取
      try {
        final lines = content.split('\n');
        for (var line in lines) {
          line = line.trim();
          if (line.length > 10 && line.length < 100) {
            return GeneratedQuote(
              content: line.replaceAll(RegExp(r'^[0-9\.、\)\s]+'), ''),
              author: 'AI生成',
              source: '',
              tags: 'AI生成,智慧',
            );
          }
        }
      } catch (_) {}
    }
    return null;
  }
}

class GeneratedQuote {
  final String content;
  final String author;
  final String source;
  final String tags;

  GeneratedQuote({
    required this.content,
    required this.author,
    this.source = '',
    this.tags = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'author': author,
      'source': source,
      'tags': tags,
    };
  }
}
