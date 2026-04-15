import 'dart:convert';
import 'package:http/http.dart' as http;

/// 名言API服务 - 国内外双线路
/// 国内优先，失败后自动切换国际线路
class QuoteApiService {
  // ============ 国内API（优先） ============
  static const String _cnBaseUrl = 'https://api.xygeng.cn/BoKeAPI';
  
  // ============ 国际API（备用） ============
  static const String _intlBaseUrl1 = 'https://zenquotes.io/api';
  static const String _intlBaseUrl2 = 'https://api.quotable.io';
  
  /// 获取一条随机名言（自动选择可用线路）
  static Future<QuoteApiResult?> getRandomQuote() async {
    // 优先试国内API
    var result = await _getRandomQuoteCn();
    if (result != null) return result;
    
    // 备用国际API
    result = await _getRandomQuoteIntlZenquotes();
    if (result != null) return result;
    
    result = await _getRandomQuoteIntlQuotable();
    if (result != null) return result;
    
    return _fallbackQuote();
  }
  
  /// 获取多条名言
  static Future<List<QuoteApiResult>> getQuotes({int count = 10}) async {
    // 优先试国内
    var results = await _getQuotesCn(count);
    if (results.isNotEmpty) return results;
    
    // 备用国际
    results = await _getQuotesIntl(count);
    if (results.isNotEmpty) return results;
    
    return [_fallbackQuote()!];
  }
  
  // ============ 国内API实现 ============
  static Future<QuoteApiResult?> _getRandomQuoteCn() async {
    try {
      final response = await http.get(
        Uri.parse('$_cnBaseUrl/random'),
      ).timeout(const Duration(seconds: 8));
      
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
      // 忽略错误，尝试下一个API
    }
    return null;
  }
  
  static Future<List<QuoteApiResult>> _getQuotesCn(int count) async {
    try {
      final response = await http.get(
        Uri.parse('$_cnBaseUrl/type/随机/$count'),
      ).timeout(const Duration(seconds: 10));
      
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
    return [];
  }
  
  // ============ 国际API实现（ZenQuotes） ============
  static Future<QuoteApiResult?> _getRandomQuoteIntlZenquotes() async {
    try {
      final response = await http.get(
        Uri.parse('$_intlBaseUrl1/random'),
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final item = data[0];
          return QuoteApiResult(
            content: item['q'] ?? '',
            author: item['a'] ?? 'Unknown',
            source: item['h'] ?? '',
            category: 'classicLiterature',
          );
        }
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
  
  // ============ 国际API实现（Quotable） ============
  static Future<QuoteApiResult?> _getRandomQuoteIntlQuotable() async {
    try {
      final response = await http.get(
        Uri.parse('$_intlBaseUrl2/random'),
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuoteApiResult(
          content: data['content'] ?? '',
          author: data['author'] ?? 'Unknown',
          source: '',
          category: 'classicLiterature',
        );
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
  
  // ============ 国际API获取多条 ============
  static Future<List<QuoteApiResult>> _getQuotesIntl(int count) async {
    try {
      final response = await http.get(
        Uri.parse('$_intlBaseUrl1/quotes'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.take(count).map((item) => QuoteApiResult(
            content: item['q'] ?? '',
            author: item['a'] ?? 'Unknown',
            source: item['h'] ?? '',
            category: 'classicLiterature',
          )).toList();
        }
      }
    } catch (e) {
      // ignore
    }
    return [];
  }
  
  static String _guessCategory(String content) {
    if (content.contains('投资') || content.contains('巴菲特') || content.contains('股票') || content.contains('财富')) {
      return 'investment';
    }
    // 道/佛/禅 属于哲学思辨，归为经典名著更准确
    // （app仅有 classicLiterature/poetry/investment 三个分类，无 philosophy）
    return 'classicLiterature';
  }
  
  static QuoteApiResult _fallbackQuote() {
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
