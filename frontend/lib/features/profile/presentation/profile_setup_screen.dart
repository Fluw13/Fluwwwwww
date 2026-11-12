import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/daily_targets.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/presentation/basic_info_section.dart';
import 'package:fluw/features/profile/presentation/body_goal_section.dart';
import 'package:fluw/features/profile/presentation/conditions_section.dart';
import 'package:fluw/features/profile/presentation/daily_targets_view.dart';
import 'package:fluw/features/profile/presentation/profile_draft.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _targetWeight;
  late final TextEditingController _conditionNote;
  Sex? _sex;
  BmrFormula? _bmrFormula;
  CalendarDate? _birthDate;
  ActivityLevel? _activityLevel;
  TrainingType? _trainingType;
  double? _weeklyChangeKg;
  Set<HealthCondition> _conditions = const {};
  bool _limitsSugar = false;

  /// Errors stay hidden until the first save attempt, then follow every change.
  bool _showsErrors = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final saved = switch (ref.read(storedProfileProvider).value) {
      LoadedProfile(:final profile) => ProfileDraft.fromProfile(profile),
      _ => const ProfileDraft(),
    };
    _name = _controller(saved.displayName);
    _height = _controller(saved.heightText);
    _weight = _controller(saved.weightText);
    _targetWeight = _controller(saved.targetWeightText);
    _conditionNote = _controller(saved.conditionNote);
    _sex = saved.sex;
    _bmrFormula = saved.bmrFormulaForOther;
    _birthDate = saved.birthDate;
    _activityLevel = saved.activityLevel;
    _trainingType = saved.trainingType;
    _weeklyChangeKg = saved.weeklyChangeKg;
    _conditions = saved.conditions;
    _limitsSugar = saved.limitsSugar;
  }

  TextEditingController _controller(String text) => TextEditingController(text: text)..addListener(_markChanged);

  @override
  void dispose() {
    for (final controller in [_name, _height, _weight, _targetWeight, _conditionNote]) {
      controller.dispose();
    }
    super.dispose();
  }

  ProfileDraft get _draft => ProfileDraft(
    displayName: _name.text,
    sex: _sex,
    bmrFormulaForOther: _bmrFormula,
    birthDate: _birthDate,
    heightText: _height.text,
    weightText: _weight.text,
    targetWeightText: _targetWeight.text,
    activityLevel: _activityLevel,
    trainingType: _trainingType,
    weeklyChangeKg: _weeklyChangeKg,
    conditions: _conditions,
    conditionNote: _conditionNote.text,
    limitsSugar: _limitsSugar,
  );

  void _markChanged() => setState(() => _hasChanges = true);

  void _update(VoidCallback change) => setState(() {
    change();
    _hasChanges = true;
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final draft = _draft;
    final result = draft.toProfile(today: today);
    final errors = _showsErrors && result is DraftInvalid ? result.errors : const <ProfileField, String>{};

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thiết lập hồ sơ'),
          actions: [TextButton(onPressed: _isSaving ? null : _save, child: const Text('Lưu'))],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            BasicInfoSection(
              nameController: _name,
              sex: _sex,
              onSexChanged: (sex) => _update(() => _sex = sex),
              bmrFormula: _bmrFormula,
              onBmrFormulaChanged: (formula) => _update(() => _bmrFormula = formula),
              birthDate: _birthDate,
              onBirthDateChanged: (date) => _update(() => _birthDate = date),
              today: today,
              errors: errors,
            ),
            const SizedBox(height: AppSpacing.md),
            BodyGoalSection(
              heightController: _height,
              weightController: _weight,
              targetWeightController: _targetWeight,
              goal: draft.goal,
              showsWeeklyChange: draft.needsWeeklyChange(today: today),
              weeklyChangeKg: _weeklyChangeKg,
              onWeeklyChangeChanged: (kg) => _update(() => _weeklyChangeKg = kg),
              activityLevel: _activityLevel,
              onActivityLevelChanged: (level) => _update(() => _activityLevel = level),
              trainingType: _trainingType,
              onTrainingTypeChanged: (type) => _update(() => _trainingType = type),
              errors: errors,
            ),
            const SizedBox(height: AppSpacing.md),
            ConditionsSection(
              conditions: _conditions,
              onConditionChanged: (condition, {required selected}) => _update(
                () => _conditions = selected ? {..._conditions, condition} : ({..._conditions}..remove(condition)),
              ),
              noteController: _conditionNote,
              limitsSugar: _limitsSugar,
              onLimitsSugarChanged: (value) => _update(() => _limitsSugar = value),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'Chỉ tiêu mỗi ngày (xem trước)',
              children: [
                switch (result) {
                  DraftValid(:final profile) => DailyTargetsView(targets: calculateDailyTargets(profile, today: today)),
                  DraftInvalid() => Text(
                    'Điền đủ thông tin ở trên để xem calo, protein, đường và nước mỗi ngày.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                },
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Lưu hồ sơ'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hồ sơ chỉ lưu trên máy này và sửa lại được bất cứ lúc nào.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final result = _draft.toProfile(today: ref.read(todayProvider));
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case DraftInvalid(:final errors):
        setState(() => _showsErrors = true);
        messenger.showSnackBar(SnackBar(content: Text('Còn ${errors.length} mục cần sửa trước khi lưu.')));
      case DraftValid(:final profile):
        setState(() => _isSaving = true);
        try {
          await ref.read(profileRepositoryProvider).save(profile);
        } on Object {
          if (mounted) {
            setState(() => _isSaving = false);
            messenger.showSnackBar(const SnackBar(content: Text('Không lưu được hồ sơ. Hãy thử lại.')));
          }
          return;
        }
        if (mounted) {
          setState(() => _hasChanges = false);
          messenger.showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ.')));
          Navigator.of(context).pop();
        }
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ các thay đổi?'),
        content: const Text('Những gì bạn vừa nhập sẽ không được lưu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Tiếp tục sửa')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Bỏ thay đổi')),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _hasChanges = false);
      Navigator.of(context).pop();
    }
  }
}
