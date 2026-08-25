import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/collapsible_history_card.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/quick_add_sheet.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _api = FeatureService();
  final _input = TextEditingController();
  final _inputFocus = FocusNode();

  List<JournalEntry>? _entries;
  JournalEntry? _selected;
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;
  String? _error;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final result = await _api.get('captures?limit=100');
      if (!mounted) return;
      final raw = (result['captures'] as List?) ?? const [];
      final entries = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['type']?.toString() == 'journal')
          .map(JournalEntry.fromJson)
          .where((e) => e.text.isNotEmpty)
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final text = _input.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Write a short note first.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await _api.post('captures', {
        'type': 'journal',
        'payload': {'text': text},
      });
      if (!mounted) return;
      _input.clear();
      setState(() {
        _saving = false;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Journal entry saved.',
          ),
        ),
      );
      await _loadEntries();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _pop() => Navigator.pop(context, _changed);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _pop();
      },
      child: HarmoniousBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(_selected == null ? 'Journal' : 'Entry'),
            leading: IconButton(
              icon: Icon(
                _selected == null
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_back_rounded,
              ),
              onPressed: () {
                if (_selected != null) {
                  setState(() => _selected = null);
                  return;
                }
                _pop();
              },
            ),
          ),
          body: _selected != null
              ? _EntryDetail(entry: _selected!)
              : RefreshIndicator(
                  color: AppColors.cyanAccent,
                  onRefresh: _loadEntries,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      HarmoniousSpacing.screenHorizontal,
                      8,
                      HarmoniousSpacing.screenHorizontal,
                      32,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      const HarmoniousPageHeader(
                        icon: Icons.menu_book_outlined,
                        title: 'Journal',
                        iconColor: AppColors.sky,
                      ),
                      const SizedBox(height: 24),
                      const HarmoniousSectionHeader(
                        title: 'Write',
                      ),
                      const SizedBox(height: 12),
                      HarmoniousCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _input,
                              focusNode: _inputFocus,
                              enabled: !_saving,
                              maxLines: 5,
                              minLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.45),
                              decoration: InputDecoration(
                                hintText: 'What’s on your mind?',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textMuted),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.coral),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      HarmoniousGradientButton(
                        label: 'Save entry',
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                      const SizedBox(height: HarmoniousSpacing.sectionGap),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else if (_loadError != null)
                        HarmoniousCard(
                          child: HarmoniousEmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: 'Could not load history',
                            message: _loadError!,
                            actionLabel: 'Retry',
                            onAction: _loadEntries,
                            compact: true,
                          ),
                        )
                      else
                        CollapsibleHistoryCard(
                          itemCount: (_entries ?? const []).length,
                          emptyMessage:
                              'Your saved reflections will appear here after you write your first note.',
                          title: 'History',
                          itemBuilder: (context, i) {
                            final entry = _entries![i];
                            return _JournalHistoryTile(
                              entry: entry,
                              onTap: () => setState(() => _selected = entry),
                            );
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _JournalHistoryTile extends StatelessWidget {
  const _JournalHistoryTile({
    required this.entry,
    required this.onTap,
  });

  final JournalEntry entry;
  final VoidCallback onTap;

  String _preview(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 120) return compact;
    return '${compact.substring(0, 117)}…';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(
        DateFormat('EEE, MMM d · h:mm a').format(entry.capturedAt.toLocal()),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _preview(entry.text),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                height: 1.35,
              ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted.withValues(alpha: 0.85),
      ),
      onTap: onTap,
    );
  }
}

class _EntryDetail extends StatelessWidget {
  const _EntryDetail({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        HarmoniousSpacing.screenHorizontal,
        8,
        HarmoniousSpacing.screenHorizontal,
        32,
      ),
      child: HarmoniousCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DateFormat('EEEE, MMMM d · h:mm a')
                  .format(entry.capturedAt.toLocal()),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            Text(
              entry.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.55,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
