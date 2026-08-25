import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:slot_1_tasks/core/services/health_tracker_models.dart';
import 'package:slot_1_tasks/core/services/health_tracker_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class HealthTab extends StatefulWidget {
  const HealthTab({super.key});

  @override
  HealthTabState createState() => HealthTabState();
}

class HealthTabState extends State<HealthTab> {
  final _service = HealthTrackerService();
  final _expandedSections = <String>{};

  HealthTrackerData _data = const HealthTrackerData();
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.load();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  Future<void> _persist(HealthTrackerData next) async {
    setState(() {
      _busy = true;
      _data = next; // show immediately
    });
    try {
      final saved = await _service.save(next);
      if (!mounted) return;
      setState(() {
        _data = saved;
        _busy = false;
      });
      _toast('Saved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Color _statusColor(HealthConditionStatus status) {
    return switch (status) {
      HealthConditionStatus.improving => AppColors.mint,
      HealthConditionStatus.stable => AppColors.sky,
      HealthConditionStatus.worse => AppColors.coral,
      HealthConditionStatus.resolved => AppColors.lavender,
    };
  }

  Future<void> _upsertCondition({HealthCondition? existing}) async {
    final result = await showDialog<_ConditionFormResult>(
      context: context,
      builder: (context) => _ConditionFormDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    final now = DateTime.now();
    if (existing == null) {
      final created = HealthCondition(
        id: healthNewId(),
        name: result.name,
        details: result.details,
        status: result.status,
        createdAt: now,
        updatedAt: now,
        updates: [
          HealthConditionUpdate(
            id: healthNewId(),
            status: result.status,
            notes: 'Condition added',
            at: now,
          ),
        ],
      );
      await _persist(
        _data.copyWith(conditions: [created, ..._data.conditions]),
      );
      return;
    }

    final updated = existing.copyWith(
      name: result.name,
      details: result.details,
      status: result.status,
      updatedAt: now,
    );
    await _persist(
      _data.copyWith(
        conditions: [
          for (final item in _data.conditions)
            item.id == existing.id ? updated : item,
        ],
      ),
    );
  }

  Future<void> _addProgressUpdate(HealthCondition condition) async {
    final result = await showDialog<_ProgressFormResult>(
      context: context,
      builder: (context) => _ProgressFormDialog(condition: condition),
    );
    if (result == null || !mounted) return;

    final now = DateTime.now();
    final update = HealthConditionUpdate(
      id: healthNewId(),
      status: result.status,
      notes: result.notes,
      at: now,
    );
    final next = condition.copyWith(
      status: result.status,
      updatedAt: now,
      updates: [update, ...condition.updates],
    );
    await _persist(
      _data.copyWith(
        conditions: [
          for (final item in _data.conditions)
            item.id == condition.id ? next : item,
        ],
      ),
    );
  }

  Future<void> _deleteCondition(HealthCondition condition) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete condition?'),
        content: Text('Remove “${condition.name}” and its progress history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _persist(
      _data.copyWith(
        conditions: _data.conditions.where((e) => e.id != condition.id).toList(),
      ),
    );
  }

  Future<void> _deleteProgressUpdate(
    HealthCondition condition,
    HealthConditionUpdate update,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete progress update?'),
        content: Text(
          'Remove this ${update.status.label} update for “${condition.name}”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final nextUpdates =
        condition.updates.where((e) => e.id != update.id).toList();
    final nextStatus =
        nextUpdates.isNotEmpty ? nextUpdates.first.status : condition.status;
    final next = condition.copyWith(
      status: nextStatus,
      updatedAt: DateTime.now(),
      updates: nextUpdates,
    );
    await _persist(
      _data.copyWith(
        conditions: [
          for (final item in _data.conditions)
            item.id == condition.id ? next : item,
        ],
      ),
    );
  }

  Future<void> _upsertRecord({HealthRecord? existing}) async {
    final result = await showDialog<_RecordFormResult>(
      context: context,
      builder: (context) => _RecordFormDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    final record = HealthRecord(
      id: existing?.id ?? healthNewId(),
      name: result.name,
      value: result.value,
      notes: result.notes,
      date: result.date,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    final next = existing == null
        ? [record, ..._data.records]
        : [
            for (final item in _data.records)
              item.id == existing.id ? record : item,
          ];
    await _persist(_data.copyWith(records: next));
  }

  Future<void> _deleteRecord(HealthRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete record?'),
        content: Text('Remove “${record.name}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _persist(
      _data.copyWith(
        records: _data.records.where((e) => e.id != record.id).toList(),
      ),
    );
  }

  Future<void> _upsertSymptom({HealthSymptom? existing}) async {
    final result = await showDialog<_SymptomFormResult>(
      context: context,
      builder: (context) => _SymptomFormDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    final symptom = HealthSymptom(
      id: existing?.id ?? healthNewId(),
      name: result.name,
      severity: result.severity,
      notes: result.notes,
      date: result.date,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    final next = existing == null
        ? [symptom, ..._data.symptoms]
        : [
            for (final item in _data.symptoms)
              item.id == existing.id ? symptom : item,
          ];
    await _persist(_data.copyWith(symptoms: next));
  }

  Future<void> _deleteSymptom(HealthSymptom symptom) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete symptom?'),
        content: Text('Remove “${symptom.name}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _persist(
      _data.copyWith(
        symptoms: _data.symptoms.where((e) => e.id != symptom.id).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HarmoniousSpacing.screenHorizontal,
                14,
                HarmoniousSpacing.screenHorizontal,
                0,
              ),
              child: HarmoniousPageHeader(
                icon: Icons.favorite_outline_rounded,
                title: 'Health',
                subtitle: _busy ? 'Saving…' : null,
                iconColor: AppColors.coral,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? HarmoniousErrorState(
                          message: _error!,
                          onRetry: _load,
                        )
                      : _healthFlow(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthFlow() {
    final active = _data.conditions
        .where((c) => c.status != HealthConditionStatus.resolved)
        .length;
    final timeline = _data.conditions
        .expand((c) => c.updates.map((u) => (c, u)))
        .toList()
      ..sort((a, b) => b.$2.at.compareTo(a.$2.at));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        HarmoniousSpacing.screenHorizontal,
        16,
        HarmoniousSpacing.screenHorizontal,
        100,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _statChip(
                '$active',
                'Active',
                AppColors.coral,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statChip(
                '${_data.symptoms.length}',
                'Symptoms',
                AppColors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statChip(
                '${_data.records.length}',
                'Records',
                AppColors.sky,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        ..._section(
          key: 'conditions',
          title: 'Conditions',
          subtitle: null,
          addLabel: 'Add',
          onAdd: () => _upsertCondition(),
          isEmpty: _data.conditions.isEmpty,
          emptyTitle: 'No conditions yet',
          emptyMessage: 'Add a condition to start tracking how it changes.',
          emptyIcon: Icons.healing_outlined,
          children: [
            for (final condition in _data.conditions)
              _itemCard(
                title: condition.name,
                subtitle: condition.details.isEmpty
                    ? condition.status.label
                    : '${condition.status.label} · ${condition.details}',
                accent: _statusColor(condition.status),
                onEdit: () => _upsertCondition(existing: condition),
                onDelete: () => _deleteCondition(condition),
                trailing: TextButton(
                  onPressed: () => _addProgressUpdate(condition),
                  child: const Text('Log update'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        ..._section(
          key: 'symptoms',
          title: 'Symptoms',
          subtitle: null,
          addLabel: 'Log',
          onAdd: () => _upsertSymptom(),
          isEmpty: _data.symptoms.isEmpty,
          emptyTitle: 'No symptoms logged',
          emptyMessage: 'Track name, severity, date, and notes.',
          emptyIcon: Icons.thermostat_outlined,
          children: [
            for (final symptom in _data.symptoms)
              _itemCard(
                title: symptom.name,
                subtitle: [
                  'Severity ${symptom.severity}/5',
                  DateFormat('MMM d, yyyy').format(symptom.date),
                  if (symptom.notes.isNotEmpty) symptom.notes,
                ].join(' · '),
                accent: AppColors.amber,
                onEdit: () => _upsertSymptom(existing: symptom),
                onDelete: () => _deleteSymptom(symptom),
              ),
          ],
        ),
        const SizedBox(height: 28),
        ..._section(
          key: 'records',
          title: 'Records',
          subtitle: null,
          addLabel: 'Add',
          onAdd: () => _upsertRecord(),
          isEmpty: _data.records.isEmpty,
          emptyTitle: 'No health records',
          emptyMessage: 'Log test names, dates, and results.',
          emptyIcon: Icons.assignment_outlined,
          children: [
            for (final record in _data.records)
              _itemCard(
                title: record.name,
                subtitle: [
                  DateFormat('MMM d, yyyy').format(record.date),
                  if (record.value.isNotEmpty) record.value,
                  if (record.notes.isNotEmpty) record.notes,
                ].join(' · '),
                accent: AppColors.sky,
                onEdit: () => _upsertRecord(existing: record),
                onDelete: () => _deleteRecord(record),
              ),
          ],
        ),
        const SizedBox(height: 28),
        ..._section(
          key: 'progress',
          title: 'Progress',
          subtitle: null,
          addLabel: null,
          onAdd: null,
          isEmpty: timeline.isEmpty,
          emptyTitle: 'No progress yet',
          emptyMessage:
              'Add a condition, then tap Log update as things change.',
          emptyIcon: Icons.timeline_outlined,
          children: [
            for (final entry in timeline)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HarmoniousCard(
                  accentColor: _statusColor(entry.$2.status),
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.$1.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  entry.$2.status.label,
                                  style: TextStyle(
                                    color: _statusColor(entry.$2.status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEE, MMM d · h:mm a')
                                  .format(entry.$2.at.toLocal()),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            if (entry.$2.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                entry.$2.notes,
                                style: const TextStyle(height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () =>
                            _deleteProgressUpdate(entry.$1, entry.$2),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.coral,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return HarmoniousCard(
      accentColor: color,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _section({
    required String key,
    required String title,
    String? subtitle,
    required String? addLabel,
    required VoidCallback? onAdd,
    required bool isEmpty,
    required String emptyTitle,
    required String emptyMessage,
    required IconData emptyIcon,
    required List<Widget> children,
    int previewCount = 5,
  }) {
    final expanded = _expandedSections.contains(key);
    final visible = (!expanded && children.length > previewCount)
        ? children.take(previewCount).toList()
        : children;
    final canToggle = children.length > previewCount;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: HarmoniousSectionHeader(
              title: title,
              subtitle: subtitle,
            ),
          ),
          if (addLabel != null && onAdd != null)
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(addLabel),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (isEmpty)
        HarmoniousCard(
          child: HarmoniousEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
            compact: true,
          ),
        )
      else ...[
        ...visible,
        if (canToggle)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                setState(() {
                  if (expanded) {
                    _expandedSections.remove(key);
                  } else {
                    _expandedSections.add(key);
                  }
                });
              },
              child: Text(
                expanded
                    ? 'Show less'
                    : 'View all (${children.length})',
              ),
            ),
          ),
      ],
    ];
  }

  Widget _itemCard({
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HarmoniousCard(
        accentColor: accent,
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 4),
                    trailing,
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionFormResult {
  const _ConditionFormResult({
    required this.name,
    required this.details,
    required this.status,
  });

  final String name;
  final String details;
  final HealthConditionStatus status;
}

class _ConditionFormDialog extends StatefulWidget {
  const _ConditionFormDialog({this.existing});

  final HealthCondition? existing;

  @override
  State<_ConditionFormDialog> createState() => _ConditionFormDialogState();
}

class _ConditionFormDialogState extends State<_ConditionFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _details;
  late HealthConditionStatus _status;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _details = TextEditingController(text: widget.existing?.details ?? '');
    _status = widget.existing?.status ?? HealthConditionStatus.stable;
  }

  @override
  void dispose() {
    _name.dispose();
    _details.dispose();
    super.dispose();
  }

  void _save() {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _nameError = 'Enter a condition name to save');
      return;
    }
    Navigator.pop(
      context,
      _ConditionFormResult(
        name: trimmed,
        details: _details.text.trim(),
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.existing == null ? 'Add condition' : 'Edit condition'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Condition / disease name',
                errorText: _nameError,
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Onset, notes, doctor advice…',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HealthConditionStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final value in HealthConditionStatus.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _ProgressFormResult {
  const _ProgressFormResult({required this.status, required this.notes});

  final HealthConditionStatus status;
  final String notes;
}

class _ProgressFormDialog extends StatefulWidget {
  const _ProgressFormDialog({required this.condition});

  final HealthCondition condition;

  @override
  State<_ProgressFormDialog> createState() => _ProgressFormDialogState();
}

class _ProgressFormDialogState extends State<_ProgressFormDialog> {
  late final TextEditingController _notes;
  late HealthConditionStatus _status;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController();
    _status = widget.condition.status;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Update · ${widget.condition.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<HealthConditionStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Progress'),
              items: [
                for (final value in HealthConditionStatus.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'What changed?',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _ProgressFormResult(
                status: _status,
                notes: _notes.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _RecordFormResult {
  const _RecordFormResult({
    required this.name,
    required this.value,
    required this.notes,
    required this.date,
  });

  final String name;
  final String value;
  final String notes;
  final DateTime date;
}

class _RecordFormDialog extends StatefulWidget {
  const _RecordFormDialog({this.existing});

  final HealthRecord? existing;

  @override
  State<_RecordFormDialog> createState() => _RecordFormDialogState();
}

class _RecordFormDialogState extends State<_RecordFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _value;
  late final TextEditingController _notes;
  late DateTime _date;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _value = TextEditingController(text: widget.existing?.value ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _date = widget.existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _nameError = 'Enter a name to save');
      return;
    }
    Navigator.pop(
      context,
      _RecordFormResult(
        name: trimmed,
        value: _value.text.trim(),
        notes: _notes.text.trim(),
        date: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.existing == null ? 'Add health record' : 'Edit record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Test / result name',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextField(
              controller: _value,
              decoration: const InputDecoration(labelText: 'Result / value'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _SymptomFormResult {
  const _SymptomFormResult({
    required this.name,
    required this.severity,
    required this.notes,
    required this.date,
  });

  final String name;
  final int severity;
  final String notes;
  final DateTime date;
}

class _SymptomFormDialog extends StatefulWidget {
  const _SymptomFormDialog({this.existing});

  final HealthSymptom? existing;

  @override
  State<_SymptomFormDialog> createState() => _SymptomFormDialogState();
}

class _SymptomFormDialogState extends State<_SymptomFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late int _severity;
  late DateTime _date;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _severity = widget.existing?.severity ?? 3;
    _date = widget.existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _nameError = 'Enter a symptom name to save');
      return;
    }
    Navigator.pop(
      context,
      _SymptomFormResult(
        name: trimmed,
        severity: _severity,
        notes: _notes.text.trim(),
        date: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.existing == null ? 'Log symptom' : 'Edit symptom'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Symptom name',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            Text('Severity: $_severity / 5'),
            Slider(
              value: _severity.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_severity',
              onChanged: (v) => setState(() => _severity = v.round()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
