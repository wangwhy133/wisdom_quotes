import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/model_providers.dart';
import '../data/database.dart';

class QuoteGeneratorService {
  static final QuoteGeneratorService _instance = QuoteGeneratorService._internal();
  factory QuoteGeneratorService() => _instance;
  QuoteGeneratorService._internal();

  Future<List<Map<String, dynamic>>> generateQuotes({
    required List<ModelProvider> providers,
    int count = 20,
    QuoteCategory category = QuoteCategory.investment,
  }) async {
    final provider = providers.isNotEmpty 
        ? providers.firstWhere((p) => p.isDefault, orElse: () => providers.first)
        : null;
    
    if (provider == null || provider.apiKey.isEmpty) return [];

    try {
      final uri = Uri.parse('${provider.baseUrl}/text/chatcompletion_v2');
      
      final tagMap = {
        QuoteCategory.classicLiterature: '经典名著、文学',
        QuoteCategory.poetry: '诗词、古诗',
        QuoteCategory.investment: '投资、商业、理财',
      };

      final body = json.encode({
        'model': provider.modelId,
        'messages': [
          {
            'role': 'user',
            'content': '''请生成 $count 条名言警句，要求：
1. 每条包含：内容(content)、作者(author)、出处(source，可选)、标签(tags)
2. 类别：${tagMap[category]}
3. 内容要有深度，中英文名言都可以
4. 返回严格的JSON数组格式，每条包含：content、author、source、tags
5. tags用英文逗号分隔，如：投资,巴菲特,智慧

直接返回JSON数组，不要其他文字：'''
          }
        ],
        'max_tokens': 2000,
        'temperature': 0.8,
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${provider.apiKey}',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices']?[0]?['message']?['content'] ?? '';
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final List<dynamic> quotes = json.decode(jsonStr);
          return quotes.map((q) => {
            'content': q['content'] ?? '',
            'author': q['author'] ?? 'Unknown',
            'source': q['source'] ?? '',
            'tags': q['tags'] ?? '',
            'category': category.index,
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
