import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/model_providers.dart';
import '../services/llm_service.dart';

class ModelProvidersScreen extends ConsumerStatefulWidget {
  const ModelProvidersScreen({super.key});

  @override
  ConsumerState<ModelProvidersScreen> createState() => _ModelProvidersScreenState();
}

class _ModelProvidersScreenState extends ConsumerState<ModelProvidersScreen> {
  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(modelProvidersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型提供商'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProviderDialog(context),
          ),
        ],
      ),
      body: providers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('暂无模型提供商'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showProviderDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加提供商'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              itemBuilder: (ctx, i) => _buildProviderCard(providers[i]),
            ),
    );
  }

  Widget _buildProviderCard(ModelProvider provider) {
    final isDefault = provider.isDefault;
    final hasKey = provider.apiKey.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showProviderDialog(context, provider: provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDefault ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.cloud,
                      color: isDefault ? Colors.green[700] : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              provider.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '默认',
                                  style: TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.baseUrl,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isDefault)
                    TextButton(
                      onPressed: () {
                        ref.read(modelProvidersProvider.notifier).setDefault(provider.id);
                        LlmService().setProvider(provider.copyWith(isDefault: true));
                      },
                      child: const Text('设为默认'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.key, hasKey ? '已配置API Key' : '未配置API Key',
                      hasKey ? Colors.green : Colors.orange),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.smart_toy, provider.modelId.isEmpty ? '未设置模型' : provider.modelId,
                      provider.modelId.isEmpty ? Colors.grey : Colors.blue),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('编辑'),
                    onPressed: () => _showProviderDialog(context, provider: provider),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18, color: Colors.green),
                    label: const Text('测试', style: TextStyle(color: Colors.green)),
                    onPressed: () => _testProvider(provider),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text('删除', style: TextStyle(color: Colors.red)),
                    onPressed: () => _confirmDelete(provider),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ModelProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${provider.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(modelProvidersProvider.notifier).remove(provider.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProviderDialog(BuildContext context, {ModelProvider? provider}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProviderForm(provider: provider),
    );
  }

  Future<void> _testProvider(ModelProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 16),
            Text('测试连接中...'),
          ],
        ),
      ),
    );

    final result = await LlmService().testConnection(provider);

    if (mounted) {
      Navigator.pop(context); // 关闭loading
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(result.success ? '✅ 测试成功' : '❌ 测试失败'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }
}

class _ProviderForm extends ConsumerStatefulWidget {
  final ModelProvider? provider;

  const _ProviderForm({this.provider});

  @override
  ConsumerState<_ProviderForm> createState() => _ProviderFormState();
}

class _ProviderFormState extends ConsumerState<_ProviderForm> {
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelIdController = TextEditingController();
  bool _showApiKey = false;
  bool _isFetchingModels = false;
  List<String> _availableModels = [];
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      _nameController.text = widget.provider!.name;
      _baseUrlController.text = widget.provider!.baseUrl;
      _apiKeyController.text = widget.provider!.apiKey;
      _modelIdController.text = widget.provider!.modelId;
      _selectedModel = widget.provider!.modelId;
    } else {
      _baseUrlController.text = 'https://api.minimax.chat/v1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelIdController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(BuildContext context) async {
    if (_baseUrlController.text.isEmpty || _apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 Base URL 和 API Key')),
      );
      return;
    }

    final tempProvider = ModelProvider(
      id: 'temp',
      name: _nameController.text.isEmpty ? 'Temp' : _nameController.text,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      modelId: _modelIdController.text,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 16),
            Text('测试连接中...'),
          ],
        ),
      ),
    );

    final result = await LlmService().testConnection(tempProvider);

    if (context.mounted) {
      Navigator.pop(context); // 关闭loading
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(result.success ? '✅ 测试成功' : '❌ 测试失败'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _fetchModels() async {
    if (_baseUrlController.text.isEmpty || _apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先填写 Base URL 和 API Key')),
      );
      return;
    }

    setState(() => _isFetchingModels = true);

    // Temporarily set provider to fetch models
    final tempProvider = ModelProvider(
      id: 'temp',
      name: _nameController.text.isEmpty ? 'Temp' : _nameController.text,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      modelId: _modelIdController.text,
    );
    LlmService().setProvider(tempProvider);

    final models = await LlmService().fetchModels();

    setState(() {
      _isFetchingModels = false;
      if (models != null && models.isNotEmpty) {
        _availableModels = models;
      }
    });

    if (models == null || models.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法获取模型列表，请检查配置')),
        );
      }
    }
  }

  void _save() {
    if (_nameController.text.isEmpty ||
        _baseUrlController.text.isEmpty ||
        _apiKeyController.text.isEmpty ||
        _modelIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有必填项')),
      );
      return;
    }

    final provider = ModelProvider(
      id: widget.provider?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      modelId: _modelIdController.text,
      isDefault: widget.provider?.isDefault ?? false,
    );

    if (widget.provider != null) {
      ref.read(modelProvidersProvider.notifier).update(provider);
    } else {
      ref.read(modelProvidersProvider.notifier).add(provider);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.provider != null ? '编辑提供商' : '添加提供商',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                hintText: '如：MiniMax、OpenAI',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL *',
                hintText: 'https://api.minimax.chat/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: !_showApiKey,
              decoration: InputDecoration(
                labelText: 'API Key *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showApiKey = !_showApiKey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _modelIdController,
                    decoration: const InputDecoration(
                      labelText: '模型 ID *',
                      hintText: '如：MiniMax-M2.7 / gpt-4o-mini',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _selectedModel = v,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isFetchingModels ? null : _fetchModels,
                  child: _isFetchingModels
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('获取模型'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _apiKeyController.text.isEmpty || _baseUrlController.text.isEmpty
                  ? null
                  : () => _testConnection(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('测试连接'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
            if (_availableModels.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('可选模型：', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableModels.map((m) => ChoiceChip(
                  label: Text(m, style: const TextStyle(fontSize: 12)),
                  selected: _selectedModel == m,
                  onSelected: (selected) {
                    setState(() {
                      _selectedModel = selected ? m : null;
                      _modelIdController.text = m;
                    });
                  },
                )).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.provider != null ? '保存修改' : '添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
