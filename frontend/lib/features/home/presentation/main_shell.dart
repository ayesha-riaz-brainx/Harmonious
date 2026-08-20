import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/tabs/ai_tab.dart';
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
  final _aiKey = GlobalKey<AiTabState>();
  late final List<Widget> _pages;

  static const _tabs = [
    _NavItem('Today', Icons.home_outlined, Icons.home_rounded),
    _NavItem('AI', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
    _NavItem('Add', Icons.add_rounded, Icons.add_rounded),
    _NavItem(
      'Journey',
      Icons.insights_outlined,
      Icons.insights_rounded,
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
        onOpenChat: _openChat,
        onOpenAiTab: () {
          if (!mounted) return;
          setState(() => _index = 1);
        },
      ),
      AiTab(
        key: _aiKey,
        onDataChanged: _onDataChanged,
      ),
      const SizedBox.shrink(),
      JourneyTab(key: _journeyKey),
      const YouTab(),
    ];
  }

  Future<void> _onDataChanged({
    bool refreshAi = false,
    bool includeToday = true,
  }) async {
    // Never rebuild Journey/AI mid-capture — just mark dirty.
    _dirty = true;
    if (!mounted) return;
    if (includeToday) {
      await _todayKey.currentState?.reload(
        refreshAi: refreshAi,
        silent: true,
      );
    }
  }

  Future<void> _openChat() async {
    if (!mounted) return;
    setState(() => _index = 1);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _aiKey.currentState?.openChat();
  }

  void _toast(String message) {
    if (!mounted) return;
    // Defer snackbar so it never races overlay dispose.
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

      // Wait one more frame after tab switch before mutating Today.
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

  Future<void> _onTap(int index) async {
    if (index == 2) {
      final outcome = await showQuickCapture(context);
      if (!mounted || outcome == null) return;
      await _applyCapture(outcome);
      return;
    }

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
      await _aiKey.currentState?.reload();
    } else if (index == 3) {
      await _journeyKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyIndex = _index == 2 ? 0 : _index;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: bodyIndex,
        children: _pages,
      ),
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
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _tabs[i],
                      selected: _index == i,
                      isAdd: i == 2,
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.isAdd = false,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    if (isAdd) {
      return Semantics(
        button: true,
        label: 'Add',
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.cyanGradientStart,
                      AppColors.cyanGradientEnd,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: AppColors.onPrimaryButton,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primaryBright
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                  size: 23,
                  color: selected
                      ? AppColors.primaryBright
                      : AppColors.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
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
