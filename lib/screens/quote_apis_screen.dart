import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

final quoteApisProvider = StateNotifierProvider<QuoteApisNotifier, List<QuoteApiProvider>>((ref) {
  return QuoteApisNotifier();
});

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

class QuoteApisScreen extends ConsumerStatefulWidget {
  const QuoteApisScreen({super.key});

  @override
  ConsumerState<QuoteApisScreen> createState() => _QuoteApisScreenState();
}

class _QuoteApisScreenState extends ConsumerState<QuoteApisScreen> {
  @override
  Widget build(BuildContext context) {
    final apis = ref.watch(quoteApisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('名言API管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showApiDialog(context),
          ),
        ],
      ),
      body: apis.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.api, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('暂无名言API'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showApiDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加API'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: apis.length,
              itemBuilder: (ctx, i) => _buildApiCard(apis[i]),
            ),
    );
  }

  Widget _buildApiCard(QuoteApiProvider api) {
    final isDefault = api.isDefault;
    final isEnabled = api.isEnabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showApiDialog(context, api: api),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      api.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                  if (isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '默认',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (!isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 20),
                              SizedBox(width: 8),
                              Text('设为默认'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(isEnabled ? Icons.pause : Icons.play_arrow, size: 20),
                            const SizedBox(width: 8),
                            Text(isEnabled ? '禁用' : '启用'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'default') {
                        ref.read(quoteApisProvider.notifier).setDefault(api.id);
                      } else if (value == 'toggle') {
                        ref.read(quoteApisProvider.notifier).toggleEnabled(api.id);
                      } else if (value == 'delete') {
                        ref.read(quoteApisProvider.notifier).remove(api.id);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                api.baseUrl,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _testApi(api),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('测试'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getMethodLabel(api.method),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'xygeng':
        return '句野API格式';
      case 'zenquotes':
        return 'ZenQuotes格式';
      case 'quotable':
        return 'Quotable格式';
      case 'custom':
        return '自定义格式';
      default:
        return method;
    }
  }

  Future<void> _testApi(QuoteApiProvider api) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('测试中...'),
          ],
        ),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse(api.baseUrl),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String quote = _extractQuote(data, api.method);
        _showResultDialog(true, quote);
      } else {
        _showResultDialog(false, 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _showResultDialog(false, e.toString());
    }
  }

  String _extractQuote(dynamic data, String method) {
    try {
      switch (method) {
        case 'xygeng':
          if (data['data'] != null) {
            return '"${data['data']['content']}" — ${data['data']['author']}';
          }
          break;
        case 'zenquotes':
          if (data is List && data.isNotEmpty) {
            return '"${data[0]['q']}" — ${data[0]['a']}';
          }
          break;
        case 'quotable':
          return '"${data['content']}" — ${data['author']}';
        default:
          return data.toString().substring(0, 100);
      }
    } catch (e) {
      return '解析失败';
    }
    return '无法解析响应';
  }

  void _showResultDialog(bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? '测试成功' : '测试失败'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showApiDialog(BuildContext context, {QuoteApiProvider? api}) {
    final isEditing = api != null;
    final nameController = TextEditingController(text: api?.name ?? '');
    final urlController = TextEditingController(text: api?.baseUrl ?? '');
    String selectedMethod = api?.method ?? 'custom';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? '编辑API' : '添加API'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名称',
                    hintText: '如：我的名言API',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://api.example.com/quotes/random',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: '响应格式',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'xygeng', child: Text('句野API格式')),
                    DropdownMenuItem(value: 'zenquotes', child: Text('ZenQuotes格式')),
                    DropdownMenuItem(value: 'quotable', child: Text('Quotable格式')),
                    DropdownMenuItem(value: 'custom', child: Text('自定义格式')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedMethod = value ?? 'custom');
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _getMethodHint(selectedMethod),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || urlController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写名称和URL')),
                  );
                  return;
                }
                final newApi = QuoteApiProvider(
                  id: api?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  baseUrl: urlController.text.trim(),
                  method: selectedMethod,
                  isDefault: api?.isDefault ?? false,
                  isEnabled: api?.isEnabled ?? true,
                );
                if (isEditing) {
                  ref.read(quoteApisProvider.notifier).update(newApi);
                } else {
                  ref.read(quoteApisProvider.notifier).add(newApi);
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodHint(String method) {
    switch (method) {
      case 'xygeng':
        return '返回格式：{"code":200,"data":{"content":"...","author":"..."}}';
      case 'zenquotes':
        return '返回格式：[{"q":"...","a":"..."}]';
      case 'quotable':
        return '返回格式：{"content":"...","author":"..."}';
      default:
        return '请确保API返回名言文本';
    }
  }
}
