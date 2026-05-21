/// 统一格式化数值，避免整数和小数在卡片里出现风格不一致的问题。
String formatNumber(num value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}

/// 将后端返回的 YYYY-MM-DD 压缩成卡片里更适合展示的 MM/DD。
String formatDateLabel(String recordedOn) {
  if (recordedOn.length >= 10) {
    return recordedOn.substring(5, 10).replaceFirst('-', '/');
  }
  return recordedOn;
}
