import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// All quotes stream
final allQuotesProvider = StreamProvider<List<Quote>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllQuotes();
});

// Selected category
final selectedCategoryProvider = StateProvider<QuoteCategory?>((ref) => null);

// Filtered quotes by category
final filteredQuotesProvider = StreamProvider<List<Quote>>((ref) {
  final db = ref.watch(databaseProvider);
  final category = ref.watch(selectedCategoryProvider);
  
  if (category == null) {
    return db.watchAllQuotes();
  }
  return db.watchQuotesByCategory(category);
});

// Favorites stream
final favoritesProvider = StreamProvider<List<Quote>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchFavorites();
});

// Search results
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Quote>>((ref) async {
  final db = ref.watch(databaseProvider);
  final query = ref.watch(searchQueryProvider);
  
  if (query.isEmpty) return [];
  return db.searchQuotes(query);
});

// Daily quote
final dailyQuoteProvider = FutureProvider<Quote?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getRandomQuote();
});

// Notification settings
final notificationEnabledProvider = StateProvider<bool>((ref) => false);
final notificationHourProvider = StateProvider<int>((ref) => 8);
final notificationMinuteProvider = StateProvider<int>((ref) => 0);
