import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'providers/theme_provider.dart';
import 'providers/model_providers.dart';
import 'services/llm_service.dart';
import 'services/quote_generator_service.dart';
import 'services/log_service.dart';

/// Global navigator key for notification tap navigation (Bug 2 fix)
final GlobalKey<NavigatorState> notificationNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger first
  await LogService().initialize();

  // Initialize notification service
  await NotificationService().initialize();

  // Global error handler
  FlutterError.onError = (details) {
    LogService().error('FlutterError', details.exception, details.stack);
  };

  // Request permissions
  await PermissionService.requestAllPermissions();

  // Initialize LlmService with saved default provider (Bug 4 fix)
  await _initLlmService();

  runApp(
    ProviderScope(
      child: WisdomQuotesApp(),
    ),
  );
}

/// Load the saved default provider into LlmService and QuoteGeneratorService on startup
Future<void> _initLlmService() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('model_providers');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      final providers = list
          .map((e) => ModelProvider.fromJson(e as Map<String, dynamic>))
          .toList();
      if (providers.isNotEmpty) {
        final defaultProvider = providers.firstWhere(
          (p) => p.isDefault,
          orElse: () => providers.first,
        );
        LlmService().setProvider(defaultProvider);
        // Bug 29 fix: also initialize QuoteGeneratorService so AI生成 works on fresh start
        QuoteGeneratorService().setProvider(defaultProvider);
      }
    }
  } catch (_) {}
}

class WisdomQuotesApp extends ConsumerStatefulWidget {
  const WisdomQuotesApp({super.key});

  @override
  ConsumerState<WisdomQuotesApp> createState() => _WisdomQuotesAppState();
}

class _WisdomQuotesAppState extends ConsumerState<WisdomQuotesApp> {
  @override
  void initState() {
    super.initState();
    // Sync LlmService with the current default provider after providers load
    Future.microtask(() {
      final providers = ref.read(modelProvidersProvider);
      if (providers.isNotEmpty) {
        final defaultProvider = providers.firstWhere(
          (p) => p.isDefault,
          orElse: () => providers.first,
        );
        LlmService().setProvider(defaultProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: '智慧名言',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeMode,
      navigatorKey: notificationNavigatorKey,
      home: const SplashScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
