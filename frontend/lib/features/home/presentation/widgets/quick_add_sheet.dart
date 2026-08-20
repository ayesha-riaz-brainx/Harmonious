import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/core/theme/app_theme.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/journal_page.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

enum QuickAddAction {
  meal,
  water,
  weight,
  workout,
  mood,
  sleep,
  journal,
}

class CaptureResult {
  const CaptureResult({
    required this.saved,
    this.message,
    this.home,
    this.loggedMood,
  });

  final bool saved;
  final String? message;
  final Map<String, dynamic>? home;
  final String? loggedMood;
}

class FoodSearchResult {
  const FoodSearchResult({
    required this.id,
    required this.name,
    this.brand,
    this.kcalPer100g,
    this.kcalPerServing,
    this.servingSize,
    this.servingUnit,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? 'Unknown food',
      brand: json['brand'] as String?,
      kcalPer100g: (json['kcal_per_100g'] as num?)?.toInt(),
      kcalPerServing: (json['kcal_per_serving'] as num?)?.toInt(),
      servingSize: (json['serving_size'] as num?)?.toDouble(),
      servingUnit: json['serving_unit'] as String?,
    );
  }

  final int id;
  final String name;
  final String? brand;
  final int? kcalPer100g;
  final int? kcalPerServing;
  final double? servingSize;
  final String? servingUnit;

  int? get preferredKcal => kcalPerServing ?? kcalPer100g;

  String get servingLabel {
    if (kcalPerServing != null &&
        servingSize != null &&
        servingUnit != null &&
        servingSize! > 0) {
      return '$kcalPerServing kcal per ${servingSize!.toStringAsFixed(servingSize! % 1 == 0 ? 0 : 1)} $servingUnit';
    }
    if (kcalPer100g != null) return '$kcalPer100g kcal per 100 g';
    return 'Calories unavailable';
  }
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.text,
    required this.capturedAt,
  });

  final String id;
  final String text;
  final DateTime capturedAt;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : <String, dynamic>{};
    final raw = json['captured_at']?.toString();
    return JournalEntry(
      id: json['id']?.toString() ?? '',
      text: (payload['text'] ?? '').toString().trim(),
      capturedAt: raw != null ? DateTime.tryParse(raw) ?? DateTime.now() : DateTime.now(),
    );
  }
}

/// Opens one bottom sheet that owns the full capture flow (pick → form → save).
/// Avoids nested dialogs that caused `_dependents.isEmpty` crashes.
Future<CaptureResult?> showQuickCapture(
  BuildContext context, {
  QuickAddAction? action,
}) {
  return showModalBottomSheet<CaptureResult>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _QuickCaptureSheet(initialAction: action),
  );
}

/// Legacy entry — opens the unified capture sheet (picker).
Future<CaptureResult?> showQuickAddSheet(BuildContext context) {
  return showQuickCapture(context);
}

/// Opens journal history in a single sheet (list → detail), no nested dialogs.
Future<void> showJournalHistorySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _JournalHistorySheet(),
  );
}

class QuickCaptureFlow {
  QuickCaptureFlow(this.context, {FeatureService? api});

  final BuildContext context;

  /// Opens the unified capture sheet. Optional [action] skips the picker.
  /// Journal opens the dedicated page instead of a bottom sheet.
  Future<CaptureResult> run([QuickAddAction? action]) async {
    if (action == QuickAddAction.journal) {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const JournalPage()),
      );
      if (!context.mounted) {
        return CaptureResult(saved: changed == true);
      }
      return CaptureResult(
        saved: changed == true,
        message: changed == true ? 'Journal entry saved.' : null,
      );
    }
    final result = await showQuickCapture(context, action: action);
    return result ?? const CaptureResult(saved: false);
  }
}

class _QuickCaptureSheet extends StatefulWidget {
  const _QuickCaptureSheet({this.initialAction});

  final QuickAddAction? initialAction;

