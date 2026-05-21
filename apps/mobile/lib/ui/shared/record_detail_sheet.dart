import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/history_items.dart';
import '../../data/utils/diet_helpers.dart';
import '../../data/utils/formatters.dart';
import '../components/prototype_card.dart';

/// 饮食记录详情底部抽屉，展示营养素并支持删除操作。
Future<void> showDietDetailSheet(
  BuildContext context,
  DietHistoryItem item,
  Future<void> Function(String id) onDelete,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RecordDetailSheet(
      title: item.foodName,
      subtitle: '${mealTypeLabel(item.mealType)} · ${formatDateLabel(item.recordedOn)}',
      rows: [
        DetailRow(
          label: '热量',
          value: '${formatNumber(nutritionNumber(item.nutrition, 'calories'))} kcal',
        ),
        DetailRow(
          label: '蛋白质',
          value: '${formatNumber(nutritionNumber(item.nutrition, 'protein'))} g',
        ),
        DetailRow(
          label: '碳水',
          value: '${formatNumber(nutritionNumber(item.nutrition, 'carbs'))} g',
        ),
        DetailRow(label: '脂肪', value: '${formatNumber(nutritionNumber(item.nutrition, 'fat'))} g'),
        DetailRow(label: '纤维', value: '${formatNumber(nutritionNumber(item.nutrition, 'fiber'))} g'),
        DetailRow(label: '钠', value: '${formatNumber(nutritionNumber(item.nutrition, 'sodiumMg'))} mg'),
        DetailRow(label: '钙', value: '${formatNumber(nutritionNumber(item.nutrition, 'calciumMg'))} mg'),
        DetailRow(label: '铁', value: '${formatNumber(nutritionNumber(item.nutrition, 'ironMg'))} mg'),
        DetailRow(label: '维A', value: '${formatNumber(nutritionNumber(item.nutrition, 'vitaminAMcg'))} mcg'),
        DetailRow(label: '维C', value: '${formatNumber(nutritionNumber(item.nutrition, 'vitaminCMg'))} mg'),
        DetailRow(label: '维D', value: '${formatNumber(nutritionNumber(item.nutrition, 'vitaminDIU'))} IU'),
      ],
      onDelete: () => _confirmDeleteRecord(context, onDelete: () => onDelete(item.id)),
    ),
  );
}

/// 运动记录详情底部抽屉，展示时长和消耗并支持删除操作。
Future<void> showExerciseDetailSheet(
  BuildContext context,
  ExerciseHistoryItem item,
  Future<void> Function(String id) onDelete,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RecordDetailSheet(
      title: exerciseTypeLabel(item.exerciseType),
      subtitle: formatDateLabel(item.recordedOn),
      rows: [
        DetailRow(label: '运动类型', value: exerciseTypeLabel(item.exerciseType)),
        DetailRow(label: '时长', value: '${item.durationMinutes} 分钟'),
        DetailRow(label: '消耗热量', value: '${formatNumber(item.caloriesBurned)} kcal'),
      ],
      onDelete: () => _confirmDeleteRecord(context, onDelete: () => onDelete(item.id)),
    ),
  );
}

/// 确认删除对话框，避免误操作导致数据丢失。
Future<void> _confirmDeleteRecord(
  BuildContext context, {
  required Future<void> Function() onDelete,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除这条记录？'),
      content: const Text('删除后会影响首页 dashboard、趋势、AI 建议和报告的基础数据。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('确认删除'),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    return;
  }

  try {
    await onDelete();
    if (navigator.canPop()) {
      navigator.pop();
    }
    messenger.showSnackBar(const SnackBar(content: Text('记录已删除')));
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('删除失败：$error')));
  }
}

/// 记录详情展示卡片的公共底部抽屉组件。
class RecordDetailSheet extends StatelessWidget {
  const RecordDetailSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final List<DetailRow> rows;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: mutedTextColor, height: 1.4)),
            const SizedBox(height: 16),
            PrototypeCard(
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    _DetailRowView(row: rows[i]),
                    if (i != rows.length - 1) const Divider(height: 18, color: lineColor),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD95C4F),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('删除记录'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailRow {
  const DetailRow({required this.label, required this.value});

  final String label;
  final String value;
}

class _DetailRowView extends StatelessWidget {
  const _DetailRowView({required this.row});

  final DetailRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(row.label, style: const TextStyle(color: mutedTextColor, fontSize: 14)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            row.value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}