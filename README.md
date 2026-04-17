# Wisdom Quotes | 智慧名言

<div align="center">

![Downloads](https://img.shields.io/github/downloads/wangwhy133/wisdom_quotes/total?style=for-the-badge)
![Stars](https://img.shields.io/github/stars/wangwhy133/wisdom_quotes?style=for-the-badge)
![License](https://img.shields.io/github/license/wangwhy133/wisdom_quotes?style=for-the-badge)

**[English](#english) | [中文](#中文)**

</div>

---

## 📖 English

### About | 关于

**Wisdom Quotes (智慧名言)** is a Flutter application featuring **2000+** curated quotes in Chinese and English, covering investment wisdom, philosophy, poetry, and classic literature.

### Features | 功能

- 📚 **2000+ Quotes** — Chinese and English wisdom from investment masters, philosophers, poets
- 🌍 **Bilingual** — Full Chinese and English support
- 🤖 **AI Interpretation** — Powered by LLM for quote analysis (detail page)
- ✨ **AI Quote Generation** — Generate new quotes with AI (theme-based or random)
- 🌐 **Batch Translation** — Translate quotes between Chinese and English
- 💭 **My Thoughts (吾思)** — Write down your own quotes and ideas
- 📝 **Notes** — Add personal notes to any quote
- 📖 **Read Tracking** — Track viewed quotes, prioritize unread ones
- 🔔 **Daily Notifications** — Receive wisdom every day at scheduled time
- ⏰ **Alarm Clock** — Bilingual quote display when alarm rings (daily recurring)
- 📥 **Import/Export** — JSON format for personal quote collections
- 📂 **API Import** — Import quotes from external APIs (xygeng, zenoquotes, quotable, custom)
- ⭐ **Favorites** — Save your favorite quotes
- 🌓 **Dark Mode** — Support for dark theme (3-way cycle: light → dark → system)
- 📱 **Home Screen Widget** — Daily quote on your desktop
- 🎨 **Splash Screen** — Beautiful whytrue brand UI
- 🌐 **Dual API** — Auto-switch between domestic (CN) and international APIs

### Screenshots | 截图

| Home | Detail |
|:---:|:---:|
| ![Home](https://via.placeholder.com/300x600?text=Home+Screen) | ![Detail](https://via.placeholder.com/300x600?text=Quote+Detail) |

### Download | 下载

**Latest Release:** [v1.1.8](https://github.com/wangwhy133/wisdom_quotes/releases/tag/v1.1.8)

📦 APK Download: `app-release.apk` (61.8MB)

### Quote Sources | 名言来源

| Category | Examples |
|:---|:---|
| 💰 Investment Masters | Warren Buffett, Charlie Munger, George Soros, Peter Lynch, Ray Dalio |
| 🧠 Philosophy | Socrates, Marcus Aurelius, Epictetus, Seneca, Nietzsche |
| 📜 Chinese Classics | Laozi (道德经), Confucius (论语), Zengzi (大学) |
| ✍️ Literature | Shakespeare, Victor Hugo, Tolstoy, Camus, Van Gogh |
| 💡 Modern Wisdom | Steve Jobs, Albert Einstein, Mark Twain, Nelson Mandela |

### Quote Files | 名言文件

Download quote collections from GitHub:

| File | Quotes | Description |
|:---|:---:|:---|
| 📄 [quotes_cn.json](https://raw.githubusercontent.com/wangwhy133/wisdom_quotes/main/assets/quotes_cn.json) | 2000+ | Chinese Quotes 名言合集 |
| 📄 [quotes_en.json](https://raw.githubusercontent.com/wangwhy133/wisdom_quotes/main/assets/quotes_en.json) | 270 | English Quotes 英文名言 |

### API Support | API 支持

- **MiniMax** — Recommended | 推荐
- **OpenAI** — GPT-3.5/GPT-4
- **Claude** — Claude 3
- Custom OpenAI-compatible endpoints | 自定义接入

### Tech Stack | 技术栈

- Flutter 3.41+
- Drift + Riverpod (State Management)
- flutter_local_notifications
- OpenAI / MiniMax API

### Build | 编译

```bash
flutter pub get
flutter build apk --release
```

### Changelog | 更新日志

#### v1.3.12
- **AlarmNotificationReceiver 增加详细日志**：方便排查通知触发状态
- 添加 `setFullScreenIntent` 和 `VISIBILITY_PUBLIC` 提升通知可见性

#### v1.3.11
- **测试推送改为 10 秒后触发**：新建 `scheduleTestNotification()` 方法，不再推到明天的固定时间点
- **测试闹钟改为当前时间 +1 分钟**：避免触发时间已过被系统跳过

#### v1.3.10
- **改用 `setExactAndAllowWhileIdle`**：替代 `setAlarmClock`，提升通知可靠性
- **测试场景 5 秒后触发**：避免 `triggerAtMillis` 已过导致通知被系统隐藏
- **通知 ID 改为 1**：避免 ID=0 被系统其他通知占用
- 新课程 ID `daily_quote_v2`：强制创建新课程避免旧缓存影响

#### v1.3.9
- **Android 13+ 运行时通知权限**：MainActivity 启动时主动申请 `POST_NOTIFICATIONS` 权限
- 权限被拒绝时自动跳转设置页面引导用户开启

#### v1.3.8
- **alarm_service.dart 改用原生 AlarmManager**：闹钟调度彻底抛弃 flutter_local_notifications，避免 `Missing type parameter` 崩溃
- 推送和闹钟均使用同一套原生方案

#### v1.3.7
- **完全绕过 flutter_local_notifications**：改用 Android 原生 AlarmManager API，彻底摆脱插件缓存损坏导致的崩溃
- **AlarmNotificationReceiver**：Kotlin 广播接收器，支持每天自动重排
- **BootReceiver**：设备重启后自动重新调度已保存的每日通知

#### v1.3.5
- **ClearPluginCacheApp**：Android Application 子类，在 Flutter 引擎启动前清理插件损坏的 SharedPreferences 缓存
- ⚠️ 修改 Application 类后必须卸载重装才能生效

#### v1.3.4
- 增加 try-catch 保护 `cancel`/`cancelAll` 调用，防止缓存损坏导致的崩溃扩散

#### v1.3.3
- 设置页面新增「立即测试推送」和「立即测试闹钟」按钮，支持即时验证

#### v1.3.2
- **LogService 防崩溃**：初始化前使用 noop logger 防止空指针
- **ERROR 日志同步写文件**：崩溃时写 `.crash` 文件
- **scheduleDaily/scheduleAlarm 加 try-catch**：隔离插件异常

#### v1.3.0
- **修复首次启动闪退**：将 Splash Screen 中废弃的 `AnimatedBuilder` 替换为 `ListenableBuilder`（Flutter 3.16+）

#### v1.2.8
- 全面日志覆盖升级，所有运行数据均记录到日志

#### v1.2.7
- 首版正式发布

#### v1.2.6
- 新增自定义 endpoint 配置功能，支持用户指定完整 API 地址

#### v1.2.5
- 修复智谱 glm-4-flash 模型 `reasoning_content` 字段解析问题
- 修复双重版本前缀问题（`_cleanBaseUrl` 不再错误删除 `/v4`）

#### v1.2.3
- 修复 `_cleanBaseUrl` 错误剥离 Zhipu `/v4` 前缀导致路径不匹配
- 确认 baipiao 代理返回空 content 为多提供商架构共性缺陷

#### v1.2.1
- 修复 `_cleanBaseUrl` 未剥离版本前缀导致 URL 双重版本号问题

#### v1.1.8
- **Android:** 注册 flutter_local_notifications 必需的 Boot Receiver（重启后闹钟/通知自动恢复）
- 闹钟和通知均使用 `exactAllowWhileIdle` 准时模式

#### v1.1.7
- 修复 `requestExactAlarmsPermission` API 方法名
- 修复 `fetchModels`/`interpretQuote` 中 response 空值访问

#### v1.1.6
- 修复智谱等第三方 API 端点兼容（`_cleanBaseUrl` 不再删除版本路径）
- 通知调度改为 `exactAllowWhileIdle` 精确模式

### License | 许可证

MIT License

---

## 中文

### 关于

**智慧名言** 是一款 Flutter 应用，收录 **2000+** 条中英文精选名言，涵盖投资智慧、哲学思辨、诗词歌赋、经典名著。

### 功能

- 📚 **2000+ 名言** — 来自投资大师、哲学家、诗人、经典著作
- 🌍 **中英双语** — 完整的中英文支持
- 🤖 **AI 解读** — LLM 驱动名言解析（详情页）
- ✨ **AI 名言生成** — 使用AI生成新的名言警句（主题生成或随机生成）
- 🌐 **批量翻译** — 中英文双向翻译
- 💭 **吾思** — 记录你的想法与名言
- 📝 **笔记** — 为任意名言添加笔记
- 📖 **阅读追踪** — 记录已看过的名言，未读优先推荐
- 🔔 **每日推送** — 每天定时接收智慧语录
- ⏰ **闹钟双语播报** — 闹钟响起时双语显示名言（每日循环）
- 📥 **导入导出** — JSON 格式个人名言库
- 📂 **API 导入** — 从外部 API 导入名言（句野、ZenQuotes、Quotable、自定义）
- ⭐ **收藏功能** — 保存喜爱名言
- 🌓 **暗黑模式** — 支持深色主题（3档循环：浅色→深色→系统）
- 📱 **桌面小组件** — 桌面显示每日名言
- 🎨 **启动页** — whytrue 品牌 UI 设计
- 🌐 **双线路API** — 国内/国际API自动切换

### 下载

**最新版本：** [v1.1.8](https://github.com/wangwhy133/wisdom_quotes/releases/tag/v1.1.8)

📦 APK 下载: `app-release.apk` (61.8MB)

### 名言来源

| 分类 | 代表人物 |
|:---|:---|
| 💰 投资大师 | 巴菲特、芒格、索罗斯、彼得·林奇、达里奥 |
| 🧠 哲学智慧 | 苏格拉底、马可·奥勒留、爱比克泰德、塞涅卡、尼采 |
| 📜 中华经典 | 老子（道德经）、孔子（论语）、曾子（大学） |
| ✍️ 文学名著 | 莎士比亚、雨果、托尔斯泰、加缪、梵高 |
| 💡 现代智慧 | 乔布斯、爱因斯坦、马克·吐温、曼德拉 |

### 名言文件

从 GitHub 下载名言集：

| 文件 | 数量 | 说明 |
|:---|:---:|:---|
| 📄 [quotes_cn.json](https://raw.githubusercontent.com/wangwhy133/wisdom_quotes/main/assets/quotes_cn.json) | 2000+ | 中文名言合集 |
| 📄 [quotes_en.json](https://raw.githubusercontent.com/wangwhy133/wisdom_quotes/main/assets/quotes_en.json) | 270 | 英文名言合集 |

### API 支持

- **MiniMax** — 推荐使用
- **OpenAI** — GPT-3.5/GPT-4
- **Claude** — Claude 3
- 支持自定义 OpenAI 兼容端点

### 技术栈

- Flutter 3.41+
- Drift + Riverpod (状态管理)
- flutter_local_notifications
- OpenAI / MiniMax API

### 编译

```bash
flutter pub get
flutter build apk --release
```

### 许可证

MIT License

---

<p align="center">

⭐ Star this repo if you like it!

</p>
