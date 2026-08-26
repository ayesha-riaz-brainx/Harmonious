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
        final rawProfile =
            Map<String, dynamic>.from(data['profile'] as Map? ?? {});
        final onboarding = Map<String, dynamic>.from(
          (data['onboarding_data'] as Map?) ??
              (rawProfile['onboarding_data'] as Map?) ??
              const {},
        );
        _profile = _hydrateProfile(rawProfile, onboarding);
        _goals =
            ((data['goals'] as List?) ?? []).map((e) => e.toString()).toList();
        if (_goals.isEmpty) {
          final fromOnboarding = (onboarding['goals'] as List?) ?? [];
          _goals = fromOnboarding
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(error);
    }
  }

  Map<String, dynamic> _hydrateProfile(
    Map<String, dynamic> profile,
    Map<String, dynamic> onboarding,
  ) {
    String? pick(String key, [List<String>? aliases]) {
      final current = profile[key];
      if (current != null && current.toString().trim().isNotEmpty) {
        return current.toString();
      }
      for (final alias in aliases ?? [key]) {
        final value = onboarding[alias];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return current?.toString();
    }

    num? pickNum(String key) {
      final current = profile[key];
      if (current is num) return current;
      if (current != null) {
        final parsed = num.tryParse(current.toString());
        if (parsed != null) return parsed;
      }
      final fromOnboarding = onboarding[key];
      if (fromOnboarding is num) return fromOnboarding;
      return num.tryParse(fromOnboarding?.toString() ?? '');
    }

    return {
      ...profile,
      'display_name': pick('display_name', ['display_name', 'name', 'full_name']),
      'full_name': pick('full_name', ['full_name', 'display_name', 'name']),
      'age': pickNum('age') ?? profile['age'],
      'height': pickNum('height') ?? profile['height'],
      'weight': pickNum('weight') ?? profile['weight'],
      'gender': pick('gender') ?? profile['gender'],
      'height_unit': pick('height_unit') ?? profile['height_unit'] ?? 'cm',
      'weight_unit': pick('weight_unit') ?? profile['weight_unit'] ?? 'kg',
      'activity_level':
          pick('activity_level') ?? profile['activity_level'],
      'goals': onboarding['goals'] ?? profile['goals'],
    };
  }

  Future<void> _save(Map<String, dynamic> patch) async {
    setState(() => _busy = true);
    try {
      final data = await _api.patch('settings', patch);
      if (!mounted) return;
      setState(() {
        final rawProfile =
            Map<String, dynamic>.from(data['profile'] as Map? ?? {});
        final onboarding = Map<String, dynamic>.from(
          (data['onboarding_data'] as Map?) ??
              (rawProfile['onboarding_data'] as Map?) ??
              const {},
        );
        _profile = _hydrateProfile(rawProfile, onboarding);
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
    final result = await showDialog<_ProfileEditResult>(
      context: context,
      builder: (context) => _ProfileEditDialog(profile: _profile),
    );
    if (result == null || !mounted) return;

    final profilePatch = <String, dynamic>{};
    if (result.name.trim().isNotEmpty) {
      profilePatch['display_name'] = result.name.trim();
    }
    if (result.age != null) profilePatch['age'] = result.age;
    if (result.height != null) profilePatch['height'] = result.height;
    if (result.weight != null) profilePatch['weight'] = result.weight;
    if (profilePatch.isEmpty) {
      _toast('Nothing to save.');
      return;
    }
    await _save({'profile': profilePatch});
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
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Expanded(
                        child: Text(
                          'Current goals',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
    final confirmController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var typedOk = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Delete account?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes your Harmonious account and all '
                    'saved data. This cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type DELETE to confirm.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'DELETE',
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        typedOk = value.trim().toUpperCase() == 'DELETE';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: !typedOk
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.coral,
                  ),
                  child: const Text('Delete forever'),
                ),
              ],
            );
          },
        );
      },
    );
    confirmController.dispose();
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
                subtitle: _bodyStatsLine(),
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

  String _bodyStatsLine() {
    final age = _profile['age'];
    final height = _profile['height'];
    final weight = _profile['weight'];
    final heightUnit = _profile['height_unit']?.toString() ?? 'cm';
    final weightUnit = _profile['weight_unit']?.toString() ?? 'kg';

    final agePart = age == null ? 'Age —' : '$age yrs';
    final heightPart = height == null ? 'Height —' : '$height $heightUnit';
    final weightPart = weight == null ? 'Weight —' : '$weight $weightUnit';
    return '$agePart · $heightPart · $weightPart';
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
                  _bodyStatsLine(),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _busy ? null : _editProfile,
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

class _ProfileEditResult {
  const _ProfileEditResult({
    required this.name,
    this.age,
    this.height,
    this.weight,
  });

  final String name;
  final int? age;
  final double? height;
  final double? weight;
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(
      text: profile['display_name']?.toString() ??
          profile['full_name']?.toString() ??
          '',
    );
    _age = TextEditingController(text: profile['age']?.toString() ?? '');
    _height = TextEditingController(text: profile['height']?.toString() ?? '');
    _weight = TextEditingController(text: profile['weight']?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _save() {
    final ageText = _age.text.trim();
    final heightText = _height.text.trim();
    final weightText = _weight.text.trim();

    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final height = heightText.isEmpty ? null : double.tryParse(heightText);
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);

    if (ageText.isNotEmpty && age == null) {
      setState(() => _error = 'Enter a valid age');
      return;
    }
    if (heightText.isNotEmpty && height == null) {
      setState(() => _error = 'Enter a valid height');
      return;
    }
    if (weightText.isNotEmpty && weight == null) {
      setState(() => _error = 'Enter a valid weight');
      return;
    }
    if (weight != null && (weight < 20 || weight > 400)) {
      setState(() => _error = 'Weight should be between 20 and 400');
      return;
    }

    Navigator.pop(
      context,
      _ProfileEditResult(
        name: _name.text.trim(),
        age: age,
        height: height,
        weight: weight,
      ),
    );
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
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_name, 'Name'),
            _field(_age, 'Age', number: true),
            _field(_height, 'Height (cm)', number: true),
            _field(_weight, 'Weight (kg)', number: true),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.coral, fontSize: 13),
              ),
            ],
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
