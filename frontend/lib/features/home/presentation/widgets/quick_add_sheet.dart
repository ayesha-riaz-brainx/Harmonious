import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';

enum QuickAddAction {
  meal,
  water,
  weight,
  workout,
  mood,
  sleep,
  journal,
  healthReport,
}

class CaptureResult {
  const CaptureResult({
    required this.saved,
    this.message,
    this.home,
  });

  final bool saved;
  final String? message;
  final Map<String, dynamic>? home;
}

/// Opens one bottom sheet that owns the full capture flow (pick → form → save).
/// Avoids nested dialogs that caused `_dependents.isEmpty` crashes.
Future<CaptureResult?> showQuickCapture(BuildContext context) {
  return showModalBottomSheet<CaptureResult>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _QuickCaptureSheet(),
  );
}

/// Legacy entry used by Today shortcuts — opens the same safe sheet.
Future<QuickAddAction?> showQuickAddSheet(BuildContext context) async {
  // Kept for call-site compatibility; prefer showQuickCapture.
  return null;
}

class QuickCaptureFlow {
  QuickCaptureFlow(this.context, {FeatureService? api});

  final BuildContext context;

  /// Opens the unified capture sheet. Optional [action] skips the picker.
  Future<CaptureResult> run([QuickAddAction? action]) async {
    final result = await showModalBottomSheet<CaptureResult>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QuickCaptureSheet(initialAction: action),
    );
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

  QuickAddAction? _action;
  bool _saving = false;
  String? _error;

  static const _actions = <(QuickAddAction, IconData, String, String, Color)>[
    (QuickAddAction.meal, Icons.restaurant_rounded, 'Log Meal', 'Calories', AppColors.amber),
    (QuickAddAction.water, Icons.water_drop_rounded, 'Log Water', 'Sip or glass', AppColors.sky),
    (QuickAddAction.weight, Icons.monitor_weight_outlined, 'Log Weight', 'kg', AppColors.aqua),
    (QuickAddAction.workout, Icons.fitness_center_rounded, 'Log Workout', 'Minutes', AppColors.coral),
    (QuickAddAction.mood, Icons.mood_rounded, 'Log Mood', 'How you feel', AppColors.mint),
    (QuickAddAction.sleep, Icons.bedtime_rounded, 'Log Sleep', 'Hours', AppColors.lavender),
    (QuickAddAction.journal, Icons.edit_note_rounded, 'Journal', 'Reflection', AppColors.sky),
    (QuickAddAction.healthReport, Icons.upload_file_rounded, 'Health Report', 'Photo or note', AppColors.coral),
  ];

  @override
  void initState() {
    super.initState();
    _action = widget.initialAction;
    if (_action == QuickAddAction.meal) {
      _input.text = '400';
    } else if (_action == QuickAddAction.sleep) {
      _input.text = '8';
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _pick(QuickAddAction action) {
    setState(() {
      _action = action;
      _error = null;
      _input.clear();
      if (action == QuickAddAction.meal) _input.text = '400';
      if (action == QuickAddAction.sleep) _input.text = '8';
    });
  }

  void _back() {
    if (widget.initialAction != null) {
      Navigator.of(context).pop(const CaptureResult(saved: false));
      return;
    }
    setState(() {
      _action = null;
      _error = null;
      _input.clear();
    });
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
      Navigator.of(context).pop(
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
  }) async {
    final value = double.tryParse(_input.text.trim());
    if (value == null) {
      setState(() => _error = 'Enter a valid number.');
      return;
    }
    final payload = <String, dynamic>{field: field == 'calories' ? value.round() : value};
    if (name != null) payload['name'] = name;
    if (type == 'workout') {
      payload['activity'] = 'Workout';
      payload['minutes'] = value.round();
      payload.remove(field);
    }
    await _savePayload(type, payload);
  }

  Future<void> _saveWater(int ml) async {
    await _savePayload('water', {
      'ml': ml,
      'liters': ml / 1000,
      'glasses': double.parse((ml / 250).toStringAsFixed(2)),
    });
  }

  Future<void> _saveMood(String mood) async {
    await _savePayload('mood', {'mood': mood});
  }

  Future<void> _saveJournal() async {
    final text = _input.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Write a short note first.');
      return;
    }
    await _savePayload('journal', {'text': text});
  }

  Future<void> _saveHealthReport(String source) async {
    if (source == 'name') {
      final text = _input.text.trim();
      if (text.isEmpty) {
        setState(() => _error = 'Enter a report name.');
        return;
      }
      await _savePayload('health_report', {
        'name': text,
        'extension': 'note',
        'source': 'manual',
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final image = await ImagePicker().pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (!mounted) return;
      if (image == null) {
        setState(() => _saving = false);
        return;
      }
      await _savePayload('health_report', {
        'name': image.name,
        'extension': image.name.split('.').last,
        'source': source,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: bottom),
        child: Padding(
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
    );
  }

  Widget _picker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Quick Capture',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Log something in a few taps',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (context, index) {
            final item = _actions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saving ? null : () => _pick(item.$1),
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.$5.withValues(alpha: 0.16),
                        AppColors.background,
                      ],
                    ),
                    border: Border.all(color: item.$5.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.$2, color: item.$5, size: 22),
                      const Spacer(),
                      Text(
                        item.$3,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        item.$4,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
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
    );
  }

  Widget _form() {
    final action = _action!;
    final meta = _actions.firstWhere((e) => e.$1 == action);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _saving ? null : _back,
              icon: const Icon(Icons.arrow_back_rounded),
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
          QuickAddAction.meal => _numberForm(
              label: 'Estimated calories',
              suffix: 'kcal',
              onSave: () => _saveNumber(
                type: 'meal',
                field: 'calories',
                name: 'Meal',
              ),
            ),
          QuickAddAction.weight => _numberForm(
              label: 'Weight',
              suffix: 'kg',
              onSave: () => _saveNumber(type: 'weight', field: 'weight'),
            ),
          QuickAddAction.sleep => _numberForm(
              label: 'Hours slept',
              suffix: 'hours',
              onSave: () => _saveNumber(type: 'sleep', field: 'hours'),
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
          QuickAddAction.healthReport => Column(
              children: [
                _choiceList(
                  options: const [
                    ('Take photo', 'camera'),
                    ('Choose from gallery', 'gallery'),
                  ],
                  onPick: _saveHealthReport,
                ),
                const SizedBox(height: 8),
                _textForm(
                  hint: 'Or type a report name',
                  lines: 1,
                  onSave: () => _saveHealthReport('name'),
                ),
              ],
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

  Widget _numberForm({
    required String label,
    required String suffix,
    required VoidCallback onSave,
  }) {
    return Column(
      children: [
        TextField(
          controller: _input,
          enabled: !_saving,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            filled: true,
            fillColor: AppColors.background,
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : onSave,
            child: const Text('Save'),
          ),
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
        TextField(
          controller: _input,
          enabled: !_saving,
          autofocus: true,
          maxLines: lines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : onSave,
            child: const Text('Save'),
          ),
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
          ListTile(
            enabled: !_saving,
            contentPadding: EdgeInsets.zero,
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
      ],
    );
  }
}
