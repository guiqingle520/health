/// 用户提交饮食记录时的输入模型。
/// 这里固定补齐后端要求的 nutrition 字段，避免表单层重复拼装默认值。
class DietRecordInput {
  const DietRecordInput({
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.protein,
  });

  final String mealType;
  final String foodName;
  final double calories;
  final double protein;

  Map<String, dynamic> toJson() => {
        'mealType': mealType,
        'foodName': foodName,
        'nutrition': {
          'calories': calories,
          'carbs': 0,
          'protein': protein,
          'fat': 0,
          'fiber': 0,
          'sodiumMg': 0,
          'calciumMg': 0,
          'ironMg': 0,
          'vitaminAMcg': 0,
          'vitaminCMg': 0,
          'vitaminDIU': 0,
        },
      };
}

/// 用户提交运动记录时的输入模型。
class ExerciseRecordInput {
  const ExerciseRecordInput({
    required this.exerciseType,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  final String exerciseType;
  final int durationMinutes;
  final double caloriesBurned;

  Map<String, dynamic> toJson() => {
        'exerciseType': exerciseType,
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
      };
}

/// 首次建档表单的输入模型，对应 `/health/profiles/me`。
class OnboardingInput {
  const OnboardingInput({
    required this.nickname,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
  });

  final String nickname;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final String goal;

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'age': age,
        'gender': gender,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal,
      };
}
