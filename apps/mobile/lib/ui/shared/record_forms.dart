import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/inputs.dart';
import '../components/primary_action_button.dart';
import '../components/prototype_card.dart';

/// 饮食记录表单卡片，保持 AI 建议页中的手动录入体验不变。
class DietRecordCard extends StatefulWidget {
  const DietRecordCard({
    super.key,
    required this.onSubmit,
    required this.submitting,
    required this.message,
  });

  final Future<void> Function(DietRecordInput input) onSubmit;
  final bool submitting;
  final String? message;

  @override
  State<DietRecordCard> createState() => _DietRecordCardState();
}

class _DietRecordCardState extends State<DietRecordCard> {
  final TextEditingController _foodNameController = TextEditingController(text: '鸡胸肉沙拉');
  final TextEditingController _caloriesController = TextEditingController(text: '420');
  final TextEditingController _proteinController = TextEditingController(text: '35');
  String _mealType = 'lunch';
  String? _error;

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('记录饮食', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mealType,
            items: const [
              DropdownMenuItem(value: 'breakfast', child: Text('早餐')),
              DropdownMenuItem(value: 'lunch', child: Text('午餐')),
              DropdownMenuItem(value: 'dinner', child: Text('晚餐')),
              DropdownMenuItem(value: 'snack', child: Text('加餐')),
            ],
            onChanged: widget.submitting ? null : (value) => setState(() => _mealType = value ?? 'lunch'),
            decoration: const InputDecoration(labelText: '餐次'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _foodNameController,
            enabled: !widget.submitting,
            decoration: const InputDecoration(labelText: '食物名称'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _caloriesController,
                  enabled: !widget.submitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '热量'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _proteinController,
                  enabled: !widget.submitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '蛋白质'),
                ),
              ),
            ],
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: widget.submitting ? '保存中...' : '保存饮食记录',
            onPressed: widget.submitting ? null : _submit,
          ),
          if (widget.message case final message?) ...[
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: primaryDarkColor, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final foodName = _foodNameController.text.trim();
    final calories = double.tryParse(_caloriesController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());

    if (foodName.isEmpty) {
      setState(() => _error = '请输入食物名称');
      return;
    }
    if (calories == null || calories < 0) {
      setState(() => _error = '请输入不小于 0 的热量');
      return;
    }
    if (protein == null || protein < 0) {
      setState(() => _error = '请输入不小于 0 的蛋白质');
      return;
    }

    setState(() => _error = null);
    await widget.onSubmit(
      DietRecordInput(mealType: _mealType, foodName: foodName, calories: calories, protein: protein),
    );

    if (!mounted) {
      return;
    }

    _foodNameController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    setState(() => _mealType = 'lunch');
  }
}

/// 运动记录表单卡片，保持 AI 建议页中的手动录入体验不变。
class ExerciseRecordCard extends StatefulWidget {
  const ExerciseRecordCard({super.key, required this.onSubmit, required this.submitting});

  final Future<void> Function(ExerciseRecordInput input) onSubmit;
  final bool submitting;

  @override
  State<ExerciseRecordCard> createState() => _ExerciseRecordCardState();
}

class _ExerciseRecordCardState extends State<ExerciseRecordCard> {
  final TextEditingController _durationController = TextEditingController(text: '40');
  final TextEditingController _caloriesBurnedController = TextEditingController(text: '360');
  String _exerciseType = 'aerobic';
  String? _error;

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesBurnedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('记录运动', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _exerciseType,
            items: const [
              DropdownMenuItem(value: 'aerobic', child: Text('有氧')),
              DropdownMenuItem(value: 'strength', child: Text('力量')),
              DropdownMenuItem(value: 'flexibility', child: Text('柔韧')),
            ],
            onChanged: widget.submitting ? null : (value) => setState(() => _exerciseType = value ?? 'aerobic'),
            decoration: const InputDecoration(labelText: '运动类型'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _durationController,
                  enabled: !widget.submitting,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '时长'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _caloriesBurnedController,
                  enabled: !widget.submitting,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '消耗'),
                ),
              ),
            ],
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: widget.submitting ? '保存中...' : '保存运动记录',
            onPressed: widget.submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final duration = int.tryParse(_durationController.text.trim());
    final caloriesBurned = double.tryParse(_caloriesBurnedController.text.trim());

    if (duration == null || duration <= 0) {
      setState(() => _error = '请输入大于 0 的运动时长');
      return;
    }
    if (caloriesBurned == null || caloriesBurned < 0) {
      setState(() => _error = '请输入不小于 0 的消耗热量');
      return;
    }

    setState(() => _error = null);
    await widget.onSubmit(
      ExerciseRecordInput(
        exerciseType: _exerciseType,
        durationMinutes: duration,
        caloriesBurned: caloriesBurned,
      ),
    );

    if (!mounted) {
      return;
    }

    _durationController.clear();
    _caloriesBurnedController.clear();
    setState(() => _exerciseType = 'aerobic');
  }
}
