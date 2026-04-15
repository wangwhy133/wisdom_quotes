import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  String _getVersion() {
    // 从 pubspec 获取版本
    try {
      final channel = const MethodChannel('flutter/app');
      return 'v1.1.5'; // Bug 18 fix: sync with pubspec.yaml
    } catch (e) {
      return 'v1.1.5'; // Bug 18 fix
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App logo and name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      '智',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '智慧名言',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'WISDOM QUOTES',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'v1.1.5', // Bug 18 fix
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      const Text(
                        '应用简介',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '智慧名言是一款收录中英文精选名言的应用，涵盖投资智慧、哲学思辨、诗词歌赋、经典名著。支持 AI 解读、AI 生成、笔记记录、吾思等功能。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // GitHub
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.code,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text('GitHub 仓库'),
              subtitle: const Text('github.com/wangwhy133/wisdom_quotes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _launchUrl('https://github.com/wangwhy133/wisdom_quotes'),
            ),
          ),
          const SizedBox(height: 8),
          
          // Author
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: const Text('作者'),
              subtitle: const Text('@wangwhy133'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _launchUrl('https://github.com/wangwhy133'),
            ),
          ),
          const SizedBox(height: 16),
          
          // Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_outline, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      const Text(
                        '主要功能',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('📚 2000+ 名言', '收录投资、哲学、诗词、文学名言'),
                  _buildFeatureItem('🤖 AI 解读', 'LLM 驱动名言深度解析'),
                  _buildFeatureItem('✨ AI 生成', '使用 AI 生成新名言'),
                  _buildFeatureItem('📝 笔记功能', '记录你对名言的想法'),
                  _buildFeatureItem('💭 吾思', '写下你自己的名言'),
                  _buildFeatureItem('🌐 批量翻译', '中英文双向翻译'),
                  _buildFeatureItem('🔔 每日推送', '每天接收智慧语录'),
                  _buildFeatureItem('📱 桌面组件', '桌面显示每日名言'),
                  _buildFeatureItem('🌓 暗黑模式', '支持深色主题'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Tech stack
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build_outlined, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      const Text(
                        '技术栈',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTechChip('Flutter'),
                      _buildTechChip('Riverpod'),
                      _buildTechChip('Drift'),
                      _buildTechChip('MiniMax API'),
                      _buildTechChip('OpenAI API'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Footer
          Center(
            child: Text(
              'Made with ❤️ by whytrue',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '© 2024 Wisdom Quotes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.grey[200],
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
