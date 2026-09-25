import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'knowledge_screen.dart';
import 'bookmarks_screen.dart';
import 'tools_screen.dart';
import '../services/update_service.dart';
import '../services/whats_new_service.dart';
import '../widgets/update_dialog.dart';
import 'dashboard_screen.dart';

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
    // 延迟检查更新，避免影响启动速度
    Future.delayed(const Duration(seconds: 3), _checkUpdate);
  }

  Future<void> _checkUpdate() async {
    if (!mounted) return;
    final info = await UpdateService.checkForUpdate();
    if (!mounted || info == null) return;

    if (!context.mounted) return;
    final action = await UpdateDialog.show(context, info);
    if (!mounted || action == null) return;

    switch (action) {
      case UpdateAction.ignore:
        await UpdateService.ignoreVersion(info.version);
      case UpdateAction.permanentlyIgnore:
        await UpdateService.permanentlyIgnoreVersion(info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onOpenSection: (index) => setState(() => _currentIndex = index),
      ),
      const ChatScreen(),
      const KnowledgeScreen(),
      const BookmarksScreen(),
      const ToolsScreen(),
    ];
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(widget.textScaleFactor)),
      child: Scaffold(
        // IndexedStack 常驻各 Tab，切换后保留问诊/搜索等页面 State（如聊天进度、滚动位置）
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: '辨证',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_library_outlined),
              selectedIcon: Icon(Icons.local_library_rounded),
              label: '资料',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: '收藏',
            ),
            NavigationDestination(
              icon: Icon(Icons.apps_outlined),
              selectedIcon: Icon(Icons.apps_rounded),
              label: '工具',
            ),
          ],
        ),
      ),
    );
  }
}
