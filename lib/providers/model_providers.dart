import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/llm_service.dart';
import '../services/quote_generator_service.dart';

// Bug 25 fix: obfuscate API keys before storing in SharedPreferences (lightweight, not crypto-grade)
String _obfuscate(String input) => input.isEmpty ? '' : base64Encode(utf8.encode(input));
String _deobfuscate(String input) {
  if (input.isEmpty) return '';
  try {
    return utf8.decode(base64Decode(input));
  } catch (_) {
    return input; // fallback if not encoded
  }
}

class ModelProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String modelId;
  final bool isDefault;
  /// 自定义Endpoint，留空则使用默认端点
  final String endpoint;

  ModelProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
    this.isDefault = false,
    this.endpoint = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    // Bug 25 fix: obfuscate API key in storage
    'apiKey': _obfuscate(apiKey),
    'modelId': modelId,
    'isDefault': isDefault,
    'endpoint': endpoint,
  };

  factory ModelProvider.fromJson(Map<String, dynamic> json) => ModelProvider(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    baseUrl: json['baseUrl'] ?? '',
    // Bug 25 fix: deobfuscate API key when loading
    apiKey: _deobfuscate(json['apiKey'] ?? ''),
    modelId: json['modelId'] ?? '',
    isDefault: json['isDefault'] ?? false,
    endpoint: json['endpoint'] ?? '',
  );

  ModelProvider copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? modelId,
    bool? isDefault,
    String? endpoint,
  }) {
    return ModelProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelId: modelId ?? this.modelId,
      isDefault: isDefault ?? this.isDefault,
      endpoint: endpoint ?? this.endpoint,
    );
  }
}

class ModelProvidersNotifier extends StateNotifier<List<ModelProvider>> {
  ModelProvidersNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('model_providers');
    if (data != null) {
      final List<dynamic> list = json.decode(data);
      state = list.map((e) => ModelProvider.fromJson(e)).toList();
    } else {
      // Add default Zhipu GLM provider (永久免费)
      state = [
        ModelProvider(
          id: 'zhipu_default',
          name: '智谱GLM',
          baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
          apiKey: '',
          modelId: 'glm-4-flash',
          isDefault: true,
        ),
      ];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('model_providers', json.encode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> add(ModelProvider provider) async {
    state = [...state, provider];
    await _save();
  }

  Future<void> update(ModelProvider provider) async {
    state = state.map((e) => e.id == provider.id ? provider : e).toList();
    await _save();
  }

  Future<void> remove(String id) async {
    // Bug 32 fix: if removing current cached provider, switch cache to new default
    final current = LlmService().currentProvider;
    state = state.where((e) => e.id != id).toList();
    await _save();
    if (current?.id == id) {
      final newDefault = defaultProvider;
      if (newDefault != null) LlmService().setProvider(newDefault);
    }
  }

  Future<void> setDefault(String id) async {
    state = state.map((e) => e.copyWith(isDefault: e.id == id)).toList();
    await _save();
    // Bug 32 fix: sync LlmService cache when default changes
    final newDefault = defaultProvider;
    if (newDefault != null) LlmService().setProvider(newDefault);
  }

  ModelProvider? get defaultProvider {
    try {
      return state.firstWhere((e) => e.isDefault);
    } catch (_) {
      return state.isNotEmpty ? state.first : null;
    }
  }
}

final modelProvidersProvider = StateNotifierProvider<ModelProvidersNotifier, List<ModelProvider>>((ref) {
  return ModelProvidersNotifier();
});

/// Refactor: current active LLM provider — derived from modelProvidersProvider.
/// This is the SINGLE SOURCE OF TRUTH for which provider is currently active.
/// Screens should read this instead of maintaining their own provider selection logic.
final currentLlmProviderProvider = Provider<ModelProvider?>((ref) {
  final providers = ref.watch(modelProvidersProvider);
  if (providers.isEmpty) return null;
  try {
    return providers.firstWhere((p) => p.isDefault);
  } catch (_) {
    return providers.first;
  }
});

/// Refactor: QuoteGeneratorService provider derived from currentLlmProviderProvider.
final quoteGeneratorProvider = Provider<QuoteGeneratorService>((ref) {
  final svc = QuoteGeneratorService();
  final provider = ref.watch(currentLlmProviderProvider);
  if (provider != null) svc.setProvider(provider);
  return svc;
});
