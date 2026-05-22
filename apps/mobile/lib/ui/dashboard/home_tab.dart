import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/views.dart';
import '../components/app_screen.dart';
import '../components/prototype_card.dart';
import '../components/section_header.dart';

/// 首页标签页，突出今日健康分与核心指标摘要。
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.onGoAi,
    required this.message,
  });

  final DashboardView data;
  final Future<void> Function() onRefresh;
  final VoidCallback onGoAi;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primaryColor,
      child: AppScreen(
        bottomPadding: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              eyebrow: '首页',
              title: '今日健康',
              subtitle: '快速了解今天的关键状态。',
            ),
            const SizedBox(height: 18),
            HealthScoreHero(data: data, onGoAi: onGoAi),
            if (message case final message?) ...[
              const SizedBox(height: 12),
              _InlineInfoChip(label: message, icon: Icons.check_circle_rounded),
            ],
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.28,
              children: [
                _MetricTile(
                  icon: Icons.directions_walk_rounded,
                  title: '步数',
                  value: '${data.steps}',
                  subtitle: '目标 ${data.stepTarget}',
                ),
                _MetricTile(
                  icon: Icons.bedtime_rounded,
                  title: '睡眠',
                  value: '${data.sleepHours.toStringAsFixed(1)}h',
                  subtitle: '睡眠分 ${data.sleepScore}',
                ),
                _MetricTile(
                  icon: Icons.water_drop_rounded,
                  title: '喝水',
                  value: '${(data.waterMl / 1000).toStringAsFixed(1)}L',
                  subtitle: '目标 ${(data.waterTargetMl / 1000).toStringAsFixed(1)}L',
                ),
                _MetricTile(
                  icon: Icons.local_fire_department_rounded,
                  title: '热量',
                  value: '${data.calories}',
                  subtitle: '目标 ${data.calorieTarget} kcal',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const PrototypeCard(
              color: softMintColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InlineInfoChip(label: '陪伴摘要', icon: Icons.pets_rounded),
                  SizedBox(height: 12),
                  Text(
                    '今日互动 2 次，情绪趋势 +1.5。适合在晚间安排 20 分钟轻步行，保持稳定节奏。',
                    style: TextStyle(height: 1.45, color: textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrototypeCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: mintColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: primaryDarkColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.aiInsights.isEmpty
                          ? '晚餐前补水 300ml，睡前提前 20 分钟放松。'
                          : data.aiInsights.first,
                      style: const TextStyle(color: textColor, height: 1.35, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首页健康分主卡，保留原有问候、日期和建议跳转入口。
class HealthScoreHero extends StatelessWidget {
  const HealthScoreHero({super.key, required this.data, required this.onGoAi});

  final DashboardView data;
  final VoidCallback onGoAi;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '早安，${data.nickname}',
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: textColor),
                ),
                const SizedBox(height: 8),
                Text('${data.date} 状态平稳', style: const TextStyle(color: mutedTextColor)),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryDarkColor,
                    side: const BorderSide(color: lineColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: onGoAi,
                  icon: const Icon(Icons.lightbulb_rounded, size: 18),
                  label: const Text('查看建议'),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: data.healthScore.clamp(0, 100) / 100,
                  strokeWidth: 10,
                  backgroundColor: mintColor,
                  color: primaryColor,
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${data.healthScore}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: textColor),
                    ),
                    const Text('健康分', style: TextStyle(color: mutedTextColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: mintColor, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: primaryDarkColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: mutedTextColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(color: textColor, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: mutedTextColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineInfoChip extends StatelessWidget {
  const _InlineInfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: mintColor, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryDarkColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: primaryDarkColor, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
