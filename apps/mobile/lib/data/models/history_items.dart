/// 历史饮食记录的展示模型。
class DietHistoryItem {
  const DietHistoryItem({
    required this.id,
    required this.mealType,
    required this.foodName,
    required this.nutrition,
    required this.recordedOn,
  });

  final String id;
  final String mealType;
  final String foodName;
  final Map<String, dynamic> nutrition;
  final String recordedOn;

  factory DietHistoryItem.fromJson(Map<String, dynamic> json) {
    return DietHistoryItem(
      id: json['id'] as String? ?? '',
      mealType: json['mealType'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      nutrition: (json['nutrition'] as Map?)?.cast<String, dynamic>() ?? const {},
      recordedOn: json['recordedOn'] as String? ?? '',
    );
  }
}

/// 历史运动记录的展示模型。
class ExerciseHistoryItem {
  const ExerciseHistoryItem({
    required this.id,
    required this.exerciseType,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.recordedOn,
  });

  final String id;
  final String exerciseType;
  final int durationMinutes;
  final num caloriesBurned;
  final String recordedOn;

  factory ExerciseHistoryItem.fromJson(Map<String, dynamic> json) {
    return ExerciseHistoryItem(
      id: json['id'] as String? ?? '',
      exerciseType: json['exerciseType'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num? ?? 0).toInt(),
      caloriesBurned: json['caloriesBurned'] as num? ?? 0,
      recordedOn: json['recordedOn'] as String? ?? '',
    );
  }
}