  @override
  State<_QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<_QuickCaptureSheet> {
  final _api = FeatureService();
  final _input = TextEditingController();
  final _foodQuery = TextEditingController();

  QuickAddAction? _action;
  bool _saving = false;
  bool _journalHistoryMode = false;
  bool _mealManualEntry = false;
  bool _foodSearchLoading = false;
  JournalEntry? _selectedJournal;
  List<JournalEntry>? _journals;
  List<FoodSearchResult>? _foodResults;
  FoodSearchResult? _selectedFood;
  bool _journalsLoading = false;
  String? _journalsError;
  String? _foodSearchError;
  String? _foodSearchErrorKind;
  String? _error;
  String? _mealName;

  static const _actions = <(QuickAddAction, IconData, String, String, Color)>[
    (QuickAddAction.meal, Icons.restaurant_rounded, 'Log Meal', 'Food & calories', AppColors.amber),
    (QuickAddAction.water, Icons.water_drop_rounded, 'Log Drink', 'Water & beverages', AppColors.sky),
    (QuickAddAction.weight, Icons.monitor_weight_outlined, 'Log Weight', 'kg', AppColors.aqua),
    (QuickAddAction.workout, Icons.fitness_center_rounded, 'Log Workout', 'Minutes', AppColors.coral),
    (QuickAddAction.mood, Icons.mood_rounded, 'Log Mood', 'How you feel', AppColors.mint),
    (QuickAddAction.sleep, Icons.bedtime_rounded, 'Log Sleep', 'Hours', AppColors.lavender),
    (QuickAddAction.journal, Icons.edit_note_rounded, 'Journal', 'Reflection', AppColors.sky),
  ];

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction;
    _seedInput(_action);
  }

  @override
  void dispose() {
    _input.dispose();
    _foodQuery.dispose();
    super.dispose();
  }

  void _seedInput(QuickAddAction? action) {
    _input.clear();
    _mealName = null;
    _mealManualEntry = false;
    _selectedFood = null;
    _foodResults = null;
    _foodSearchError = null;
    _foodSearchErrorKind = null;
    _foodQuery.clear();
    if (action == QuickAddAction.meal) {
      _input.text = '';
    } else if (action == QuickAddAction.sleep) {
      _input.text = '8';
    }
  }

