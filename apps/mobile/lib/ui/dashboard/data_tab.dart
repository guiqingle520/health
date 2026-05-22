import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/history_items.dart';
import '../../data/models/views.dart';
import '../../data/utils/diet_helpers.dart';
import '../../data/utils/formatters.dart';
import '../components/app_screen.dart';
import '../components/choice_chip_button.dart';
import '../components/info_chip.dart';
import '../components/prototype_card.dart';
import '../components/section_header.dart';
import '../shared/record_detail_sheet.dart';

/// 数据中心页，承接趋势、饮食历史和运动历史三类内容。
class DataTab extends StatefulWidget {
  const DataTab({
    super.key,
    required this.data,
    required this.weightTrend,
    required this.heartRateTrend,
    required this.dietHistory,
    required this.exerciseHistory,
    required this.historyLoading,
    required this.historyError,
    required this.onRefreshHistory,
    required this.onDeleteDietRecord,
    required this.onDeleteExerciseRecord,
  });

  final DashboardView data;
  final HealthTrendView? weightTrend;
  final HealthTrendView? heartRateTrend;
  final List<DietHistoryItem> dietHistory;
  final List<ExerciseHistoryItem> exerciseHistory;
  final bool historyLoading;
  final String? historyError;
  final Future<void> Function({String? mealType, String? exerciseType})
      onRefreshHistory;
  final Future<void> Function(String id, {String? mealType, String? exerciseType})
      onDeleteDietRecord;
  final Future<void> Function(String id, {String? mealType, String? exerciseType})
      onDeleteExerciseRecord;

  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  int _selectedSegment = 0;
  String? _selectedMealType;
  String? _selectedExerciseType;

  Future<void> _refreshCurrentHistory() {
    return widget.onRefreshHistory(
      mealType: _selectedMealType,
      exerciseType: _selectedExerciseType,
    );
  }

  void _selectMealType(String? mealType) {
    setState(() => _selectedMealType = mealType);
    widget.onRefreshHistory(
      mealType: mealType,
      exerciseType: _selectedExerciseType,
    );
  }

