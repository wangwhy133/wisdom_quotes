import 'dart:convert';
import 'package:http/http.dart' as http;

/// 名言API服务 - 国内可用
/// 使用 https://api.xygeng.cn/BoKeAPI 开放接口
class QuoteApiService {
  static const String _baseUrl = 'https://api.xygeng.cn/BoKeAPI';
  
  /// 获取一条随机名言
  static Future<QuoteApiResult?> getRandomQuote() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/random'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          return QuoteApiResult(
            content: data['data']['content'] ?? '',
            author: data['data']['author'] ?? '未知',
            source: data['data']['source'] ?? '',
            category: _guessCategory(data['data']['content'] ?? ''),
          );
        }
      }
    } catch (e) {
      // 备用：尝试返回本地默认名言
    }
    return _fallbackQuote();
  }

  /// 获取多条名言
  static Future<List<QuoteApiResult>> getQuotes({int count = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/type/随机/$count'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          return (data['data'] as List).map((item) => QuoteApiResult(
            content: item['content'] ?? '',
            author: item['author'] ?? '未知',
            source: item['source'] ?? '',
            category: _guessCategory(item['content'] ?? ''),
          )).toList();
        }
      }
    } catch (e) {
      // ignore
    }
    return [_fallbackQuote()!];
  }

  /// 根据分类获取名言
  static Future<List<QuoteApiResult>> getQuotesByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/type/$category/20'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          return (data['data'] as List).map((item) => QuoteApiResult(
            content: item['content'] ?? '',
            author: item['author'] ?? '未知',
            source: item['source'] ?? '',
            category: category,
          )).toList();
        }
      }
    } catch (e) {
      // ignore
    }
    return [_fallbackQuote()!];
  }

  static String _guessCategory(String content) {
    if (content.contains('投资') || content.contains('巴菲特') || content.contains('股票') || content.contains('财富')) {
      return 'investment';
    } else if (content.contains('道') || content.contains('佛') || content.contains('禅')) {
      return 'poetry';
    }
    return 'classicLiterature';
  }

  static QuoteApiResult? _fallbackQuote() {
    return QuoteApiResult(
      content: '学而不思则罔，思而不学则殆。',
      author: '孔子',
      source: '论语',
      category: 'classicLiterature',
    );
  }
}

class QuoteApiResult {
  final String content;
  final String author;
  final String source;
  final String category;

  QuoteApiResult({
    required this.content,
    required this.author,
    required this.source,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'author': author,
      'source': source,
      'category': category == 'investment' ? 2 : (category == 'poetry' ? 1 : 0),
      'tags': '',
    };
  }
}