  void _pick(QuickAddAction action) {
    if (action == QuickAddAction.journal) {
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.pop(const CaptureResult(saved: false));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.push(
          MaterialPageRoute<bool>(builder: (_) => const JournalPage()),
        );
      });
      return;
    }
    setState(() {
      _action = action;
      _error = null;
      _journalHistoryMode = false;
      _selectedJournal = null;
      _seedInput(action);
    });
  }

  void _back() {
    if (_action == QuickAddAction.journal && _selectedJournal != null) {
      setState(() {
        _selectedJournal = null;
        _error = null;
      });
      return;
    }

    if (_action == QuickAddAction.journal && _journalHistoryMode) {
      setState(() {
        _journalHistoryMode = false;
        _selectedJournal = null;
        _error = null;
      });
      return;
    }

    // Opened from a Today CTA → dismiss.
    if (widget.initialAction != null) {
      _close(const CaptureResult(saved: false));
      return;
    }

    setState(() {
      _action = null;
      _error = null;
      _journalHistoryMode = false;
      _selectedJournal = null;
      _input.clear();
    });
  }

  void _close(CaptureResult result) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context, rootNavigator: true).pop(result);
  }

  Future<void> _openJournalHistory() async {
    setState(() {
      _journalHistoryMode = true;
      _selectedJournal = null;
      _error = null;
    });
    await _loadJournals();
  }

  Future<void> _loadJournals() async {
    setState(() {
      _journalsLoading = true;
      _journalsError = null;
    });
    try {
      final result = await _api.get('captures?limit=100');
      if (!mounted) return;
      final raw = (result['captures'] as List?) ?? const [];
      final journals = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['type']?.toString() == 'journal')
          .map(JournalEntry.fromJson)
          .where((e) => e.text.isNotEmpty)
          .toList();
      setState(() {
        _journals = journals;
        _journalsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _journalsLoading = false;
        _journalsError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _savePayload(String type, Map<String, dynamic> payload) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await _api.post('captures', {
        'type': type,
        'payload': payload,
      });
      if (!mounted) return;
      final home = result['home'] is Map
          ? Map<String, dynamic>.from(result['home'] as Map)
          : null;
      _close(
        CaptureResult(
          saved: true,
          message: result['message']?.toString() ?? 'Saved.',
          home: home,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _saveNumber({
    required String type,
    required String field,
    String? name,
    bool requirePositive = false,
    double? maxValue,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final raw = _input.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value < 0) {
      setState(() => _error = 'Enter a valid number.');
      return;
    }
    if (requirePositive && value <= 0) {
      setState(() => _error = 'Enter a value greater than 0.');
      return;
    }
    if (maxValue != null && value > maxValue) {
      setState(() => _error = 'Enter a value up to $maxValue.');
      return;
    }
    final payload = <String, dynamic>{
      field: field == 'calories' ? value.round() : value,
    };
    if (name != null) payload['name'] = name;
    await _savePayload(type, payload);
  }

  String _friendlyFoodSearchError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    final lower = message.toLowerCase();
    if (lower.contains('not configured') ||
        lower.contains('not available') ||
        lower.contains('usda_fdc') ||
        lower.contains('temporarily unavailable')) {
      return 'Food search is not set up on the server. Enter calories manually below.';
    }
    if (lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('socket') ||
        lower.contains('failed host lookup')) {
      return 'Could not reach the food database. Check your connection and try again.';
    }
    if (lower.contains('unexpected token') ||
        lower.contains('unexpected response') ||
        lower.contains('not valid json') ||
        lower.contains('not available on the server')) {
      return 'Food search is unavailable right now. Enter calories manually below.';
    }
    return message;
  }

  String _foodSearchErrorKindFor(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('not configured') ||
        message.contains('not available') ||
        message.contains('usda_fdc') ||
        message.contains('temporarily unavailable')) {
      return 'config';
    }
    if (message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket')) {
      return 'network';
    }
    if (message.contains('unexpected') ||
        message.contains('not valid json') ||
        message.contains('not available on the server')) {
      return 'config';
    }
    return 'generic';
  }

  Future<void> _searchFoods() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final query = _foodQuery.text.trim();
    if (query.length < 2) {
      setState(() => _foodSearchError = 'Enter at least 2 characters.');
      return;
    }

    setState(() {
      _foodSearchLoading = true;
      _foodSearchError = null;
      _foodSearchErrorKind = null;
      _selectedFood = null;
    });

    try {
      final result = await _api.get('foods/search', query: {'query': query});
      if (!mounted) return;
      final raw = (result['foods'] as List?) ?? const [];
      final foods = raw
          .whereType<Map>()
          .map((e) => FoodSearchResult.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() {
        _foodResults = foods;
        _foodSearchLoading = false;
        if (foods.isEmpty) {
          _foodSearchError = 'No matches for "$query". Try a simpler name like chicken or apple.';
          _foodSearchErrorKind = 'empty';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _foodSearchLoading = false;
        _foodSearchError = _friendlyFoodSearchError(e);
        _foodSearchErrorKind = _foodSearchErrorKindFor(e);
        _foodResults = null;
      });
    }
  }

  void _selectFood(FoodSearchResult food) {
    final kcal = food.preferredKcal;
    if (kcal == null) {
      setState(() {
        _foodSearchError = 'No calorie data for this item. Try another result or enter manually.';
        _foodSearchErrorKind = 'empty';
      });
      return;
    }
    setState(() {
      _selectedFood = food;
      _input.text = '$kcal';
      _mealName = food.name;
      _foodSearchError = null;
      _foodSearchErrorKind = null;
      _mealManualEntry = false;
    });
  }

  void _clearSelectedFood() {
    setState(() {
      _selectedFood = null;
      _mealName = null;
      _input.clear();
    });
  }

  Future<void> _saveWater(int ml) async {
    await _savePayload('water', {
      'ml': ml,
      'liters': ml / 1000,
      'glasses': double.parse((ml / 250).toStringAsFixed(2)),
    });
  }

  Future<void> _saveMood(String mood) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await _api.post('captures', {
        'type': 'mood',
        'payload': {'mood': mood},
      });
      if (!mounted) return;
      final home = result['home'] is Map
          ? Map<String, dynamic>.from(result['home'] as Map)
          : null;
      _close(
        CaptureResult(
          saved: true,
          message: result['message']?.toString() ?? 'Saved.',
          home: home,
          loggedMood: mood,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _saveJournal() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final text = _input.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Write a short note first.');
      return;
    }
    await _savePayload('journal', {'text': text});
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    // Leave room for the keyboard so meal/sleep/weight Save stays reachable.
    final maxHeight = (media.size.height - bottomInset) * 0.92;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                if (_action == null) _picker() else _form(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _picker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HarmoniousSectionHeader(
          title: 'Quick capture',
          subtitle: 'Log something in a few taps',
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final item = _actions[index];
            return HarmoniousCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              accentColor: item.$5,
              onTap: _saving ? null : () => _pick(item.$1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$2, color: item.$5, size: 22),
                  const Spacer(),
                  Text(
                    item.$3,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                  ),
                  Text(
                    item.$4,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _form() {
    final action = _action!;
    final meta = _actions.firstWhere((e) => e.$1 == action);

    if (action == QuickAddAction.journal && _journalHistoryMode) {
      return _journalHistoryBody(meta);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _saving ? null : _back,
              icon: const Icon(Icons.arrow_back_rounded),
              constraints: const BoxConstraints(
                minWidth: HarmoniousSpacing.minTapTarget,
                minHeight: HarmoniousSpacing.minTapTarget,
              ),
            ),
            Icon(meta.$2, color: meta.$5),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                meta.$3,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (action == QuickAddAction.journal)
              TextButton(
                onPressed: _saving ? null : _openJournalHistory,
                child: const Text('History'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Text(
            _error!,
            style: const TextStyle(color: AppColors.coral, fontSize: 13),
          ),
          const SizedBox(height: 8),
        ],
        switch (action) {
          QuickAddAction.meal => _mealForm(),
          QuickAddAction.weight => _numberForm(
              label: 'Weight',
              suffix: 'kg',
              onSave: () => _saveNumber(
                type: 'weight',
                field: 'weight',
                requirePositive: true,
                maxValue: 500,
              ),
            ),
          QuickAddAction.sleep => _numberForm(
              label: 'Hours slept',
              suffix: 'hours',
              onSave: () => _saveNumber(
                type: 'sleep',
                field: 'hours',
                requirePositive: true,
                maxValue: 24,
              ),
            ),
          QuickAddAction.workout => _choiceList(
              options: const [
                ('10 minutes', 10),
                ('20 minutes', 20),
                ('30 minutes', 30),
                ('45 minutes', 45),
                ('60 minutes', 60),
              ],
              onPick: (minutes) => _savePayload('workout', {
                'activity': 'Workout',
                'minutes': minutes,
              }),
            ),
          QuickAddAction.water => _choiceList(
              options: const [
                ('Sip · 50 ml', 50),
                ('Small · 100 ml', 100),
                ('Cup · 150 ml', 150),
                ('Coffee · 200 ml', 200),
                ('Tea · 200 ml', 200),
                ('Half glass · 125 ml', 125),
                ('1 glass · 250 ml', 250),
                ('2 glasses · 500 ml', 500),
              ],
              onPick: _saveWater,
            ),
          QuickAddAction.mood => _choiceList(
              options: const [
                ('Happy', 'Happy'),
                ('Neutral', 'Neutral'),
                ('Stressed', 'Stressed'),
                ('Tired', 'Tired'),
                ('Anxious', 'Anxious'),
              ],
              onPick: _saveMood,
            ),
          QuickAddAction.journal => _textForm(
              hint: 'What’s on your mind?',
              lines: 4,
              onSave: _saveJournal,
            ),
        },
        if (_saving) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ],
    );
  }

  Widget _journalHistoryBody((QuickAddAction, IconData, String, String, Color) meta) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Icon(meta.$2, color: meta.$5),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedJournal == null ? 'Journal history' : 'Journal entry',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedJournal != null)
          _JournalDetail(entry: _selectedJournal!)
        else
          _JournalList(
            loading: _journalsLoading,
            error: _journalsError,
            journals: _journals,
            onRetry: _loadJournals,
            onSelect: (entry) => setState(() => _selectedJournal = entry),
          ),
      ],
    );
  }

  Widget _mealForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_mealManualEntry) ...[
          Text(
            'Search a food',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a result to preview calories, then log in one tap.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          _SheetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _foodQuery,
                        enabled: !_saving && !_foodSearchLoading,
                        textInputAction: TextInputAction.search,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                        decoration: InputDecoration(
                          hintText: 'e.g. chicken, apple, oatmeal',
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background.withValues(alpha: 0.55),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.cardBorder.withValues(alpha: 0.8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.cardBorder.withValues(alpha: 0.8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.cyanAccent.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _searchFoods(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SheetIconButton(
                      icon: Icons.search_rounded,
                      loading: _foodSearchLoading,
                      onPressed: _saving || _foodSearchLoading ? null : _searchFoods,
                    ),
                  ],
                ),
                if (_foodSearchLoading) ...[
                  const SizedBox(height: 14),
                  const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
                if (_foodSearchError != null) ...[
                  const SizedBox(height: 12),
                  _FoodSearchMessage(
                    kind: _foodSearchErrorKind ?? 'generic',
                    message: _foodSearchError!,
                  ),
                ],
                if (_foodResults != null && _foodResults!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: AppColors.cardBorder.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 4),
                  for (final food in _foodResults!) ...[
                    _FoodResultTile(
                      food: food,
                      selected: _selectedFood?.id == food.id,
                      enabled: !_saving,
                      onTap: () => _selectFood(food),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _mealManualEntry = true;
                        _foodSearchError = null;
                        _foodSearchErrorKind = null;
                      }),
              child: const Text('Enter calories manually'),
            ),
          ),
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => setState(() => _mealManualEntry = false),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Search foods instead'),
            ),
          ),
          const SizedBox(height: 4),
          _SheetCard(
            child: TextField(
              enabled: !_saving,
              onChanged: (value) => _mealName = value.trim().isEmpty ? null : value.trim(),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'What did you eat? (optional)',
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                filled: true,
                fillColor: AppColors.background.withValues(alpha: 0.55),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.cardBorder.withValues(alpha: 0.8),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.cardBorder.withValues(alpha: 0.8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.cyanAccent.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_selectedFood != null) ...[
          _SelectedFoodCard(
            food: _selectedFood!,
            onClear: _saving ? null : _clearSelectedFood,
          ),
          const SizedBox(height: 12),
        ],
        _SheetCard(
          child: TextField(
            controller: _input,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            style: AppTheme.metricMono(fontSize: 22),
            decoration: InputDecoration(
              labelText: _selectedFood == null ? 'Estimated calories' : 'Calories to log',
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              suffixText: 'kcal',
              suffixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
              filled: true,
              fillColor: AppColors.background.withValues(alpha: 0.55),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cyanAccent.withValues(alpha: 0.65),
                ),
              ),
            ),
            onSubmitted: (_) => _saveNumber(
              type: 'meal',
              field: 'calories',
              name: _mealName?.trim().isNotEmpty == true ? _mealName!.trim() : 'Meal',
              requirePositive: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SheetPrimaryButton(
          label: _selectedFood == null ? 'Log meal' : 'Log ${_mealName ?? 'meal'}',
          loading: _saving,
          onPressed: _saving
              ? null
              : () => _saveNumber(
                    type: 'meal',
                    field: 'calories',
                    name: _mealName?.trim().isNotEmpty == true
                        ? _mealName!.trim()
                        : 'Meal',
                    requirePositive: true,
                  ),
        ),
      ],
    );
  }

  Widget _numberForm({
    required String label,
    required String suffix,
    required VoidCallback onSave,
  }) {
    return Column(
      children: [
        _SheetCard(
          child: TextField(
            controller: _input,
            enabled: !_saving,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            style: AppTheme.metricMono(fontSize: 22),
            decoration: InputDecoration(
              labelText: label,
              suffixText: suffix,
              filled: true,
              fillColor: AppColors.background.withValues(alpha: 0.55),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cyanAccent.withValues(alpha: 0.65),
                ),
              ),
            ),
            onSubmitted: (_) => onSave(),
          ),
        ),
        const SizedBox(height: 14),
        _SheetPrimaryButton(
          label: 'Save',
          loading: _saving,
          onPressed: _saving ? null : onSave,
        ),
      ],
    );
  }

  Widget _textForm({
    required String hint,
    required int lines,
    required VoidCallback onSave,
  }) {
    return Column(
      children: [
        _SheetCard(
          child: TextField(
            controller: _input,
            enabled: !_saving,
            autofocus: true,
            maxLines: lines,
            textInputAction:
                lines == 1 ? TextInputAction.done : TextInputAction.newline,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.background.withValues(alpha: 0.55),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cyanAccent.withValues(alpha: 0.65),
                ),
              ),
            ),
            onSubmitted: lines == 1 ? (_) => onSave() : null,
          ),
        ),
        const SizedBox(height: 14),
        _SheetPrimaryButton(
          label: 'Save',
          loading: _saving,
          onPressed: _saving ? null : onSave,
        ),
      ],
    );
  }

  Widget _choiceList<T>({
    required List<(String, T)> options,
    required Future<void> Function(T value) onPick,
  }) {
    return Column(
      children: [
        for (final option in options)
          _SheetCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.zero,
            child: ListTile(
              enabled: !_saving,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              title: Text(
                option.$1,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: _saving ? null : () => onPick(option.$2),
            ),
          ),
      ],
    );
  }
}

