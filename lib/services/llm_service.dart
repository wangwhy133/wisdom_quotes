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

  /// 测试模型连接是否正常
  Future<TestResult> testConnection(ModelProvider provider) async {
    if (provider.apiKey.isEmpty || provider.baseUrl.isEmpty) {
      return TestResult(success: false, message: '请填写 API Key 和 Base URL');
    }

    try {
      // 尝试发送一个简单的测试请求
      final uri = Uri.parse('${provider.baseUrl}/v1/chat/completions');
      
      final body = json.encode({
        'model': provider.modelId.isNotEmpty ? provider.modelId : 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': 'Hi, reply with "OK" only.'}
        ],
        'max_tokens': 10,
        'temperature': 0,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${provider.apiKey}',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        return TestResult(success: true, message: '连接成功！响应: $content');
      } else {
        final error = json.decode(response.body);
        return TestResult(
          success: false,
          message: '请求失败 (${response.statusCode}): ${error['error']?['message'] ?? response.body}',
        );
      }
    } catch (e) {
      return TestResult(success: false, message: '连接失败: $e');
    }
  }

  Future<String?> interpretQuote({
    required String content,
    required String author,
    String? source,
  }) async {
    if (!isConfigured) return null;

    try {
      // 尝试 OpenAI 兼容接口
      var uri = Uri.parse('${_currentProvider!.baseUrl}/v1/chat/completions');
      
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

      var response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentProvider!.apiKey}',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      // 如果 v1 接口失败，尝试 MiniMax 专用接口
      if (response.statusCode != 200) {
        uri = Uri.parse('${_currentProvider!.baseUrl}/text/chatcompletion_v2');
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_currentProvider!.apiKey}',
          },
          body: body,
        ).timeout(const Duration(seconds: 30));
      }

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
      var uri = Uri.parse('${_currentProvider!.baseUrl}/v1/chat/completions');

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

      var response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentProvider!.apiKey}',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      // 如果 v1 接口失败，尝试 MiniMax 专用接口
      if (response.statusCode != 200) {
        uri = Uri.parse('${_currentProvider!.baseUrl}/text/chatcompletion_v2');
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_currentProvider!.apiKey}',
          },
          body: body,
        ).timeout(const Duration(seconds: 30));
      }

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
      // 尝试 OpenAI 兼容接口
      var uri = Uri.parse('${_currentProvider!.baseUrl}/v1/models');
      
      var response = await http.get(
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

      // 如果 v1/models 失败，尝试 MiniMax 专用接口
      uri = Uri.parse('${_currentProvider!.baseUrl}/models');
      response = await http.get(
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

class TestResult {
  final bool success;
  final String message;
  TestResult({required this.success, required this.message});
}
