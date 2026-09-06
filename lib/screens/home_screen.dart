import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'knowledge_screen.dart';
import 'bookmarks_screen.dart';
import 'tools_screen.dart';
import '../services/whats_new_service.dart';
import '../services/license_service.dart';

class HomeScreen extends StatefulWidget {
  final double textScaleFactor;
  const HomeScreen({super.key, this.textScaleFactor = 1.0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 启动后弹出「本次更新了什么」（若有版本更新）
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) WhatsNewService.checkAndShow(context);
    });
    // 定制分发版不在启动时联网检查更新。
    Future.delayed(const Duration(milliseconds: 1200), _showExpiryReminder);
  }

  Future<void> _showExpiryReminder() async {
    if (!mounted) return;
    final license = await LicenseService.current();
    final days = license.remainingDays;
    if (!mounted || !license.isValid || days == null || days > 7) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.event_busy_outlined),
        content: Text(days == 0 ? '授权将于今日到期' : '授权将于 $days 天后到期'),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  final List<Widget> _screens = [
    const KnowledgeScreen(),
    const ToolsScreen(),
    const ChatScreen(),
    const BookmarksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(widget.textScaleFactor)),
      child: Scaffold(
        // IndexedStack 常驻各 Tab，切换后保留问诊/搜索等页面 State（如聊天进度、滚动位置）
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: '知识库',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build),
              label: '工具',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: '辨证',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: '收藏',
            ),
          ],
        ),
      ),
    );
  }
}
