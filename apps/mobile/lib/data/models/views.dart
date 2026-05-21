/// 仪表盘首页需要的聚合视图模型。
class DashboardView {
  const DashboardView({
    required this.date,
    required this.healthScore,
    required this.nickname,
    required this.steps,
    required this.stepTarget,
    required this.sleepHours,
    required this.sleepScore,
    required this.waterMl,
    required this.waterTargetMl,
    required this.calories,
    required this.calorieTarget,
    required this.aiInsights,
  });

  final String date;
  final int healthScore;
  final String nickname;
  final int steps;
  final int stepTarget;
  final double sleepHours;
  final int sleepScore;
  final int waterMl;
  final int waterTargetMl;
  final int calories;
  final int calorieTarget;
  final List<String> aiInsights;

  factory DashboardView.fromJson(Map<String, dynamic> json) {
    final cards = json['cards'] as Map<String, dynamic>? ?? {};
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    return DashboardView(
      date: json['date'] as String? ?? '',
      healthScore: (json['healthScore'] as num? ?? 0).toInt(),
      nickname: profile['nickname'] as String? ?? '用户',
      steps: (cards['steps'] as num? ?? 0).toInt(),
      stepTarget: (cards['stepTarget'] as num? ?? 10000).toInt(),
      sleepHours: (cards['sleepHours'] as num? ?? 0).toDouble(),
      sleepScore: (cards['sleepScore'] as num? ?? 0).toInt(),
      waterMl: (cards['waterMl'] as num? ?? 0).toInt(),
      waterTargetMl: (cards['waterTargetMl'] as num? ?? 2000).toInt(),
      calories: (cards['calories'] as num? ?? 0).toInt(),
      calorieTarget: (cards['calorieTarget'] as num? ?? 2200).toInt(),
      aiInsights: (json['aiInsights'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// 趋势图上的单个时间点。
class HealthTrendPoint {
  const HealthTrendPoint({required this.date, required this.value});

  final String date;
  final double value;

  factory HealthTrendPoint.fromJson(Map<String, dynamic> json) {
    return HealthTrendPoint(
      date: json['date'] as String? ?? '',
      value: (json['value'] as num? ?? 0).toDouble(),
    );
  }
}

/// 趋势接口返回的信号提示。
class HealthTrendSignal {
  const HealthTrendSignal({required this.level, required this.message});

  final String level;
  final String message;

  factory HealthTrendSignal.fromJson(Map<String, dynamic> json) {
    return HealthTrendSignal(
      level: json['level'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
    );
  }
}

/// 数据页趋势卡片使用的完整视图模型。
class HealthTrendView {
  const HealthTrendView({
    required this.metric,
    required this.period,
    required this.currentValue,
    required this.delta,
    required this.unit,
    required this.points,
    required this.signals,
  });

  final String metric;
  final String period;
  final double currentValue;
  final double delta;
  final String unit;
  final List<HealthTrendPoint> points;
  final List<HealthTrendSignal> signals;

  factory HealthTrendView.fromJson(Map<String, dynamic> json) {
    return HealthTrendView(
      metric: json['metric'] as String? ?? 'weight',
      period: json['period'] as String? ?? 'week',
      currentValue: (json['currentValue'] as num? ?? 0).toDouble(),
      delta: (json['delta'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? '',
      points: (json['points'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => HealthTrendPoint.fromJson(item.cast<String, dynamic>()))
          .toList(),
      signals: (json['signals'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => HealthTrendSignal.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }

  /// 当趋势接口暂时不可用时，使用本地兜底数据保证数据页结构仍可渲染。
  factory HealthTrendView.fallback({
    required String metric,
    required double currentValue,
    required double delta,
    required String unit,
    required List<double> values,
    required String message,
  }) {
    return HealthTrendView(
      metric: metric,
      period: 'week',
      currentValue: currentValue,
      delta: delta,
      unit: unit,
      points: [
        for (var i = 0; i < values.length; i++)
          HealthTrendPoint(date: 'D${i + 1}', value: values[i]),
      ],
      signals: [HealthTrendSignal(level: 'info', message: message)],
    );
  }
}

/// 单条 AI 推荐卡片模型。
class AiRecommendation {
  const AiRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.reason,
    required this.actionText,
    required this.status,
  });

  final String id;
  final String type;
  final String title;
  final String reason;
  final String actionText;
  final String status;

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'diet',
      title: json['title'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      actionText: json['actionText'] as String? ?? '查看',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// 今日 AI 建议页的聚合响应。
class AiRecommendationsTodayView {
  const AiRecommendationsTodayView({required this.date, required this.items});

  final String date;
  final List<AiRecommendation> items;

  factory AiRecommendationsTodayView.fromJson(Map<String, dynamic> json) {
    return AiRecommendationsTodayView(
      date: json['date'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AiRecommendation.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// 个人中心页面的聚合视图模型。
class ProfileCenterView {
  const ProfileCenterView({
    required this.nickname,
    required this.goalLabel,
    required this.healthScore,
    required this.streakDays,
    required this.reportCount,
    required this.connectedDevices,
    required this.proTitle,
    required this.proSubtitle,
    required this.sections,
  });

  final String nickname;
  final String goalLabel;
  final int healthScore;
  final int streakDays;
  final int reportCount;
  final int connectedDevices;
  final String proTitle;
  final String proSubtitle;
  final List<ProfileCenterSection> sections;

  factory ProfileCenterView.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final pro = json['pro'] as Map<String, dynamic>? ?? {};
    return ProfileCenterView(
      nickname: profile['nickname'] as String? ?? '用户',
      goalLabel: profile['goalLabel'] as String? ?? '保持健康',
      healthScore: (stats['healthScore'] as num? ?? 0).toInt(),
      streakDays: (stats['streakDays'] as num? ?? 0).toInt(),
      reportCount: (stats['reportCount'] as num? ?? 0).toInt(),
      connectedDevices: (stats['connectedDevices'] as num? ?? 0).toInt(),
      proTitle: pro['title'] as String? ?? 'HealthGuard Pro',
      proSubtitle: pro['subtitle'] as String? ?? '解锁深度报告、设备同步和家庭共享',
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ProfileCenterSection.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }

  /// 当个人中心接口未返回时，使用首页已有数据维持页面完整度。
  factory ProfileCenterView.fallback(DashboardView data) {
    return ProfileCenterView(
      nickname: data.nickname,
      goalLabel: '保持健康',
      healthScore: data.healthScore,
      streakDays: 7,
      reportCount: 2,
      connectedDevices: 0,
      proTitle: 'HealthGuard Pro',
      proSubtitle: '解锁深度报告、设备同步和家庭共享',
      sections: const [
        ProfileCenterSection(id: 'profile', title: '健康档案', subtitle: '基础资料、目标、风险标签'),
        ProfileCenterSection(id: 'reports', title: '数据与报告', subtitle: '周报、月报和导出能力'),
        ProfileCenterSection(id: 'devices', title: '设备与数据源', subtitle: 'Garmin 未连接 · 即将支持'),
        ProfileCenterSection(id: 'family', title: '家庭共享', subtitle: '家人授权与陪伴视角'),
        ProfileCenterSection(id: 'preferences', title: '隐私与提醒', subtitle: '提醒、隐私和单位设置'),
        ProfileCenterSection(id: 'support', title: '帮助与反馈', subtitle: '常见问题与反馈入口'),
      ],
    );
  }
}

/// 个人中心中的单个功能入口。
class ProfileCenterSection {
  const ProfileCenterSection({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;

  factory ProfileCenterSection.fromJson(Map<String, dynamic> json) {
    return ProfileCenterSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}

/// 登录接口返回的 token 结果。
class LoginResult {
  const LoginResult({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }
}