class _JournalHistorySheet extends StatefulWidget {
  const _JournalHistorySheet();

  @override
  State<_JournalHistorySheet> createState() => _JournalHistorySheetState();
}

class _JournalHistorySheetState extends State<_JournalHistorySheet> {
  final _api = FeatureService();
  List<JournalEntry>? _journals;
  bool _loading = true;
  String? _error;
  JournalEntry? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.get('captures?limit=100');
      if (!mounted) return;
      final raw = (result['captures'] as List?) ?? const [];
      final journals = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['type']?.toString() == 'journal')
          .map(JournalEntry.fromJson)
          .where((e) => e.text.isNotEmpty)
          .toList();
      setState(() {
        _journals = journals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.88;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (_selected != null)
                    IconButton(
                      onPressed: () => setState(() => _selected = null),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  const Icon(Icons.edit_note_rounded, color: AppColors.sky),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selected == null ? 'Journal history' : 'Journal entry',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selected != null)
                _JournalDetail(entry: _selected!)
              else
                _JournalList(
                  loading: _loading,
                  error: _error,
                  journals: _journals,
                  onRetry: _load,
                  onSelect: (entry) => setState(() => _selected = entry),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalList extends StatelessWidget {
  const _JournalList({
    required this.loading,
    required this.error,
    required this.journals,
    required this.onRetry,
    required this.onSelect,
  });

  final bool loading;
  final String? error;
  final List<JournalEntry>? journals;
  final VoidCallback onRetry;
  final void Function(JournalEntry entry) onSelect;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.coral, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    final items = journals ?? const <JournalEntry>[];
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No journal entries yet. Write your first reflection to start a history.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: AppColors.surfaceBorder.withValues(alpha: 0.7),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              DateFormat('EEE, MMM d · h:mm a').format(items[i].capturedAt.toLocal()),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _preview(items[i].text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: () => onSelect(items[i]),
          ),
        ],
      ],
    );
  }

  String _preview(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 120) return compact;
    return '${compact.substring(0, 117)}…';
  }
}

