import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Refactor: moved from quote_apis_screen.dart — providers belong in lib/providers/
class QuoteApiProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String method; // xygeng, zenquotes, quotable, custom
  final bool isDefault;
  final bool isEnabled;
  final String category; // 分类: investment, philosophy, poetry, literature, general
  int quoteCount; // 导入的名言数量

  QuoteApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.method = 'xygeng',
    this.isDefault = false,
    this.isEnabled = true,
    this.category = 'general',
    this.quoteCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'method': method,
    'isDefault': isDefault,
    'isEnabled': isEnabled,
    'category': category,
    'quoteCount': quoteCount,
  };

  factory QuoteApiProvider.fromJson(Map<String, dynamic> json) => QuoteApiProvider(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    baseUrl: json['baseUrl'] ?? '',
    method: json['method'] ?? 'xygeng',
    isDefault: json['isDefault'] ?? false,
    isEnabled: json['isEnabled'] ?? true,
    category: json['category'] ?? 'general',
    quoteCount: json['quoteCount'] ?? 0,
  );

  QuoteApiProvider copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? method,
    bool? isDefault,
    bool? isEnabled,
    String? category,
    int? quoteCount,
  }) {
    return QuoteApiProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      method: method ?? this.method,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
      category: category ?? this.category,
      quoteCount: quoteCount ?? this.quoteCount,
    );
  }
}

class QuoteApisNotifier extends StateNotifier<List<QuoteApiProvider>> {
  QuoteApisNotifier() : super([]) {
    _load();
  }

  static const String _key = 'quote_apis';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final List<dynamic> list = json.decode(data);
      state = list.map((e) => QuoteApiProvider.fromJson(e)).toList();
    } else {
      // Default APIs
      state = [
        QuoteApiProvider(
          id: 'xygeng_cn',
          name: '句野API (综合)',
          baseUrl: 'https://api.xygeng.cn/BoKeAPI/random',
          method: 'xygeng',
          category: 'general',
          isDefault: true,
          isEnabled: true,
        ),
        QuoteApiProvider(
          id: 'zenquotes_invest',
          name: 'ZenQuotes (投资)',
          baseUrl: 'https://zenquotes.io/api/random',
          method: 'zenquotes',
          category: 'investment',
          isEnabled: true,
        ),
        QuoteApiProvider(
          id: 'quotable_philo',
          name: 'Quotable (哲学)',
          baseUrl: 'https://api.quotable.io/random',
          method: 'quotable',
          category: 'philosophy',
          isEnabled: false,
        ),
        QuoteApiProvider(
          id: 'урл',
          name: '励志名言API',
          baseUrl: 'https://api.vvhan.com/api/mingyan',
          method: 'custom',
          category: 'motivation',
          isEnabled: false,
        ),
      ];
      _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> add(QuoteApiProvider api) async {
    state = [...state, api];
    await _save();
  }

  Future<void> update(QuoteApiProvider api) async {
    state = state.map((e) => e.id == api.id ? api : e).toList();
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> setDefault(String id) async {
    state = state.map((e) => e.copyWith(isDefault: e.id == id)).toList();
    await _save();
  }

  Future<void> toggleEnabled(String id) async {
    state = state.map((e) => e.id == id ? e.copyWith(isEnabled: !e.isEnabled) : e).toList();
    await _save();
  }
}

final quoteApisProvider = StateNotifierProvider<QuoteApisNotifier, List<QuoteApiProvider>>((ref) {
  return QuoteApisNotifier();
});
