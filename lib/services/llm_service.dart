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

  /// 清理baseUrl，避免双重路径
  String _cleanBaseUrl(String baseUrl) {
    // 先trim掉首尾空格，再处理路径
    String cleaned = baseUrl.trim();
    // 移除末尾的 /v1, /v2, /v3 等版本标记
    cleaned = cleaned.replaceAll(RegExp(r'/v[0-9]+$'), '');
    // 移除末尾斜杠和空格
    cleaned = cleaned.replaceAll(RegExp(r'[/\\s]+$'), '');
    return cleaned;
  }

  String _url(String path) {
    return '${_cleanBaseUrl(_currentProvider!.baseUrl)}$path';
  }

  String _urlForProvider(String baseUrl, String path) {
    return '${_cleanBaseUrl(baseUrl)}$path';
  }

  /// 测试模型连接是否正常
  Future<TestResult> testConnection(ModelProvider provider) async {
    if (provider.apiKey.isEmpty || provider.baseUrl.isEmpty) {
      return TestResult(success: false, message: '请填写 API Key 和 Base URL');
    }

    try {
      // 构建测试URL
      final url = _urlForProvider(provider.baseUrl, '/v1/chat/completions');
      
      final body = json.encode({
        'model': provider.modelId.isNotEmpty ? provider.modelId : 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': 'Hi, reply with "OK" only.'}
        ],
        'max_tokens': 10,
        'temperature': 0,
      });

      final response = await http.post(
        Uri.parse(url),
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

      // 尝试 OpenAI 兼容接口
      var response = await http.post(
        Uri.parse(_url('/v1/chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentProvider!.apiKey}',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      // 如果失败，尝试 MiniMax 专用接口
      if (response.statusCode != 200) {
        response = await http.post(
          Uri.parse('${_currentProvider!.baseUrl}/text/chatcompletion_v2'),
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

      // 尝试 OpenAI 兼容接口
      var response = await http.post(
        Uri.parse(_url('/v1/chat/completions')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentProvider!.apiKey}',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      // 如果失败，尝试 MiniMax 专用接口
      if (response.statusCode != 200) {
        response = await http.post(
          Uri.parse('${_currentProvider!.baseUrl}/text/chatcompletion_v2'),
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
      var response = await http.get(
        Uri.parse(_url('/v1/models')),
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

      // 如果失败，尝试 MiniMax 专用接口
      response = await http.get(
        Uri.parse('${_currentProvider!.baseUrl}/models'),
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
