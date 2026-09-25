import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/solar_term_card.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onOpenSection;

  const DashboardScreen({super.key, required this.onOpenSection});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('临证工作台'),
            actions: [
              IconButton(
                tooltip: '全库检索',
                onPressed: () => onOpenSection(2),
                icon: const Icon(Icons.search_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.list(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, const Color(0xFF173F5F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '辨证有序 · 典籍可查',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '从问诊到经方、本草与经典原文，集中在一个工作台。',
                        style: TextStyle(
                          color: colors.onPrimary.withValues(alpha: .82),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.surface,
                          foregroundColor: colors.primary,
                        ),
                        onPressed: () => onOpenSection(1),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('开始辨证'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const SolarTermCard(),
                const SizedBox(height: 22),
                const _SectionTitle(
                  title: '常用入口',
                  subtitle: '核心资料保持原样，仅重新组织入口',
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.42,
                  children: [
                    _EntryCard(
                      icon: Icons.medication_outlined,
                      title: '经方检索',
                      subtitle: '327 首方剂',
                      onTap: () => onOpenSection(2),
                    ),
                    _EntryCard(
                      icon: Icons.spa_outlined,
                      title: '本草查询',
                      subtitle: '465 味药材',
                      onTap: () => onOpenSection(2),
                    ),
                    _EntryCard(
                      icon: Icons.adjust_outlined,
                      title: '经络腧穴',
                      subtitle: '408 个穴位',
                      onTap: () => onOpenSection(2),
                    ),
                    _EntryCard(
                      icon: Icons.auto_stories_outlined,
                      title: '经典原文',
                      subtitle: '伤寒 · 金匮 · 内经',
                      onTap: () => onOpenSection(2),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionTitle(title: '个人工作区', subtitle: '快速回到常用内容'),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bookmark_outline_rounded),
                        title: const Text('收藏资料'),
                        subtitle: const Text('方剂、药材与阅读记录'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => onOpenSection(3),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.grid_view_rounded),
                        title: const Text('全部工具'),
                        subtitle: const Text('中医工具与传统文化资料分区'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => onOpenSection(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
      ),
    ],
  );
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.colors.primary, size: 27),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
