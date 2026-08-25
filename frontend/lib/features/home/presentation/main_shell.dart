import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/tabs/health_tab.dart';
import 'package:slot_1_tasks/features/home/presentation/tabs/tools_tab.dart';
import 'package:slot_1_tasks/features/home/presentation/tabs/journey_tab.dart';
import 'package:slot_1_tasks/features/home/presentation/tabs/today_tab.dart';
import 'package:slot_1_tasks/features/home/presentation/tabs/you_tab.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/quick_add_sheet.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _dirty = false;
  final _todayKey = GlobalKey<TodayTabState>();
  final _journeyKey = GlobalKey<JourneyTabState>();
  final _toolsKey = GlobalKey<ToolsTabState>();
  final _healthKey = GlobalKey<HealthTabState>();
  late final List<Widget> _pages;

  /// Today · Tools · Journey · Health · You — Add is a floating FAB
  static const _tabs = [
    _NavItem('Today', Icons.home_outlined, Icons.home_rounded),
    _NavItem('Tools', Icons.spa_outlined, Icons.spa_rounded),
    _NavItem('Journey', Icons.show_chart_outlined, Icons.show_chart_rounded),
    _NavItem(
      'Health',
      Icons.favorite_outline_rounded,
      Icons.favorite_rounded,
    ),
    _NavItem('You', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      TodayTab(
        key: _todayKey,
        onDataChanged: _onDataChanged,
        onOpenToolsTab: () {
          if (!mounted) return;
          setState(() => _index = 1);
        },
      ),
      ToolsTab(
        key: _toolsKey,
        onDataChanged: _onDataChanged,
      ),
      JourneyTab(key: _journeyKey),
      HealthTab(key: _healthKey),
      const YouTab(),
    ];
  }

  Future<void> _onDataChanged({bool includeToday = true}) async {
    _dirty = true;
    if (!mounted) return;
    if (includeToday) {
      await _todayKey.currentState?.reload(silent: true);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  Future<void> _applyCapture(CaptureResult outcome) async {
    if (!mounted || !outcome.saved) {
      if (outcome.message != null) _toast(outcome.message!);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (_index != 0) {
        setState(() => _index = 0);
      }

      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      try {
        if (outcome.home != null) {
          _todayKey.currentState?.applyHome(outcome.home!);
        } else {
          await _todayKey.currentState?.reload(silent: true);
        }
      } catch (_) {
        await _todayKey.currentState?.reload(silent: true);
      }

      if (outcome.message != null) _toast(outcome.message!);
      _dirty = true;
    });
  }

  Future<void> _openAdd() async {
    final outcome = await showQuickCapture(context);
    if (!mounted || outcome == null) return;
    await _applyCapture(outcome);
  }

  Future<void> _onTap(int index) async {
    if (_dirty) {
      _dirty = false;
    }
    if (!mounted) return;
    setState(() => _index = index);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    if (index == 0) {
      await _todayKey.currentState?.reload(silent: true);
    } else if (index == 1) {
      await _toolsKey.currentState?.reload();
    } else if (index == 2) {
      await _journeyKey.currentState?.refresh();
    } else if (index == 3) {
      await _healthKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      floatingActionButton: _FloatingAddButton(onTap: _openAdd),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          border: const Border(
            top: BorderSide(color: AppColors.surfaceBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _tabs[i],
                      selected: _index == i,
                      onTap: () => _onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add',
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cyanGradientStart,
                  AppColors.cyanGradientEnd,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 30,
              color: AppColors.onPrimaryButton,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: selected
                      ? AppColors.primaryBright
                      : AppColors.textMuted,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryBright
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
