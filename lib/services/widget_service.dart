import 'package:flutter/services';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';

class WidgetService {
  static const String _prefsName = 'quote_widget_prefs';
  
  /// 更新桌面小部件数据
  static Future<void> updateWidget({
    required int widgetId,
    required String quote,
    required String author,
    required String category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final keyPrefix = 'quote_$widgetId';
    
    await prefs.setString(keyPrefix, quote);
    await prefs.setString('author_$widgetId', author);
    await prefs.setString('category_$widgetId', category);
    
    // 通知 Android widget 更新
    try {
      const platform = MethodChannel('wisdom_quotes/widget');
      await platform.invokeMethod('updateWidget', {'widgetId': widgetId});
    } catch (e) {
      // Widget channel 可能未初始化，忽略错误
    }
  }

  /// 获取随机名言并更新 Widget
  static Future<void> refreshWidgetQuote(int widgetId, AppDatabase db) async {
    final quote = await db.getRandomQuote();
    if (quote != null) {
      await updateWidget(
        widgetId: widgetId,
        quote: quote.content,
        author: quote.author,
        category: _getCategoryName(quote.category),
      );
    }
  }

  static String _getCategoryName(dynamic category) {
    switch (category.toString()) {
      case 'QuoteCategory.classicLiterature':
        return '经典名著';
      case 'QuoteCategory.poetry':
        return '诗词';
      case 'QuoteCategory.investment':
        return '投资名言';
      default:
        return '';
    }
  }
}
