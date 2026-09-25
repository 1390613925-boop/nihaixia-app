import 'package:flutter/material.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../engine/diagnostic_rules.dart';
import '../models/formula.dart';
import '../models/herb.dart';
import '../widgets/meridian_icons.dart';
import '../widgets/solar_term_card.dart';
import '../theme/app_colors.dart';
import 'acupuncture_screen.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';
import 'meridian_detail_screen.dart';
import 'neijing_knowledge_screen.dart';
import 'search_tab.dart';
import 'shanghan_jingui_screen.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('资料中心', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(
              '经方 · 本草 · 腧穴 · 经典',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerHeight: 0,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          tabs: const [
            Tab(text: '六经', icon: Icon(Icons.public)),
            Tab(text: '方剂', icon: Icon(Icons.medication)),
            Tab(text: '本草', icon: Icon(Icons.eco)),
            Tab(text: '针灸', icon: Icon(Icons.healing)),
            Tab(text: '内经', icon: Icon(Icons.menu_book)),
            Tab(text: '经典', icon: Icon(Icons.auto_stories)),
            Tab(text: '搜索', icon: Icon(Icons.search)),
          ],
        ),
      ),
      body: Column(
        children: [
          const SolarTermCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MeridianTab(),
                _FormulaTab(),
                _HerbTab(),
                const AcupunctureScreen(),
                const NeijingKnowledgeScreen(),
                const ShangHanJinguiScreen(),
                const SearchTab(),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    final formulas = _getFormulas();

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '搜索方剂名、适应证、药物组成...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        // 六经筛选
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _meridians.length,
            itemBuilder: (context, index) {
              final m = _meridians[index];
              final selected = m == _selectedMeridian;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(m, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMeridian = m),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
        // 分类筛选
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final c = _categories[index];
              final selected = c == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(c, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '共 ${formulas.length} 首方剂',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .92,
            ),
            itemCount: formulas.length,
            itemBuilder: (context, index) {
              final f = formulas[index];
              return Material(
                color: context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: context.colors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormulaDetailScreen(formula: f),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medication_liquid_outlined,
                              color: context.colors.primary,
                              size: 24,
                            ),
                            const Spacer(),
                            Icon(
                              Icons.north_east_rounded,
                              color: context.colors.onSurfaceVariant,
                              size: 17,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          f.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${f.meridian} · ${f.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          f.indication,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
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

  @override
  Widget build(BuildContext context) {
    final herbs = _getHerbs();
    final categories = HerbRepository.getCategories();
    final natures = HerbRepository.getNatureCategories();

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '搜索药名、功效、性味、分类...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        // Category filter
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final selected = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
        // Nature + Meridian filter
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: natures.length + _meridians.length,
            itemBuilder: (context, index) {
              if (index < natures.length) {
                final n = natures[index];
                final selected =
                    n == _selectedNature && _selectedMeridian == '全部';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(n, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedNature = n;
                      _selectedMeridian = '全部';
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              } else {
                final m = _meridians[index - natures.length];
                final selected = m == _selectedMeridian;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(m, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedMeridian = m;
                      _selectedNature = '全部';
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }
            },
          ),
        ),
        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '共 ${herbs.length} 味药',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        // Herb list
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .95,
            ),
            itemCount: herbs.length,
            itemBuilder: (context, index) {
              final h = herbs[index];
              final action = h.action ?? '';
              final actionShort = action.length > 40
                  ? '${action.substring(0, 40)}...'
                  : action;
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
                      builder: (_) => HerbDetailScreen(herb: h),
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
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: context.colors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                h.name.substring(0, 1),
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              h.natureIcon,
                              size: 18,
                              color: context.colors.primary,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          h.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${h.flavor.isNotEmpty ? "味${h.flavor} · " : ""}${h.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          actionShort,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
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
