import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../data/database_helper.dart';
import '../engine/diagnostic_rules.dart';
import '../models/formula.dart';
import '../models/herb.dart';
import '../models/bookmark.dart';
import '../widgets/meridian_icons.dart';
import '../theme/app_colors.dart';
import 'acupuncture_screen.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';
import 'meridian_detail_screen.dart';
import 'neijing_knowledge_screen.dart';
import 'search_tab.dart';
import 'shanghan_jingui_screen.dart';

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  void _open(BuildContext context, String title, Widget child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries =
        <({String title, String subtitle, IconData icon, VoidCallback open})>[
          (
            title: '六经',
            subtitle: '辨证图谱',
            icon: Icons.hub_outlined,
            open: () => _open(context, '六经辨证', _MeridianTab()),
          ),
          (
            title: '方剂',
            subtitle: '327 首',
            icon: Icons.medication_outlined,
            open: () => _open(context, '方剂索引', _FormulaTab()),
          ),
          (
            title: '本草',
            subtitle: '465 味',
            icon: Icons.spa_outlined,
            open: () => _open(context, '本草索引', _HerbTab()),
          ),
          (
            title: '针灸',
            subtitle: '取穴与透针',
            icon: Icons.adjust_outlined,
            open: () => _open(context, '针灸检索', const AcupunctureScreen()),
          ),
          (
            title: '内经',
            subtitle: '脏象与诊法',
            icon: Icons.menu_book_outlined,
            open: () => _open(context, '内经索引', const NeijingKnowledgeScreen()),
          ),
          (
            title: '经典',
            subtitle: '伤寒与金匮',
            icon: Icons.auto_stories_outlined,
            open: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShangHanJinguiScreen()),
            ),
          ),
        ];
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('资料中心', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '分类索引与全库检索',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '全库搜索',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _open(context, '全库搜索', const SearchTab()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _open(context, '全库搜索', const SearchTab()),
            child: Ink(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: context.colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '搜索方剂、本草、穴位与经典',
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '分类浏览',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '选择资料类型进入检索或阅读',
            style: TextStyle(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.34,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              return Material(
                color: context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: context.colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: e.open,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              e.icon,
                              color: context.colors.primary,
                              size: 28,
                            ),
                            const Spacer(),
                            Icon(
                              Icons.north_east_rounded,
                              color: context.colors.onSurfaceVariant,
                              size: 18,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          e.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MeridianTab extends StatelessWidget {
  static const _meridianOrder = ['太阳', '阳明', '少阳', '太阴', '少阴', '厥阴'];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _LibraryIntro(
            icon: Icons.hub_outlined,
            eyebrow: 'SIX MERIDIANS',
            title: '六经辨证图谱',
            description: '按病位与阴阳层次浏览六经，点击进入脉证、治法与常用方剂。',
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Row(
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '太阳 → 阳明 → 少阳   ·   太阴 → 少阴 → 厥阴',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: .2,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .92,
            ),
            itemCount: _meridianOrder.length,
            itemBuilder: (context, index) {
              final name = _meridianOrder[index];
              final details = DiagnosticRules.meridianDetails[name]!;
              final color = context.colors.meridianColor(name);
              final formulas = details['formulas'] as List<String>;
              return Material(
                color: context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: context.colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeridianDetailScreen(meridian: name),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: context.colors.meridianContainer(name),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(meridianIcon(name), color: color),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.north_east_rounded,
                              size: 18,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '$name病',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${details['nature']} · ${details['organ']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${details['keyPulse']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1.35),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${formulas.length} 首常用方',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LibraryIntro extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  const _LibraryIntro({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.colors.primary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.colors.onPrimary.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: context.colors.onPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: context.colors.onPrimary.withValues(alpha: .68),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: context.colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: context.colors.onPrimary.withValues(alpha: .8),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FormulaTab extends StatefulWidget {
  @override
  State<_FormulaTab> createState() => _FormulaTabState();
}

class _FormulaTabState extends State<_FormulaTab> {
  String _selectedMeridian = '全部';
  String _selectedCategory = '全部';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _meridians = ['全部', '太阳', '阳明', '少阳', '太阴', '少阴', '厥阴'];

  static const _categories = [
    '全部',
    '金疮药',
    '倪海厦经验方',
    '解表剂',
    '和解剂',
    '清热剂',
    '泻下剂',
    '温里剂',
    '补益剂',
    '理气剂',
    '活血化瘀剂',
    '祛湿剂',
    '化痰剂',
    '寒热并用剂',
    '外用剂',
    '祛风剂',
    '安神剂',
    '止血剂',
    '驱虫剂',
  ];

  List<Formula> _getFormulas() {
    var list = FormulaRepository.getAll();
    if (_selectedMeridian != '全部') {
      list = list.where((f) => f.meridian.contains(_selectedMeridian)).toList();
    }
    if (_selectedCategory != '全部') {
      list = list.where((f) => f.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (f) =>
                f.name.toLowerCase().contains(q) ||
                f.indication.toLowerCase().contains(q) ||
                f.components.any((c) => c.name.toLowerCase().contains(q)) ||
                f.keywords.any((k) => k.toLowerCase().contains(q)),
          )
          .toList();
    }
    return list;
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '筛选方剂',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                const Text('六经', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _meridians
                      .map(
                        (m) => ChoiceChip(
                          label: Text(m),
                          selected: _selectedMeridian == m,
                          onSelected: (_) {
                            setState(() => _selectedMeridian = m);
                            setSheetState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text('分类', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _categories
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c),
                              selected: _selectedCategory == c,
                              onSelected: (_) {
                                setState(() => _selectedCategory = c);
                                setSheetState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formulas = _getFormulas();
    final filters = <String>[
      if (_selectedMeridian != '全部') _selectedMeridian,
      if (_selectedCategory != '全部') _selectedCategory,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: '搜索方名、主治或组成',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('筛选'),
                ),
              ),
            ],
          ),
        ),
        if (filters.isNotEmpty)
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text(f),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => setState(() {
                        if (f == _selectedMeridian) _selectedMeridian = '全部';
                        if (f == _selectedCategory) _selectedCategory = '全部';
                      }),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: Row(
            children: [
              Text(
                '${formulas.length} 首',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '方名 / 主治 / 组成',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: .5, color: context.colors.outlineVariant),
        Expanded(
          child: ListView.separated(
            itemCount: formulas.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: .5,
              indent: 16,
              endIndent: 16,
              color: context.colors.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final f = formulas[index];
              final components = f.components.map((c) => c.name).join('、');
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormulaDetailScreen(formula: f),
                  ),
                ),
                child: SizedBox(
                  height: 74,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                            Text(
                              f.meridian,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          f.indication,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          components,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HerbTab extends StatefulWidget {
  @override
  State<_HerbTab> createState() => _HerbTabState();
}

class _HerbTabState extends State<_HerbTab> {
  String _selectedCategory = '全部';
  String _selectedNature = '全部';
  String _selectedMeridian = '全部';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _meridians = [
    '全部',
    '肺',
    '心',
    '肝',
    '脾',
    '肾',
    '胃',
    '胆',
    '大肠',
    '小肠',
    '膀胱',
    '三焦',
  ];

  List<Herb> _getHerbs() {
    var herbs = HerbRepository.getAll();
    if (_selectedCategory != '全部') {
      herbs = herbs.where((h) => h.category == _selectedCategory).toList();
    }
    if (_selectedNature != '全部') {
      herbs = herbs.where((h) => h.natureCategory == _selectedNature).toList();
    }
    if (_selectedMeridian != '全部') {
      herbs = herbs
          .where((h) => h.meridians.contains(_selectedMeridian))
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      // 走 HerbRepository.matchesQuery（含异名归一）。
      // 此前此处自行拼字符串匹配，漏了 canonicalOf，导致 103 个异名中 74 个在此页搜不到
      //（例：茈胡 → 应命中柴胡）。禁止改回本地匹配。
      herbs = herbs
          .where((h) => HerbRepository.matchesQuery(h, _searchQuery))
          .toList();
    }
    return herbs;
  }

  final ScrollController _listController = ScrollController();

  String _letterOf(String name) {
    final pinyin = PinyinHelper.getFirstWordPinyin(name).trim();
    if (pinyin.isEmpty) return '#';
    final letter = pinyin[0].toUpperCase();
    return RegExp(r'[A-Z]').hasMatch(letter) ? letter : '#';
  }

  Color _natureColor(String nature) {
    switch (nature) {
      case '热':
        return const Color(0xFFC65F45);
      case '温':
        return const Color(0xFFC98452);
      case '寒':
        return const Color(0xFF456F9E);
      case '凉':
        return const Color(0xFF4E8FA2);
      default:
        return const Color(0xFF9A8968);
    }
  }

  Future<void> _showFilters() async {
    final categories = HerbRepository.getCategories();
    final natures = HerbRepository.getNatureCategories();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '筛选本草',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                const Text(
                  '寒热属性',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: natures
                      .map(
                        (n) => ChoiceChip(
                          label: Text(n),
                          selected: _selectedNature == n,
                          onSelected: (_) {
                            setState(() => _selectedNature = n);
                            setSheetState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                const Text('归经', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _meridians
                      .map(
                        (m) => ChoiceChip(
                          label: Text(m),
                          selected: _selectedMeridian == m,
                          onSelected: (_) {
                            setState(() => _selectedMeridian = m);
                            setSheetState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                const Text('分类', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: categories
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c),
                              selected: _selectedCategory == c,
                              onSelected: (_) {
                                setState(() => _selectedCategory = c);
                                setSheetState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _bookmark(Herb h) async {
    await DatabaseHelper.instance.insertBookmark(
      Bookmark(
        title: h.name,
        content: h.action ?? h.original ?? '',
        category: '本草',
        source: 'herb_detail',
      ),
    );
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已收藏 ${h.name}')));
  }

  void _jumpTo(String letter, List<Herb> herbs) {
    final index = herbs.indexWhere((h) => _letterOf(h.name) == letter);
    if (index >= 0 && _listController.hasClients) {
      _listController.animateTo(
        index * 64.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final herbs = [..._getHerbs()]
      ..sort(
        (a, b) => PinyinHelper.getPinyin(
          a.name,
        ).compareTo(PinyinHelper.getPinyin(b.name)),
      );
    final letters =
        herbs
            .map((h) => _letterOf(h.name))
            .toSet()
            .where((e) => e != '#')
            .toList()
          ..sort();
    final filters = <String>[
      if (_selectedNature != '全部') _selectedNature,
      if (_selectedMeridian != '全部') _selectedMeridian,
      if (_selectedCategory != '全部') _selectedCategory,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: '搜索药名、功效或性味',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('筛选'),
                ),
              ),
            ],
          ),
        ),
        if (filters.isNotEmpty)
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InputChip(
                      label: Text(f),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => setState(() {
                        if (f == _selectedNature) _selectedNature = '全部';
                        if (f == _selectedMeridian) _selectedMeridian = '全部';
                        if (f == _selectedCategory) _selectedCategory = '全部';
                      }),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 30, 6),
          child: Row(
            children: [
              Text(
                '${herbs.length} 味',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '左滑收藏',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: .5, color: context.colors.outlineVariant),
        Expanded(
          child: Stack(
            children: [
              ListView.separated(
                controller: _listController,
                padding: const EdgeInsets.only(right: 20),
                itemCount: herbs.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: .5,
                  indent: 20,
                  color: context.colors.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  final h = herbs[index];
                  final nature = h.natureCategory;
                  final meta = [
                    if (h.flavor.isNotEmpty) '味${h.flavor}',
                    if (h.meridians.isNotEmpty) '归${h.meridians.join('、')}',
                  ].join('，');
                  return Dismissible(
                    key: ValueKey('herb-${h.name}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await _bookmark(h);
                      return false;
                    },
                    background: Container(
                      color: context.colors.primary,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Icon(
                        Icons.bookmark_add_outlined,
                        color: context.colors.onPrimary,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HerbDetailScreen(herb: h),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 64,
                            color: _natureColor(nature),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    h.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  if (meta.isNotEmpty)
                                    Text(
                                      meta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                                  Text(
                                    h.action ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.onSurfaceVariant
                                          .withValues(alpha: .78),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 0,
                top: 4,
                bottom: 4,
                width: 20,
                child: LayoutBuilder(
                  builder: (context, constraints) => Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final l in letters)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _jumpTo(l, herbs),
                            child: Center(
                              child: Text(
                                l,
                                style: TextStyle(
                                  fontSize: letters.length > 20 ? 8 : 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
