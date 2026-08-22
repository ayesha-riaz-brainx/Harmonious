import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

import 'package:slot_1_tasks/core/config/api_config.dart';
import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/bmi_assessment_page.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/shared/widgets/auth_notice.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class YouTab extends StatefulWidget {
  const YouTab({super.key});

  @override
  State<YouTab> createState() => _YouTabState();
}

class _YouTabState extends State<YouTab> {
  final _auth = AuthService();
  final _api = FeatureService();
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _health = {};
  List<String> _goals = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.get('settings');
      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
        _health = Map<String, dynamic>.from(data['health_info'] as Map? ?? {});
        _goals =
            ((data['goals'] as List?) ?? []).map((e) => e.toString()).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(error);
    }
  }

  Future<void> _save(Map<String, dynamic> patch) async {
    setState(() => _busy = true);
    try {
      final data = await _api.patch('settings', patch);
      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(data['profile'] as Map? ?? {});
        _health = Map<String, dynamic>.from(data['health_info'] as Map? ?? {});
        _goals =
            ((data['goals'] as List?) ?? []).map((e) => e.toString()).toList();
      });
      _toast('Saved.');
    } catch (error) {
      if (!mounted) return;
      _toast(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(
      text: _profile['display_name']?.toString() ?? '',
    );
    final age = TextEditingController(text: _profile['age']?.toString() ?? '');
    final height =
        TextEditingController(text: _profile['height']?.toString() ?? '');
    final weight =
        TextEditingController(text: _profile['weight']?.toString() ?? '');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, 'Name'),
              _field(age, 'Age', number: true),
              _field(height, 'Height', number: true),
              _field(weight, 'Weight', number: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'display_name': name.text.trim(),
              'age': int.tryParse(age.text.trim()),
              'height': double.tryParse(height.text.trim()),
              'weight': double.tryParse(weight.text.trim()),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    age.dispose();
    height.dispose();
    weight.dispose();
    if (result != null) await _save({'profile': result});
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _editGoals() async {
    final selected = _goals.toSet();
    final custom = TextEditingController();
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current goals',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final goal in {
                        ...OnboardingOptions.goals,
                        ...selected,
                      })
                        FilterChip(
                          label: Text(goal),
                          selected: selected.contains(goal),
                          onSelected: (_) => setSheetState(() {
                            selected.contains(goal)
                                ? selected.remove(goal)
                                : selected.add(goal);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: custom,
                    decoration: const InputDecoration(
                      labelText: 'Add a new goal',
                      hintText: 'e.g. Run a 5K',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      final value = custom.text.trim();
                      if (value.isEmpty) return;
                      setSheetState(() {
                        selected.add(value);
                        custom.clear();
                      });
                    },
                    child: const Text('Add goal'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, selected.toList()),
                      child: const Text('Save goals'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    custom.dispose();
    if (result != null) await _save({'goals': result});
  }

  Future<void> _editHealth() async {
    final conditions = TextEditingController(
      text: (_health['conditions'] as List?)?.join(', ') ?? '',
    );
    final medications = TextEditingController(
      text: (_health['medications'] as List?)?.join(', ') ?? '',
    );
    final history = TextEditingController(
      text: _health['medical_history']?.toString() ?? '',
    );
    final documents = TextEditingController(
      text: (_health['documents'] as List?)?.join(', ') ?? '',
    );
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Health information'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field(conditions, 'Conditions (comma separated)'),
              _field(medications, 'Medications (comma separated)'),
              _field(history, 'Medical history'),
              _field(documents, 'Health documents (names)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'conditions': _csv(conditions.text),
              'medications': _csv(medications.text),
              'medical_history': history.text.trim(),
              'documents': _csv(documents.text),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    conditions.dispose();
    medications.dispose();
    history.dispose();
    documents.dispose();
    if (result != null) await _save({'health_info': result});
  }

  List<String> _csv(String value) => value
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _export() async {
    try {
      final data = await _api.get('settings/export');
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
      );
      if (!mounted) return;
      _toast('Your data export was copied to the clipboard.');
    } catch (error) {
      _toast(error);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.welcome,
      (route) => false,
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(ApiConfig.privacyPolicyUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AuthNotice.show(
        context,
        message: 'Could not open the privacy policy.',
        tone: AuthNoticeTone.error,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your Harmonious account and data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await _auth.deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);

    AuthNotice.show(
      context,
      message: result.message,
      tone: result.success ? AuthNoticeTone.success : AuthNoticeTone.error,
    );

    if (!result.success) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.welcome,
      (route) => false,
    );
  }

  void _toast(Object value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value.toString().replaceFirst('Exception: ', '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const HarmoniousBackground(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final name = _profile['display_name']?.toString() ??
        _profile['full_name']?.toString() ??
        'Friend';

    return HarmoniousBackground(
      child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              HarmoniousSpacing.screenHorizontal,
              16,
              HarmoniousSpacing.screenHorizontal,
              32,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              const HarmoniousPageHeader(
                icon: Icons.person_rounded,
                title: 'You',
                subtitle: 'Profile, goals, and account',
              ),
              const SizedBox(height: 20),
              _profileCard(name),
              const HarmoniousSectionDivider(),
              const SizedBox(height: 8),
              _section(
                title: 'BMI assessment',
                icon: Icons.monitor_weight_outlined,
                color: AppColors.aqua,
                subtitle: 'Age, height & weight → WHO-style BMI',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BmiAssessmentPage(),
                    ),
                  );
                },
              ),
              _section(
                title: 'Goals',
                icon: Icons.flag_rounded,
                color: AppColors.amber,
                subtitle:
                    _goals.isEmpty ? 'No current goals' : _goals.join(' · '),
                onTap: _editGoals,
              ),
              _section(
                title: 'Health information',
                icon: Icons.health_and_safety_rounded,
                color: AppColors.coral,
                subtitle: 'History, conditions, medications & documents',
                onTap: _editHealth,
              ),
              const HarmoniousSectionDivider(),
              const SizedBox(height: 8),
              _section(
                title: 'Privacy policy',
                icon: Icons.privacy_tip_rounded,
                color: AppColors.sky,
                subtitle: 'Read how Harmonious handles your data',
                onTap: _openPrivacyPolicy,
              ),
              _section(
                title: 'Privacy & data export',
                icon: Icons.download_rounded,
                color: AppColors.mint,
                subtitle: 'Copy a complete export of your Harmonious data',
                onTap: _export,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: HarmoniousSpacing.minTapTarget,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: HarmoniousSpacing.minTapTarget,
                child: TextButton.icon(
                  onPressed: _busy ? null : _deleteAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.coral,
                  ),
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text(AppStrings.deleteAccount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(String name) {
    return HarmoniousCard(
      padding: const EdgeInsets.all(18),
      accentColor: AppColors.primary,
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              name.isEmpty ? 'Y' : name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryBright,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_profile['age'] ?? '—'} yrs · '
                  '${_profile['height'] ?? '—'} ${_profile['height_unit'] ?? 'cm'} · '
                  '${_profile['weight'] ?? '—'} ${_profile['weight_unit'] ?? 'kg'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _editProfile,
            constraints: const BoxConstraints(
              minWidth: HarmoniousSpacing.minTapTarget,
              minHeight: HarmoniousSpacing.minTapTarget,
            ),
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.primaryBright,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HarmoniousCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
