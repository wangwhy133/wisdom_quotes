import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String modelId;
  final bool isDefault;

  ModelProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'modelId': modelId,
    'isDefault': isDefault,
  };

  factory ModelProvider.fromJson(Map<String, dynamic> json) => ModelProvider(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    baseUrl: json['baseUrl'] ?? '',
    apiKey: json['apiKey'] ?? '',
    modelId: json['modelId'] ?? '',
    isDefault: json['isDefault'] ?? false,
  );

  ModelProvider copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    String? modelId,
    bool? isDefault,
  }) {
    return ModelProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      modelId: modelId ?? this.modelId,
      isDefault: isDefault ?? this.isDefault,
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
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> setDefault(String id) async {
    state = state.map((e) => e.copyWith(isDefault: e.id == id)).toList();
    await _save();
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
