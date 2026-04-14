import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  static const String _baseUrl = 'https://api.mymemory.translated.net/get';

  /// Translate text from sourceLang to targetLang using MyMemory API (free, no key needed)
  /// langs: 'en'->'zh-CN', 'zh-CN'->'en', 'en'->'es', etc.
  Future<String?> translate(String text, {
    String fromLang = 'en',
    String toLang = 'zh-CN',
  }) async {
    if (text.trim().isEmpty) return null;
    
    try {
      final langPair = '$fromLang|$toLang';
      final uri = Uri.parse('$_baseUrl').replace(queryParameters: {
        'q': text,
        'langpair': langPair,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['responseStatus'] == 200) {
          return data['responseData']['translatedText'];
        }
      }
    } catch (_) {}
    return null;
  }

  /// Quick translate English to Chinese
  Future<String?> enToZh(String text) => translate(text, fromLang: 'en', toLang: 'zh-CN');

  /// Translate Chinese to English
  Future<String?> zhToEn(String text) => translate(text, fromLang: 'zh-CN', toLang: 'en');
}
