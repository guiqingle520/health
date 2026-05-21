/// 从营养字典中读取数值，并兼容后端返回字符串数字的情况。
double nutritionNumber(Map<String, dynamic> nutrition, String key) {
  final value = nutrition[key];
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

/// 将餐次枚举转换成中文标签。
String mealTypeLabel(String mealType) {
  return switch (mealType) {
    'breakfast' => '早餐',
    'lunch' => '午餐',
    'dinner' => '晚餐',
    'snack' => '加餐',
    _ => '其他',
  };
}

/// 将运动类型转换成用户可读文案。
String exerciseTypeLabel(String exerciseType) {
  return switch (exerciseType) {
    'aerobic' => '有氧运动',
    'strength' => '力量训练',
    'flexibility' => '拉伸放松',
    _ => '运动记录',
  };
}
