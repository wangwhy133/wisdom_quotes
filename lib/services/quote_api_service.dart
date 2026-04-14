import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../data/database.dart';

class QuoteApiService {
  static final QuoteApiService _instance = QuoteApiService._internal();
  factory QuoteApiService() => _instance;
  QuoteApiService._internal();

  final Random _random = Random();

  /// Fetch random quote from quotable.io
  Future<Quote?> fetchFromQuotable() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.quotable.io/random'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return Quote(
          id: -_random.nextInt(100000),
          content: data['content'] ?? '',
          author: data['author'] ?? 'Unknown',
          source: null,
          category: QuoteCategory.investment,
          tags: 'API',
          isFavorite: false,
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Fetch quotes from type.fit
  Future<List<Quote>> fetchFromTypeFit() async {
    try {
      final res = await http.get(
        Uri.parse('https://type.fit/api/quotes'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data
            .where((item) => item['text'] != null && item['author'] != null)
            .map((item) {
          String author = item['author'] ?? 'Unknown';
          if (author == 'null') author = 'Unknown';
          return Quote(
            id: -_random.nextInt(100000) - _random.nextInt(100),
            content: item['text'] ?? '',
            author: author,
            source: null,
            category: QuoteCategory.investment,
            tags: 'API',
            isFavorite: false,
            createdAt: DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch from zenquotes.io
  Future<List<Quote>> fetchFromZenQuotes() async {
    try {
      final res = await http.get(
        Uri.parse('https://zenquotes.io/api/quotes'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((item) {
          return Quote(
            id: -_random.nextInt(100000) - _random.nextInt(100),
            content: item['q'] ?? '',
            author: item['a'] ?? 'Unknown',
            source: item['h'] != null && item['h'].isNotEmpty ? item['h'] : null,
            category: QuoteCategory.investment,
            tags: 'API',
            isFavorite: false,
            createdAt: DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch from all APIs
  Future<List<Quote>> fetchFromAllApis() async {
    final results = await Future.wait([
      fetchFromQuotable(),
      fetchFromTypeFit(),
      fetchFromZenQuotes(),
    ]);

    final quotes = <Quote>[];
    for (final result in results) {
      if (result is List<Quote>) {
        quotes.addAll(result.where((q) => q.id < 0));
      } else if (result is Quote && result.id < 0) {
        quotes.add(result);
      }
    }
    return quotes;
  }
}