  void _selectExerciseType(String? exerciseType) {
    setState(() => _selectedExerciseType = exerciseType);
    widget.onRefreshHistory(
      mealType: _selectedMealType,
      exerciseType: exerciseType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final weight = widget.weightTrend ??
        HealthTrendView.fallback(
          metric: 'weight',
          currentValue: 70.7,
          delta: -1,
          unit: 'kg',
          values: const [71.7, 71.4, 71.0, 71.2, 70.8, 70.5, 70.7],
          message: '本周体重变化 -1.0kg，继续关注饮食和运动节奏。',
        );
    final heartRate = widget.heartRateTrend ??
        HealthTrendView.fallback(
          metric: 'heartRate',
          currentValue: 76,
          delta: 2.4,
          unit: 'bpm',
          values: const [73, 75, 74, 76, 78, 77, 76],
          message: '本周静息心率有波动，建议结合睡眠和运动恢复观察。',
        );

    return AppScreen(
      bottomPadding: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            eyebrow: '健康数据',
            title: '数据中心',
            subtitle: '查看趋势、饮食记录和运动记录。',
          ),
          const SizedBox(height: 16),
          _SegmentedTabs(
            labels: const ['趋势', '饮食', '运动'],
            selectedIndex: _selectedSegment,
            onChanged: (index) => setState(() => _selectedSegment = index),
          ),
          const SizedBox(height: 16),
          switch (_selectedSegment) {
            0 => Column(
                children: [
                  _TrendCard(
                    title: '平均体重',
                    trend: weight,
                    badgeColor: mintColor,
                  ),
                  const SizedBox(height: 14),
                  _TrendCard(
                    title: '静息心率',
                    trend: heartRate,
                    badgeColor: const Color(0xFFFFF0E6),
                    footer:
                        '结合今日 ${widget.data.steps} 步和睡眠 ${widget.data.sleepHours.toStringAsFixed(1)}h，建议观察晚间恢复。',
                  ),
                ],
              ),
            1 => _DietHistorySection(
                date: widget.data.date,
                items: widget.dietHistory,
                loading: widget.historyLoading,
                error: widget.historyError,
                selectedMealType: _selectedMealType,
                onMealTypeChanged: _selectMealType,
                onRetry: _refreshCurrentHistory,
                onDelete: (id) => widget.onDeleteDietRecord(
                  id,
                  mealType: _selectedMealType,
                  exerciseType: _selectedExerciseType,
                ),
              ),
            _ => _ExerciseHistorySection(
                date: widget.data.date,
                items: widget.exerciseHistory,
                loading: widget.historyLoading,
                error: widget.historyError,
                selectedExerciseType: _selectedExerciseType,
                onExerciseTypeChanged: _selectExerciseType,
                onRetry: _refreshCurrentHistory,
                onDelete: (id) => widget.onDeleteExerciseRecord(
                  id,
                  mealType: _selectedMealType,
                  exerciseType: _selectedExerciseType,
                ),
              ),
          },
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selectedIndex == i ? Colors.white : Colors.transparent,
                    boxShadow: selectedIndex == i
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selectedIndex == i ? primaryDarkColor : mutedTextColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DietHistorySection extends StatelessWidget {
  const _DietHistorySection({
    required this.date,
    required this.items,
    required this.loading,
    required this.error,
    required this.selectedMealType,
    required this.onMealTypeChanged,
    required this.onRetry,
    required this.onDelete,
  });

  final String date;
  final List<DietHistoryItem> items;
  final bool loading;
  final String? error;
  final String? selectedMealType;
  final ValueChanged<String?> onMealTypeChanged;
  final Future<void> Function() onRetry;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final filters = _HistoryFilterChips(
      options: const [
        _HistoryFilterOption(label: '全部', value: null),
        _HistoryFilterOption(label: '早餐', value: 'breakfast'),
        _HistoryFilterOption(label: '午餐', value: 'lunch'),
        _HistoryFilterOption(label: '晚餐', value: 'dinner'),
        _HistoryFilterOption(label: '加餐', value: 'snack'),
      ],
      selectedValue: selectedMealType,
      onChanged: onMealTypeChanged,
    );

    if (loading && items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: 12),
          const _HistoryLoadingCard(label: '正在加载饮食记录...'),
        ],
      );
    }
    if (error != null && items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: 12),
          _HistoryErrorCard(message: error!, onRetry: onRetry),
        ],
      );
    }
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: 12),
          const _HistoryEmptyState(
            icon: Icons.restaurant_rounded,
            title: '暂无饮食记录',
            subtitle: '去 AI 建议页添加早餐、午餐、晚餐或加餐记录，保存后会在这里汇总。',
          ),
        ],
      );
    }

    final todayItems = items.where((item) => item.recordedOn == date).toList();
    final summaryItems = todayItems.isEmpty ? items : todayItems;
    final calories = summaryItems.fold<double>(
      0,
      (sum, item) => sum + nutritionNumber(item.nutrition, 'calories'),
    );
    final protein = summaryItems.fold<double>(
      0,
      (sum, item) => sum + nutritionNumber(item.nutrition, 'protein'),
    );
    final carbs = summaryItems.fold<double>(
      0,
      (sum, item) => sum + nutritionNumber(item.nutrition, 'carbs'),
    );
    final fat = summaryItems.fold<double>(
      0,
      (sum, item) => sum + nutritionNumber(item.nutrition, 'fat'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters,
        const SizedBox(height: 12),
        if (loading) ...[
          const LinearProgressIndicator(
            minHeight: 3,
            color: primaryColor,
            backgroundColor: mintColor,
          ),
          const SizedBox(height: 12),
        ],
        if (error case final error?) ...[
          _HistoryErrorCard(message: error, onRetry: onRetry),
          const SizedBox(height: 12),
        ],
        PrototypeCard(
          color: softMintColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todayItems.isEmpty ? '近 30 天饮食汇总' : '今日饮食汇总',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HistorySummaryTile(
                      value: '${summaryItems.length}',
                      label: '记录',
                    ),
                  ),
                  Expanded(
                    child: _HistorySummaryTile(
                      value: formatNumber(calories),
                      label: 'kcal',
                    ),
                  ),
                  Expanded(
                    child: _HistorySummaryTile(
                      value: '${formatNumber(protein)}g',
                      label: '蛋白质',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '碳水 ${formatNumber(carbs)}g · 脂肪 ${formatNumber(fat)}g',
                style: const TextStyle(color: mutedTextColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('最近饮食记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DietHistoryCard(
              item: item,
              onTap: () => showDietDetailSheet(context, item, onDelete),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseHistorySection extends StatelessWidget {
  const _ExerciseHistorySection({
    required this.date,
    required this.items,
    required this.loading,
    required this.error,
    required this.selectedExerciseType,
    required this.onExerciseTypeChanged,
    required this.onRetry,
    required this.onDelete,
  });

  final String date;
  final List<ExerciseHistoryItem> items;
  final bool loading;
  final String? error;
  final String? selectedExerciseType;
  final ValueChanged<String?> onExerciseTypeChanged;
  final Future<void> Function() onRetry;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final filters = _HistoryFilterChips(
      options: const [
        _HistoryFilterOption(label: '全部', value: null),
        _HistoryFilterOption(label: '有氧', value: 'aerobic'),
        _HistoryFilterOption(label: '力量', value: 'strength'),
        _HistoryFilterOption(label: '拉伸', value: 'flexibility'),
      ],
      selectedValue: selectedExerciseType,
      onChanged: onExerciseTypeChanged,
    );

    if (loading && items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: 12),
          const _HistoryLoadingCard(label: '正在加载运动记录...'),
        ],
      );
    }
    if (error != null && items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: 12),
          _HistoryErrorCard(message: error!, onRetry: onRetry),
        ],
      );
    }
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          const SizedBox(height: 12),
          const _HistoryEmptyState(
            icon: Icons.directions_run_rounded,
            title: '暂无运动记录',
            subtitle: '记录一次散步、力量训练或拉伸后，会自动生成运动历史和消耗汇总。',
          ),
        ],
      );
    }

    final todayItems = items.where((item) => item.recordedOn == date).toList();
    final summaryItems = todayItems.isEmpty ? items : todayItems;
    final duration = summaryItems.fold<int>(0, (sum, item) => sum + item.durationMinutes);
    final burned = summaryItems.fold<num>(0, (sum, item) => sum + item.caloriesBurned);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters,
        const SizedBox(height: 12),
        if (loading) ...[
          const LinearProgressIndicator(
            minHeight: 3,
            color: primaryColor,
            backgroundColor: mintColor,
          ),
          const SizedBox(height: 12),
        ],
        if (error case final error?) ...[
          _HistoryErrorCard(message: error, onRetry: onRetry),
          const SizedBox(height: 12),
        ],
        PrototypeCard(
          color: softMintColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todayItems.isEmpty ? '近 30 天运动汇总' : '今日运动汇总',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HistorySummaryTile(
                      value: '${summaryItems.length}',
                      label: '记录',
                    ),
                  ),
                  Expanded(
                    child: _HistorySummaryTile(value: '$duration', label: '分钟'),
                  ),
                  Expanded(
                    child: _HistorySummaryTile(
                      value: formatNumber(burned),
                      label: 'kcal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('最近运动记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ExerciseHistoryCard(
              item: item,
              onTap: () => showExerciseDetailSheet(context, item, onDelete),
            ),
          ),
        ),
      ],
    );
  }
}

