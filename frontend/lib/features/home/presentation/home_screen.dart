import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/diary/diary_day.dart';
import 'package:fluw/core/diary/diary_target.dart';
import 'package:fluw/core/nutrition/nutrient_totals.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/features/home/domain/day_evaluation.dart';
import 'package:fluw/features/home/domain/nutrition_advice.dart';
import 'package:fluw/features/home/presentation/advice_card.dart';
import 'package:fluw/features/home/presentation/day_evaluation_card.dart';
import 'package:fluw/features/home/presentation/greeting_card.dart';
import 'package:fluw/features/home/presentation/quick_actions.dart';
import 'package:fluw/features/home/presentation/today_meals_card.dart';
import 'package:fluw/features/home/presentation/today_nutrition_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.onOpenSearch,
    required this.onOpenScan,
    required this.onOpenNote,
    required this.onSetupProfile,
    super.key,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenNote;
  final VoidCallback onSetupProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final limits = ref.watch(personalLimitsProvider);
    final todayDiary = ref.watch(diaryDayProvider(today));
    final yesterday = ref.watch(diaryDayProvider(today.addDays(-1))).value;
    final todayDay = todayDiary.value;
    final totals = todayDay?.day?.dayTotal ?? NutrientTotals.of(const []);
    final entryCount = todayDay?.entryCount ?? 0;
    final yesterdayEvaluation = yesterday?.day == null
        ? null
        : evaluateDay(totals: yesterday!.day!.dayTotal, entryCount: yesterday.entryCount, limits: limits);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        GreetingCard(limits: limits, onSetupProfile: onSetupProfile),
        const SizedBox(height: AppSpacing.md),
        if (todayDiary.hasError)
          Text(
            'Không đọc được Nhật ký trên máy. Thử mở lại app.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        else ...[
          TodayNutritionCard(totals: totals, entryCount: entryCount, limits: limits),
          const SizedBox(height: AppSpacing.md),
          TodayMealsCard(
            day: todayDay?.day,
            unreadableCount: todayDay?.unreadableCount ?? 0,
            onAddFood: (slot) {
              ref.read(diaryTargetProvider.notifier).choose(DiaryTarget(day: today, slot: slot));
              onOpenSearch();
            },
            onOpenNote: onOpenNote,
          ),
        ],
        if (yesterdayEvaluation != null && yesterdayEvaluation.verdicts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          DayEvaluationCard(title: 'Đánh giá hôm qua', evaluation: yesterdayEvaluation),
        ],
        const SizedBox(height: AppSpacing.md),
        AdviceCard(
          advice: adviceFor(limits: limits, today: totals, entryCount: entryCount, now: DateTime.now()),
        ),
        const SizedBox(height: AppSpacing.md),
        QuickActions(onOpenScan: onOpenScan, onOpenSearch: onOpenSearch),
      ],
    );
  }
}
