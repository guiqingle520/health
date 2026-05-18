import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const HealthApp());
}

enum AppStage { login, onboarding, dashboard }

class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  State<HealthApp> createState() => _HealthAppState();
}

class _HealthAppState extends State<HealthApp> {
  final ApiClient _apiClient = ApiClient();
  AppStage _stage = AppStage.login;
  String? _accessToken;
  DashboardView? _dashboard;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthGuard',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: Scaffold(
        appBar: AppBar(title: const Text('HealthGuard')),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return _ErrorView(message: error, onRetry: _retryCurrentStep);
    }

    switch (_stage) {
      case AppStage.login:
        return LoginView(onSubmit: _handleLogin);
      case AppStage.onboarding:
        return OnboardingView(onSubmit: _handleOnboardingSubmit);
      case AppStage.dashboard:
        final dashboard = _dashboard;
        if (dashboard == null) {
          return _ErrorView(
            message: '未获取到仪表盘数据',
            onRetry: _retryCurrentStep,
          );
        }
        return DashboardViewWidget(data: dashboard, onRefresh: _loadDashboard);
    }
  }

  Future<void> _handleLogin(String phone, String code) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loginResult = await _apiClient.login(phone: phone, code: code);
      _accessToken = loginResult.accessToken;
      final profile = await _apiClient.fetchMyProfile(loginResult.accessToken);

      if (!mounted) {
        return;
      }

      if (profile == null) {
        setState(() {
          _stage = AppStage.onboarding;
          _loading = false;
        });
        return;
      }

      await _loadDashboard();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '登录失败：$error';
      });
    }
  }

  Future<void> _handleOnboardingSubmit(OnboardingInput input) async {
    final token = _accessToken;
    if (token == null) {
      setState(() {
        _stage = AppStage.login;
        _error = '登录态已失效，请重新登录';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _apiClient.upsertMyProfile(token, input);
      if (!mounted) {
        return;
      }
      await _loadDashboard();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '档案提交失败：$error';
      });
    }
  }

  Future<void> _loadDashboard() async {
    final token = _accessToken;
    if (token == null) {
      setState(() {
        _stage = AppStage.login;
        _error = '登录态已失效，请重新登录';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dashboard = await _apiClient.fetchDashboard(token);
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _stage = AppStage.dashboard;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '加载仪表盘失败：$error';
      });
    }
  }

  void _retryCurrentStep() {
    switch (_stage) {
      case AppStage.login:
        setState(() => _error = null);
        return;
      case AppStage.onboarding:
        setState(() => _error = null);
        return;
      case AppStage.dashboard:
        _loadDashboard();
        return;
    }
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.onSubmit});

  final Future<void> Function(String phone, String code) onSubmit;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _phoneController =
      TextEditingController(text: '13800138000');
  final TextEditingController _codeController =
      TextEditingController(text: '123456');

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            '欢迎使用健康管家',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '手机号',
              hintText: '请输入 11 位手机号',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '验证码',
              hintText: '请输入 4-6 位验证码',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => widget.onSubmit(
              _phoneController.text.trim(),
              _codeController.text.trim(),
            ),
            child: const Text('登录并继续'),
          ),
        ],
      ),
    );
  }
}

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

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.onSubmit});

  final Future<void> Function(OnboardingInput input) onSubmit;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final TextEditingController _nicknameController =
      TextEditingController(text: '张先生');
  final TextEditingController _ageController = TextEditingController(text: '30');
  final TextEditingController _heightController =
      TextEditingController(text: '175');
  final TextEditingController _weightController =
      TextEditingController(text: '72');
  String _gender = 'male';
  String _goal = 'maintain';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('完善档案', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(labelText: '昵称'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '年龄'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            items: const [
              DropdownMenuItem(value: 'male', child: Text('男')),
              DropdownMenuItem(value: 'female', child: Text('女')),
            ],
            onChanged: (value) => setState(() => _gender = value ?? 'male'),
            decoration: const InputDecoration(labelText: '性别'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '身高(cm)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '体重(kg)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _goal,
            items: const [
              DropdownMenuItem(value: 'lose_fat', child: Text('减脂')),
              DropdownMenuItem(value: 'gain_muscle', child: Text('增肌')),
              DropdownMenuItem(value: 'maintain', child: Text('保持健康')),
            ],
            onChanged: (value) => setState(() => _goal = value ?? 'maintain'),
            decoration: const InputDecoration(labelText: '目标'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final input = OnboardingInput(
                nickname: _nicknameController.text.trim(),
                age: int.tryParse(_ageController.text.trim()) ?? 0,
                gender: _gender,
                heightCm: double.tryParse(_heightController.text.trim()) ?? 0,
                weightKg: double.tryParse(_weightController.text.trim()) ?? 0,
                goal: _goal,
              );
              widget.onSubmit(input);
            },
            child: const Text('保存并进入仪表盘'),
          ),
        ],
      ),
    );
  }
}

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