class _DietHistoryCard extends StatelessWidget {
  const _DietHistoryCard({required this.item, required this.onTap});

  final DietHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final calories = nutritionNumber(item.nutrition, 'calories');
    final protein = nutritionNumber(item.nutrition, 'protein');
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: PrototypeCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _HistoryIcon(icon: Icons.restaurant_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.foodName,
                      style: const TextStyle(color: textColor, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${mealTypeLabel(item.mealType)} · ${formatDateLabel(item.recordedOn)} · 蛋白质 ${formatNumber(protein)}g',
                    style: const TextStyle(color: mutedTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${formatNumber(calories)} kcal',
              style: const TextStyle(color: primaryDarkColor, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseHistoryCard extends StatelessWidget {
  const _ExerciseHistoryCard({required this.item, required this.onTap});

  final ExerciseHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: PrototypeCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _HistoryIcon(icon: Icons.directions_run_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exerciseTypeLabel(item.exerciseType),
                    style: const TextStyle(color: textColor, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDateLabel(item.recordedOn)} · ${item.durationMinutes} 分钟',
                    style: const TextStyle(color: mutedTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${formatNumber(item.caloriesBurned)} kcal',
              style: const TextStyle(color: primaryDarkColor, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFilterOption {
  const _HistoryFilterOption({required this.label, required this.value});

  final String label;
  final String? value;
}

class _HistoryFilterChips extends StatelessWidget {
  const _HistoryFilterChips({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<_HistoryFilterOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChipButton(
              label: option.label,
              selected: option.value == selectedValue,
              onTap: () => onChanged(option.value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _HistorySummaryTile extends StatelessWidget {
  const _HistorySummaryTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: mutedTextColor, fontSize: 12)),
      ],
    );
  }
}

class _HistoryIcon extends StatelessWidget {
  const _HistoryIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: mintColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: primaryDarkColor, size: 21),
    );
  }
}

class _HistoryLoadingCard extends StatelessWidget {
  const _HistoryLoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: mutedTextColor)),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      color: softMintColor,
      child: Column(
        children: [
          _HistoryIcon(icon: icon),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedTextColor, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorCard extends StatelessWidget {
  const _HistoryErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      color: const Color(0xFFFFF0E6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoChip(
            label: '记录历史加载失败',
            icon: Icons.warning_amber_rounded,
            color: Color(0xFFFFF8ED),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: mutedTextColor, height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryDarkColor,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.trend,
    required this.badgeColor,
    this.footer,
  });

  final String title;
  final HealthTrendView trend;
  final Color badgeColor;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final deltaPrefix = trend.delta > 0
        ? '↑'
        : trend.delta < 0
            ? '↓'
            : '—';
    final badge = '$deltaPrefix ${trend.delta.abs().toStringAsFixed(1)} ${trend.unit}';
    final signal = trend.signals.isEmpty ? null : trend.signals.first.message;

    return PrototypeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              InfoChip(label: badge, color: badgeColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${trend.currentValue.toStringAsFixed(trend.unit == 'kg' ? 1 : 0)} ${trend.unit}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 110, child: _MiniTrendChart(points: trend.points)),
          if (signal case final signal?) ...[
            const SizedBox(height: 12),
            InfoChip(
              label: signal,
              icon: trend.signals.first.level == 'warning'
                  ? Icons.warning_amber_rounded
                  : Icons.insights_rounded,
              color: trend.signals.first.level == 'warning'
                  ? const Color(0xFFFFF0E6)
                  : softMintColor,
            ),
          ],
          if (footer case final footer?) ...[
            const SizedBox(height: 12),
            Text(footer, style: const TextStyle(color: mutedTextColor, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  const _MiniTrendChart({required this.points});

  final List<HealthTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniTrendChartPainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class _MiniTrendChartPainter extends CustomPainter {
  _MiniTrendChartPainter(this.points);

  final List<HealthTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    final values = points.map((point) => point.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 1);
    final chartPoints = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width : size.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / range;
      final y = size.height - normalized * (size.height * 0.78) - size.height * 0.10;
      chartPoints.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (final point in chartPoints.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(chartPoints.last.dx, size.height)
      ..lineTo(chartPoints.first.dx, size.height)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.22),
            primaryColor.withValues(alpha: 0.03),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = chartPoints.last;
    canvas.drawCircle(last, 6, Paint()..color = Colors.white);
    canvas.drawCircle(last, 4, Paint()..color = primaryColor);
  }

  @override
  bool shouldRepaint(covariant _MiniTrendChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
