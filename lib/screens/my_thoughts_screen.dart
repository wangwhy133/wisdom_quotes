import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../providers/providers.dart';

class MyThoughtsScreen extends ConsumerStatefulWidget {
  const MyThoughtsScreen({super.key});

  @override
  ConsumerState<MyThoughtsScreen> createState() => _MyThoughtsScreenState();
}

class _MyThoughtsScreenState extends ConsumerState<MyThoughtsScreen> {
  bool _isLoading = true;
  List<Quote> _thoughts = [];
  String? _error; // Bug 15 fix: track error state

  @override
  void initState() {
    super.initState();
    _loadThoughts();
  }

  Future<void> _loadThoughts() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final thoughts = await db.getAllMyThoughts();
      setState(() {
        _thoughts = thoughts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _addThought() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddThoughtDialog(),
    );

    if (result != null) {
      final db = ref.read(databaseProvider);
      await db.insertMyThought(result);
      _loadThoughts();
    }
  }

  Future<void> _editThought(Quote thought) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddThoughtDialog(existingThought: thought),
    );

    if (result != null) {
      final db = ref.read(databaseProvider);
      await db.updateMyThought(thought.id, result);
      _loadThoughts();
    }
  }

  Future<void> _deleteThought(Quote thought) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定要删除这条吾思吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await db.deleteMyThought(thought.id);
      _loadThoughts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('吾思'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadThoughts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addThought,
        icon: const Icon(Icons.add),
        label: const Text('添加吾思'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无吾思',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮，记录你的想法',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bug 15 fix: handle error state (was showing blank screen)
  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadThoughts,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (_thoughts.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _thoughts.length,
      itemBuilder: (context, index) {
        final thought = _thoughts[index];
        return _buildThoughtCard(thought);
      },
    );
  }

  Widget _buildThoughtCard(Quote thought) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editThought(thought),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: Colors.purple[700]),
                        const SizedBox(width: 4),
                        Text(
                          '吾思',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteThought(thought),
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                thought.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
              if (thought.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '笔记',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thought.notes,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(thought.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _AddThoughtDialog extends StatefulWidget {
  final Quote? existingThought;

  const _AddThoughtDialog({this.existingThought});

  @override
  State<_AddThoughtDialog> createState() => _AddThoughtDialogState();
}

class _AddThoughtDialogState extends State<_AddThoughtDialog> {
  late final TextEditingController _contentController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.existingThought?.content ?? '');
    _notesController = TextEditingController(text: widget.existingThought?.notes ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingThought != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑吾思' : '添加吾思'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '名言内容 *',
                hintText: '写下你的想法...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '笔记（可选）',
                hintText: '记录你的思考...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
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
            if (_contentController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入名言内容')),
              );
              return;
            }
            Navigator.pop(context, {
              'content': _contentController.text.trim(),
              'notes': _notesController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }
}