class DashboardViewWidget extends StatelessWidget {
  const DashboardViewWidget({
    super.key,
    required this.data,
    required this.onRefresh,
  });

  final DashboardView data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text('早安，${data.nickname}'),
              subtitle: Text('健康总分 ${data.healthScore} • ${data.date}'),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: [
              _MetricCard(
                title: '步数',
                value: '${data.steps}/${data.stepTarget}',
              ),
              _MetricCard(
                title: '睡眠',
                value: '${data.sleepHours.toStringAsFixed(1)}h (${data.sleepScore}分)',
              ),
              _MetricCard(
                title: '喝水',
                value: '${data.waterMl}/${data.waterTargetMl}ml',
              ),
              _MetricCard(
                title: '热量',
                value: '${data.calories}/${data.calorieTarget}kcal',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('AI 今日洞察', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...data.aiInsights.map(
            (insight) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(insight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }
}

class DietHistoryItem {
  const DietHistoryItem({
    required this.mealType,
    required this.foodName,
    required this.nutrition,
    required this.recordedOn,
  });

  final String mealType;
  final String foodName;
  final Map<String, dynamic> nutrition;
  final String recordedOn;

  factory DietHistoryItem.fromJson(Map<String, dynamic> json) {
    return DietHistoryItem(
      mealType: json['mealType'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      nutrition: (json['nutrition'] as Map?)?.cast<String, dynamic>() ?? const {},
      recordedOn: json['recordedOn'] as String? ?? '',
    );
  }
}

class ExerciseHistoryItem {
  const ExerciseHistoryItem({
    required this.exerciseType,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.recordedOn,
  });

  final String exerciseType;
  final int durationMinutes;
  final num caloriesBurned;
  final String recordedOn;

  factory ExerciseHistoryItem.fromJson(Map<String, dynamic> json) {
    return ExerciseHistoryItem(
      exerciseType: json['exerciseType'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      caloriesBurned: json['caloriesBurned'] as num? ?? 0,
      recordedOn: json['recordedOn'] as String? ?? '',
    );
  }
}

class ApiClient {
  ApiClient({
    String? baseUrl,
  }) : _baseUrl = baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:3000',
        );

  final String _baseUrl;

  Future<LoginResult> login({
    required String phone,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return LoginResult.fromJson(_decodeObject(response.body));
  }

  Future<Map<String, dynamic>?> fetchMyProfile(String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/profiles/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 404 || response.body.trim() == 'null') {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return _decodeObject(response.body);
  }

  Future<void> upsertMyProfile(String accessToken, OnboardingInput input) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/health/profiles/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<DashboardView> fetchDashboard(String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/dashboard/today'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return DashboardView.fromJson(_decodeObject(response.body));
  }

  Future<List<DietHistoryItem>> fetchDietHistory(
    String accessToken, {
    String? from,
    String? to,
    int? limit,
  }) async {
    final response = await http.get(
      _buildUri(
        '/health/diet-records',
        from: from,
        to: to,
        limit: limit,
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return _decodeList(response.body)
        .map((item) => DietHistoryItem.fromJson(item))
        .toList();
  }

  Future<List<ExerciseHistoryItem>> fetchExerciseHistory(
    String accessToken, {
    String? from,
    String? to,
    int? limit,
  }) async {
    final response = await http.get(
      _buildUri(
        '/health/exercise-records',
        from: from,
        to: to,
        limit: limit,
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return _decodeList(response.body)
        .map((item) => ExerciseHistoryItem.fromJson(item))
        .toList();
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('response is not a JSON object');
    }
    return decoded;
  }

  List<Map<String, dynamic>> _decodeList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const FormatException('response is not a JSON array');
    }

    return decoded.map((item) {
      if (item is! Map) {
        throw const FormatException('response item is not a JSON object');
      }
      return item.cast<String, dynamic>();
    }).toList();
  }

  Uri _buildUri(
    String path, {
    String? from,
    String? to,
    int? limit,
  }) {
    final queryParameters = <String, String>{};
    if (from != null) {
      queryParameters['from'] = from;
    }
    if (to != null) {
      queryParameters['to'] = to;
    }
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }

    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters.isEmpty ? null : queryParameters);
  }
}