class _JournalDetail extends StatelessWidget {
  const _JournalDetail({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          DateFormat('EEEE, MMMM d · h:mm a').format(entry.capturedAt.toLocal()),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          entry.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.85),
        ),
      ),
      child: child,
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: enabled
                ? const [
                    AppColors.cyanGradientStart,
                    AppColors.cyanGradientEnd,
                  ]
                : [
                    AppColors.cyanGradientStart.withValues(alpha: 0.4),
                    AppColors.cyanGradientEnd.withValues(alpha: 0.4),
                  ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimaryButton,
                      ),
                    )
                  : Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.onPrimaryButton,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetIconButton extends StatelessWidget {
  const _SheetIconButton({
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cyanAccent.withValues(alpha: 0.18),
          foregroundColor: AppColors.cyanAccent,
          disabledBackgroundColor: AppColors.cardBorder.withValues(alpha: 0.35),
          disabledForegroundColor: AppColors.textMuted,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 22),
      ),
    );
  }
}

class _FoodSearchMessage extends StatelessWidget {
  const _FoodSearchMessage({
    required this.kind,
    required this.message,
  });

  final String kind;
  final String message;

  IconData get _icon {
    switch (kind) {
      case 'empty':
        return Icons.search_off_rounded;
      case 'network':
        return Icons.wifi_off_rounded;
      case 'config':
        return Icons.settings_suggest_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color get _accent {
    switch (kind) {
      case 'network':
        return AppColors.coral;
      case 'config':
        return AppColors.amber;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodResultTile extends StatelessWidget {
  const _FoodResultTile({
    required this.food,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final FoodSearchResult food;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kcal = food.preferredKcal;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.cyanAccent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.cyanAccent.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  food.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                kcal == null ? '—' : '$kcal kcal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.cyanAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedFoodCard extends StatelessWidget {
  const _SelectedFoodCard({
    required this.food,
    this.onClear,
  });

  final FoodSearchResult food;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final kcal = food.preferredKcal;
    return _SheetCard(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.cyanAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.cyanAccent,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (kcal != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$kcal kcal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textMuted,
            ),
        ],
      ),
    );
  }
}
