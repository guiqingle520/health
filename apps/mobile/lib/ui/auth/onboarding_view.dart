import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/inputs.dart';
import '../components/app_screen.dart';
import '../components/choice_chip_button.dart';
import '../components/primary_action_button.dart';
import '../components/prototype_card.dart';
import '../components/section_header.dart';

/// 首次建档页，引导用户填写基础健康信息以生成健康分和 AI 建议。
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.onSubmit});

  final Future<void> Function(OnboardingInput input) onSubmit;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final TextEditingController _nicknameController =
      TextEditingController(text: '张先生');
  final TextEditingController _ageController =
      TextEditingController(text: '30');
  final TextEditingController _heightController =
      TextEditingController(text: '175');
  final TextEditingController _weightController =
      TextEditingController(text: '72');
  String _gender = 'male';
  String _goal = 'maintain';
  String? _error;

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            eyebrow: '首次使用',
            title: '完善健康档案',
            subtitle: '用于生成每日健康分、饮食提醒和 AI 建议。',
          ),
          const SizedBox(height: 18),
          PrototypeCard(
            color: softMintColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '建档进度',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      '2 / 3 基础信息',
                      style: TextStyle(color: primaryDarkColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0.66,
                    minHeight: 9,
                    backgroundColor: Colors.white,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrototypeCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '个人资料',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  '这些信息会用于计算更贴近你的健康目标。',
                  style: TextStyle(color: mutedTextColor),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: '昵称',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '年龄'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '身高(cm)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '体重(kg)',
                    prefixIcon: Icon(Icons.monitor_weight_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('性别', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChipButton(
                      label: '男',
                      icon: Icons.male_rounded,
                      selected: _gender == 'male',
                      onTap: () => setState(() => _gender = 'male'),
                    ),
                    ChoiceChipButton(
                      label: '女',
                      icon: Icons.female_rounded,
                      selected: _gender == 'female',
                      onTap: () => setState(() => _gender = 'female'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('目标', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Column(
                  children: [
                    _GoalOptionCard(
                      title: '减脂',
                      subtitle: '控制热量，提升活动消耗',
                      icon: Icons.local_fire_department_rounded,
                      selected: _goal == 'lose_fat',
                      onTap: () => setState(() => _goal = 'lose_fat'),
                    ),
                    const SizedBox(height: 10),
                    _GoalOptionCard(
                      title: '增肌',
                      subtitle: '关注蛋白质和力量训练',
                      icon: Icons.fitness_center_rounded,
                      selected: _goal == 'gain_muscle',
                      onTap: () => setState(() => _goal = 'gain_muscle'),
                    ),
                    const SizedBox(height: 10),
                    _GoalOptionCard(
                      title: '保持健康',
                      subtitle: '平衡饮食、运动和睡眠节奏',
                      icon: Icons.favorite_rounded,
                      selected: _goal == 'maintain',
                      onTap: () => setState(() => _goal = 'maintain'),
                    ),
                  ],
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 14),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const PrototypeCard(
            color: mintColor,
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: primaryDarkColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '档案可随时修改，后续会补充慢性病史、用药和体检报告。',
                    style: TextStyle(color: textColor, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryActionButton(
            label: '保存并进入首页',
            onPressed: _submit,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }

  void _submit() {
    final nickname = _nicknameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final heightCm = double.tryParse(_heightController.text.trim());
    final weightKg = double.tryParse(_weightController.text.trim());

    if (nickname.isEmpty) {
      setState(() => _error = '请输入昵称');
      return;
    }
    if (age == null || age < 1 || age > 120) {
      setState(() => _error = '请输入 1-120 之间的年龄');
      return;
    }
    if (heightCm == null || heightCm < 100 || heightCm > 250) {
      setState(() => _error = '请输入 100-250cm 之间的身高');
      return;
    }
    if (weightKg == null || weightKg < 20 || weightKg > 300) {
      setState(() => _error = '请输入 20-300kg 之间的体重');
      return;
    }

    setState(() => _error = null);
    widget.onSubmit(OnboardingInput(
      nickname: nickname,
      age: age,
      gender: _gender,
      heightCm: heightCm,
      weightKg: weightKg,
      goal: _goal,
    ));
  }
}

/// 目标选项卡，配合 OnboardingView 中的性别选择。
class _GoalOptionCard extends StatelessWidget {
  const _GoalOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? mintColor : softMintColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? primaryColor : lineColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : primaryDarkColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: mutedTextColor,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? primaryDarkColor : lineColor,
            ),
          ],
        ),
      ),
    );
  }
}