import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/providers.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/translation_service.dart';
import '../services/log_service.dart';

import '../services/alarm_service.dart';
import 'model_providers_screen.dart';
import 'ai_generate_screen.dart';
import 'my_thoughts_screen.dart';
import 'notes_screen.dart';
import 'about_screen.dart';
import 'logs_screen.dart';
import 'quote_apis_screen.dart';

final _log = LogService()['Settings'];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifEnabled = false;
  int _hour = 8;
  int _minute = 0;
  bool _loading = true;
  bool _isImporting = false;
  bool _isExporting = false;

  // Alarm config
  bool _alarmEnabled = false;
  int _alarmHour = 7;
  int _alarmMinute = 0;

  // Font config
  String _selectedFont = 'Default';

  static const List<String> _availableFonts = ['Default', 'Serif', 'Monospace', 'Cursive', 'Fantasy'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifEnabled = prefs.getBool('notif_enabled') ?? false;
      _hour = prefs.getInt('notif_hour') ?? 8;
      _minute = prefs.getInt('notif_minute') ?? 0;
      _alarmEnabled = prefs.getBool('alarm_enabled') ?? false;
      _alarmHour = prefs.getInt('alarm_hour') ?? 7;
      _alarmMinute = prefs.getInt('alarm_minute') ?? 0;
      _selectedFont = prefs.getString('quote_font') ?? 'Default';
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', _notifEnabled);
    await prefs.setInt('notif_hour', _hour);
    await prefs.setInt('notif_minute', _minute);
    await prefs.setBool('alarm_enabled', _alarmEnabled);
    await prefs.setInt('alarm_hour', _alarmHour);
    await prefs.setInt('alarm_minute', _alarmMinute);
    await prefs.setString('quote_font', _selectedFont);
  }

  Future<void> _toggleNotification(bool value) async {
    _log.debug('[settings] _toggleNotification($value) hour=$_hour minute=$_minute');
    if (value) {
      // Bug 1 fix: check notification permission before enabling
      final hasPermission = await PermissionService.hasNotificationPermission();
      if (!hasPermission) {
        _log.warning('[settings] 通知权限未授权');
        if (!mounted) return;
        await PermissionService.showSettingsDialog(context);
        await _loadSettings();
        return;
      }
    }

    setState(() => _notifEnabled = value);
    await _saveSettings();
    if (value) {
      final notifService = NotificationService();
      await notifService.initialize();
      final db = ref.read(databaseProvider);
      final quote = await db.getRandomQuote();
      if (quote != null) {
        _log.info('[settings] 开启每日通知 hour=$_hour minute=$_minute quote=${quote.content.substring(0, quote.content.length < 20 ? quote.content.length : 20)}...');
        try {
          await notifService.scheduleDaily(hour: _hour, minute: _minute, quote: quote);
        } catch (e, st) {
          _log.error('[settings] scheduleDaily失败: $e', e, st);
        }
      } else {
        _log.warning('[settings] 每日通知无可用名言');
      }
    } else {
      _log.info('[settings] 关闭每日通知');
      try {
        await NotificationService().cancelAll();
      } catch (e, st) {
        _log.error('[settings] cancelAll失败', e, st);
      }
    }
  }

  Future<void> _toggleAlarm(bool value) async {
    _log.debug('[settings] _toggleAlarm($value) hour=$_alarmHour minute=$_alarmMinute');
    if (value) {
      // Bug 1 fix: check exact alarm permission before enabling
      final hasPermission = await PermissionService.hasExactAlarmPermission();
      if (!hasPermission) {
        _log.warning('[settings] 精确闹钟权限未授权');
        if (!mounted) return;
        await PermissionService.showSettingsDialog(context);
        await _loadSettings();
        return;
      }
    }

    setState(() => _alarmEnabled = value);
    await _saveSettings();
    if (value) {
      final alarmService = AlarmService();
      await alarmService.initialize();
      final db = ref.read(databaseProvider);
      final quote = await db.getRandomQuote();
      if (quote != null) {
        final translator = TranslationService();
        String? translated;
        final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(quote.content);
        translated = isChinese ? await translator.zhToEn(quote.content) : await translator.enToZh(quote.content);
        _log.info('[settings] 开启闹钟 hour=$_alarmHour minute=$_alarmMinute quote=${quote.content.substring(0, quote.content.length < 20 ? quote.content.length : 20)}...');
        try {
          await alarmService.scheduleAlarm(id: AlarmService.dailyAlarmId, hour: _alarmHour, minute: _alarmMinute, quote: quote, translatedContent: translated);
        } catch (e, st) {
          _log.error('[settings] scheduleAlarm失败: $e', e, st);
        }
      } else {
        _log.warning('[settings] 闹钟无可用名言');
      }
    } else {
      _log.info('[settings] 关闭闹钟');
      try {
        await AlarmService().cancelAlarm(AlarmService.dailyAlarmId);
      } catch (e, st) {
        _log.error('[settings] cancelAlarm失败', e, st);
      }
    }
  }

  Future<void> _selectTime({bool isAlarm = false}) async {
    final initial = isAlarm ? TimeOfDay(hour: _alarmHour, minute: _alarmMinute) : TimeOfDay(hour: _hour, minute: _minute);
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isAlarm) { _alarmHour = picked.hour; _alarmMinute = picked.minute; }
        else { _hour = picked.hour; _minute = picked.minute; }
      });
      await _saveSettings();
    }
  }

  Future<void> _exportQuotes() async {
    setState(() => _isExporting = true);
    try {
      final db = ref.read(databaseProvider);
      final data = await db.exportQuotes();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wisdom_quotes_export.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], subject: '智慧名言导出');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出 ${data.length} 条名言')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
    setState(() => _isExporting = false);
  }

  Future<void> _importQuotes() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final List<dynamic> data = json.decode(content);
        final db = ref.read(databaseProvider);
        await db.importQuotes(data.cast<Map<String, dynamic>>());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入 ${data.length} 条名言')));
          ref.invalidate(allQuotesProvider);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
    setState(() => _isImporting = false);
  }

  Future<void> _importBundledQuotes(String assetPath, String name) async {
    setState(() => _isImporting = true);
    try {
      final data = await DefaultAssetBundle.of(context).loadString(assetPath);
      final List<dynamic> jsonData = json.decode(data);
      final db = ref.read(databaseProvider);
      await db.importQuotes(jsonData.cast<Map<String, dynamic>>());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入${name} ${jsonData.length} 条名言')));
        ref.invalidate(allQuotesProvider);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
    setState(() => _isImporting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('设置')), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('每日推送'),
          SwitchListTile(title: const Text('开启每日名言推送'), subtitle: const Text('每天固定时间推送一条名言'), value: _notifEnabled, onChanged: _toggleNotification),
          if (_notifEnabled)
            ListTile(
              title: const Text('推送时间'),
              subtitle: Text('${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectTime(),
            ),
          ListTile(
            leading: const Icon(Icons.send, color: Colors.green),
            title: const Text('立即测试推送'),
            subtitle: const Text('立刻发送一条测试通知（不等定时）'),
            onTap: () async {
              _log.debug('[settings] 测试推送开始');
              try {
                final notifService = NotificationService();
                await notifService.initialize();
                final db = ref.read(databaseProvider);
                final quote = await db.getRandomQuote();
                if (quote != null) {
                  await notifService.scheduleDaily(hour: DateTime.now().hour, minute: DateTime.now().minute + 1, quote: quote);
                  _log.info('[settings] 测试推送已发送');
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('测试推送已发送！请注意通知栏')));
                }
              } catch (e, st) {
                _log.error('[settings] 测试推送失败', e, st);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('测试推送失败: $e')));
              }
            },
          ),
          const Divider(),
          _buildSectionHeader('闹钟功能'),
          SwitchListTile(title: const Text('开启名言闹钟'), subtitle: const Text('闹钟响起时显示双语名言'), value: _alarmEnabled, onChanged: _toggleAlarm),
          if (_alarmEnabled)
            ListTile(
              title: const Text('闹钟时间'),
              subtitle: Text('${_alarmHour.toString().padLeft(2, '0')}:${_alarmMinute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectTime(isAlarm: true),
            ),
          ListTile(
            leading: const Icon(Icons.alarm, color: Colors.orange),
            title: const Text('立即测试闹钟'),
            subtitle: const Text('立刻响一次闹钟（不等定时）'),
            onTap: () async {
              _log.debug('[settings] 测试闹钟开始');
              try {
                final alarmService = AlarmService();
                await alarmService.initialize();
                final db = ref.read(databaseProvider);
                final quote = await db.getRandomQuote();
                if (quote != null) {
                  await alarmService.scheduleAlarm(id: 9999, hour: DateTime.now().hour, minute: DateTime.now().minute + 1, quote: quote, translatedContent: null);
                  _log.info('[settings] 测试闹钟已发送 id=9999');
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('测试闹钟已设置！1分钟后响铃')));
                }
              } catch (e, st) {
                _log.error('[settings] 测试闹钟失败', e, st);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('测试闹钟失败: $e')));
              }
            },
          ),
          const Divider(),
          _buildSectionHeader('AI功能'),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.purple),
            title: const Text('AI 名言生成'),
            subtitle: const Text('使用AI生成新的名言'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiGenerateScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.indigo),
            title: const Text('吾思'),
            subtitle: const Text('记录你的想法与名言'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyThoughtsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.note_alt, color: Colors.orange),
            title: const Text('我的笔记'),
            subtitle: const Text('查看所有笔记与对应名言'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('管理模型提供商'),
            subtitle: const Text('添加、编辑、删除AI模型接口'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelProvidersScreen())),
          ),
          const Divider(),
          _buildSectionHeader('名言API'),
          ListTile(
            leading: const Icon(Icons.api, color: Colors.green),
            title: const Text('管理名言API'),
            subtitle: const Text('添加、测试、切换名言数据源'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteApisScreen())),
          ),
          const Divider(),
          _buildSectionHeader('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.teal),
            title: const Text('关于智慧名言'),
            subtitle: const Text('版本信息、GitHub仓库'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          const Divider(),
          _buildSectionHeader('显示设置'),
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeProvider);
              // Bug 20 fix: allow choosing light/dark/system instead of just dark/light toggle
              return ListTile(
                leading: Icon(
                  themeMode == ThemeMode.dark ? Icons.dark_mode
                    : themeMode == ThemeMode.light ? Icons.light_mode
                    : Icons.brightness_auto,
                  color: themeMode == ThemeMode.dark ? Colors.indigo
                      : themeMode == ThemeMode.light ? Colors.orange
                      : Colors.grey,
                ),
                title: const Text('主题模式'),
                subtitle: Text(
                  themeMode == ThemeMode.dark ? '暗黑模式'
                    : themeMode == ThemeMode.light ? '浅色模式'
                    : '跟随系统',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(context, ref),
              );
            },
          ),
          ListTile(
            title: const Text('名言字体'),
            subtitle: Text(_selectedFont),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showFontPicker,
          ),
          const Divider(),
          _buildSectionHeader('导入内置名言库'),
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.green),
            title: const Text('导入中文名言'),
            subtitle: const Text('经典名著、诗词、投资名言 · 35条'),
            trailing: _isImporting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
            onTap: _isImporting ? null : () => _importBundledQuotes('assets/quotes_cn.json', '中文名言'),
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.blue),
            title: const Text('导入英文名言'),
            subtitle: const Text('经典语录、投资名言 · 35条'),
            trailing: _isImporting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
            onTap: _isImporting ? null : () => _importBundledQuotes('assets/quotes_en.json', '英文名言'),
          ),
          const Divider(),
          _buildSectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('导入自定义JSON'),
            subtitle: const Text('从文件导入自己的名言库'),
            trailing: _isImporting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
            onTap: _isImporting ? null : _importQuotes,
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('导出名言'),
            subtitle: const Text('导出为JSON文件备份'),
            trailing: _isExporting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : _exportQuotes,
          ),
          const Divider(),
          _buildSectionHeader('系统信息'), // Bug 19 fix: was duplicate '关于'
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('运行日志'),
            subtitle: const Text('查看近7天运行日志（用于排查问题）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen()));
            },
          ),
          const ListTile(title: Text('版本'), subtitle: const Text('v1.2.7')), // Bug 18 fix
          ListTile(
            title: const Text('名言总数'),
            subtitle: ref.watch(allQuotesProvider).when(
              data: (quotes) => Text('${quotes.length} 条'),
              loading: () => const Text('加载中...'),
              error: (_, __) => const Text('无法加载'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFontPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: _availableFonts.length,
        itemBuilder: (ctx, i) {
          final font = _availableFonts[i];
          return ListTile(
            title: Text(font, style: _getFontStyle(font)),
            trailing: font == _selectedFont ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              setState(() => _selectedFont = font);
              _saveSettings();
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  // Bug 20 fix: theme picker (light / dark / system)
  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto, color: Colors.grey),
            title: const Text('跟随系统'),
            subtitle: const Text('根据系统设置自动切换'),
            trailing: ref.read(themeProvider) == ThemeMode.system
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.light_mode, color: Colors.orange),
            title: const Text('浅色模式'),
            subtitle: const Text('始终使用浅色主题'),
            trailing: ref.read(themeProvider) == ThemeMode.light
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.indigo),
            title: const Text('暗黑模式'),
            subtitle: const Text('始终使用深色主题'),
            trailing: ref.read(themeProvider) == ThemeMode.dark
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  TextStyle _getFontStyle(String font) {
    switch (font) {
      case 'Serif': return const TextStyle(fontFamily: 'serif');
      case 'Monospace': return const TextStyle(fontFamily: 'monospace');
      case 'Cursive': return const TextStyle(fontFamily: 'cursive');
      case 'Fantasy': return const TextStyle(fontFamily: 'fantasy');
      default: return const TextStyle();
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600])),
    );
  }
}
