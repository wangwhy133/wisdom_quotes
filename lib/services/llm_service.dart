import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/model_providers.dart';

class LlmService {
  static final LlmService _instance = LlmService._internal();
  factory LlmService() => _instance;
  LlmService._internal();

  ModelProvider? _currentProvider;

  void setProvider(ModelProvider provider) {
    _currentProvider = provider;
  }

  ModelProvider? get currentProvider => _currentProvider;

  bool get isConfigured => _currentProvider != null &&
      _currentProvider!.apiKey.isNotEmpty &&
      _currentProvider!.baseUrl.isNotEmpty;

  Future<String?> interpretQuote({
    required String content,
    required String author,
    String? source,
  }) async {
    if (!isConfigured) return null;

    try {
      final uri = Uri.parse('${_currentProvider!.baseUrl}/text/chatcompletion_v2');

      final body = json.encode({
        'model': _currentProvider!.modelId,
        'messages': [
          {
            'role': 'user',
            'content': '''请解读以下名言的深层含义，并给出简短点评（100字以内）：

原文：$content
作者：$author${source != null && source.isNotEmpty ? '《$source》' : ''}

请用简洁有洞察力的语言解读。'''
          }
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentProvider!.apiKey}',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices']?[0]?['message']?['content'];
      }
    } catch (_) {}
    return null;
  }

  Future<String?> translateQuotes({
    required List<Map<String, String>> quotes,
    required String targetLang,
  }) async {
    if (!isConfigured) return null;

    try {
      final uri = Uri.parse('${_currentProvider!.baseUrl}/text/chatcompletion_v2');

      final quotesText = quotes.map((q) =>
        '- "${q['content']}" - ${q['author']}'
      ).join('\n');

      final body = json.encode({
        'model': _currentProvider!.modelId,
        'messages': [
          {
            'role': 'user',
            'content': '''请将以下名言翻译成${targetLang == 'zh' ? '中文' : '英文'}，保持原有格式，逐一翻译：

$quotesText'''
          }
        ],
        'max_tokens': 1500,
        'temperature': 0.5,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentProvider!.apiKey}',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices']?[0]?['message']?['content'];
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>?> fetchModels() async {
    if (!isConfigured) return null;

    try {
      final uri = Uri.parse('${_currentProvider!.baseUrl}/models');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${_currentProvider!.apiKey}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List).map((m) => m['id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        }
      }
    } catch (_) {}
    return null;
  }
}
