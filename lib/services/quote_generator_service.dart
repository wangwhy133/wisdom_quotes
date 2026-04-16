import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/model_providers.dart';
import 'log_service.dart';

class QuoteGeneratorService {
  static final QuoteGeneratorService _instance = QuoteGeneratorService._internal();
  factory QuoteGeneratorService() => _instance;
  QuoteGeneratorService._internal();

  ModelProvider? _currentProvider;
  String? _lastError;

  String? get lastError => _lastError;

  void setProvider(ModelProvider provider) {
    _currentProvider = provider;
  }

  ModelProvider? get currentProvider => _currentProvider;

  bool get isConfigured => _currentProvider != null &&
      _currentProvider!.apiKey.isNotEmpty &&
      _currentProvider!.baseUrl.isNotEmpty;

  String _cleanBaseUrl(String baseUrl) {
    String cleaned = baseUrl.trim();
    // 移除末尾的 /v1, /v2, /v3 等版本标记
    cleaned = cleaned.replaceAll(RegExp(r'/v[0-9]+$'), '');
    // 移除末尾斜杠和空格
    cleaned = cleaned.replaceAll(RegExp(r'[/\\s]+$'), '');
    return cleaned;
  }

  Future<GeneratedQuote?> generateQuote({
    String? theme,
    String? author,
    String? category,
  }) async {
    _lastError = null;
    LogService().debug('generateQuote start, theme=$theme, configured=$isConfigured');
    if (!isConfigured) {
      _lastError = '未配置 AI provider';
      LogService().error('generateQuote: 未配置AI provider');
      return null;
    }

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

    final endpoints = [
      '${_cleanBaseUrl(_currentProvider!.baseUrl)}/chat/completions',
      '${_cleanBaseUrl(_currentProvider!.baseUrl)}/v1/chat/completions',
      '${_cleanBaseUrl(_currentProvider!.baseUrl)}/text/chatcompletion_v2',
    ];

    LogService().debug('generateQuote endpoints: $endpoints');
    LogService().debug('generateQuote model: ${_currentProvider!.modelId}');

    final body = json.encode({
      'model': _currentProvider!.modelId,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': 300,
      'temperature': 0.9,
    });

    for (var uriStr in endpoints) {
      LogService().debug('generateQuote trying: $uriStr');
      try {
        final response = await http.post(
          Uri.parse(uriStr),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_currentProvider!.apiKey}',
          },
          body: body,
        ).timeout(const Duration(seconds: 30));

        LogService().debug('generateQuote response ${response.statusCode} for $uriStr');
        LogService().debug('generateQuote body: ${response.body.length} bytes');

        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            LogService().debug('generateQuote parsed data keys: ${data.keys.toList()}');

            final choices = data['choices'] as List?;
            final content = choices?.isNotEmpty == true
                ? (choices![0]['message']?['content'] as String?)
                : null;

            if (content != null && content.isNotEmpty) {
              LogService().debug('generateQuote content found, length=${content.length}');
              final quote = _parseQuote(content);
              if (quote != null) {
                LogService().info('generateQuote success: ${quote.content.substring(0, quote.content.length < 20 ? quote.content.length : 20)}...');
                return quote;
              } else {
                LogService().warning('generateQuote _parseQuote returned null');
                _lastError = '[_parseQuote failed]';
              }
            } else {
              LogService().warning('generateQuote content为空 for $uriStr, body=${response.body.substring(0, response.body.length < 200 ? response.body.length : 200)}');
              _lastError = '[$uriStr] content为空';
            }
          } catch (e, st) {
            LogService().error('generateQuote parse error for $uriStr', e, st);
            _lastError = '[$uriStr] parse error: $e';
          }
        } else {
          LogService().warning('generateQuote HTTP ${response.statusCode} for $uriStr: ${response.body}');
          _lastError = '[$uriStr] HTTP ${response.statusCode}: ${response.body}';
        }
      } catch (e, st) {
        LogService().error('generateQuote request error for $uriStr', e, st);
        _lastError = '[$uriStr] $e';
      }
    }

    LogService().warning('generateQuote all endpoints failed, lastError=$_lastError');
    return null;
  }

  GeneratedQuote? _parseQuote(String content) {
    try {
      String jsonStr = content.trim();

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
