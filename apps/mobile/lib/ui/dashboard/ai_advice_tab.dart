import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/inputs.dart';
import '../../data/models/views.dart';
import '../components/app_screen.dart';
import '../components/info_chip.dart';
import '../components/prototype_card.dart';
import '../components/section_header.dart';
import '../shared/record_forms.dart';

/// AI 建议页，集中展示今日推荐并保留手动记录入口。
class AiAdviceTab extends StatelessWidget {
  const AiAdviceTab({
    super.key,
    required this.data,
    required this.recommendations,
    required this.onSubmitDietRecord,
    required this.onSubmitExerciseRecord,
    required this.submittingDietRecord,
    required this.submittingExerciseRecord,
    required this.message,
  });

  final DashboardView data;
  final AiRecommendationsTodayView? recommendations;
  final Future<void> Function(DietRecordInput input) onSubmitDietRecord;
  final Future<void> Function(ExerciseRecordInput input) onSubmitExerciseRecord;
  final bool submittingDietRecord;
  final bool submittingExerciseRecord;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final items = recommendations?.items.isNotEmpty == true
        ? recommendations!.items
        : [
            AiRecommendation(
              id: '${data.date}:protein',
              type: 'diet',
              title: '晚餐补充优质蛋白',
              reason: data.aiInsights.isEmpty
                  ? '今日蛋白质偏低，晚餐建议补充鱼类或豆制品。'
                  : data.aiInsights.first,
              actionText: '记录晚餐',
              status: 'pending',
            ),
            const AiRecommendation(
              id: 'fallback:activity',
              type: 'exercise',
              title: '增加 20 分钟轻有氧',
              reason: '运动消耗较少，建议增加散步、骑行或低强度有氧活动。',
              actionText: '记录运动',
              status: 'pending',
            ),
          ];

    return AppScreen(
      bottomPadding: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            eyebrow: '为你定制',
            title: 'AI 健康建议',
            subtitle: '结合今日饮食、运动和陪伴上下文。',
          ),
          const SizedBox(height: 16),
          const PrototypeCard(
            color: softMintColor,
            child: Row(
              children: [
                Icon(Icons.camera_alt_rounded, color: primaryDarkColor, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('拍照记录饮食', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('AI 自动估算热量与营养素，即将支持。', style: TextStyle(color: mutedTextColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PrototypeCard(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: mutedTextColor),
                SizedBox(width: 10),
                Expanded(child: Text('搜索食物 / 询问 AI...', style: TextStyle(color: mutedTextColor))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('今日 AI 推荐 · ${items.length} 条', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AdviceCard(recommendation: item),
            ),
          ),
          const SizedBox(height: 8),
          const Text('手动记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          DietRecordCard(
            onSubmit: onSubmitDietRecord,
            submitting: submittingDietRecord,
            message: message,
          ),
          const SizedBox(height: 12),
          ExerciseRecordCard(
            onSubmit: onSubmitExerciseRecord,
            submitting: submittingExerciseRecord,
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.recommendation});

  final AiRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final icon = switch (recommendation.type) {
      'exercise' => Icons.directions_run_rounded,
      'water' => Icons.water_drop_rounded,
      'sleep' => Icons.bedtime_rounded,
      _ => Icons.restaurant_rounded,
    };
    final label = switch (recommendation.type) {
      'exercise' => '运动',
      'water' => '饮水',
      'sleep' => '睡眠',
      _ => '饮食',
    };

    return PrototypeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: mintColor, borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: primaryDarkColor),
              ),
              const SizedBox(width: 12),
              InfoChip(label: label),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.title,
            style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(recommendation.reason, style: const TextStyle(color: mutedTextColor, height: 1.45)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryDarkColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {},
                  child: const Text('稍后再说'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {},
                  child: Text(recommendation.actionText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
