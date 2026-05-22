import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'data/api_client.dart';
import 'data/models/history_items.dart';
import 'data/models/inputs.dart';
import 'data/models/views.dart';
import 'ui/auth/login_view.dart';
import 'ui/auth/onboarding_view.dart';
import 'ui/components/loading_error_views.dart';
import 'ui/dashboard/dashboard_shell.dart';

void main() {
  runApp(const HealthApp());
}

enum AppStage { login, onboarding, dashboard }

enum DashboardTab { home, data, aiAdvice, profile }

class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  State<HealthApp> createState() => _HealthAppState();
}

class _HealthAppState extends State<HealthApp> {
  final ApiClient _apiClient = ApiClient();
  AppStage _stage = AppStage.login;
  DashboardTab _selectedTab = DashboardTab.home;
  String? _accessToken;
  DashboardView? _dashboard;
  HealthTrendView? _weightTrend;
  HealthTrendView? _heartRateTrend;
  AiRecommendationsTodayView? _recommendations;
  ProfileCenterView? _profileCenter;
  List<DietHistoryItem> _dietHistory = const [];
  List<ExerciseHistoryItem> _exerciseHistory = const [];
  bool _historyLoading = false;
  String? _historyError;
  bool _loading = false;
  bool _submittingDietRecord = false;
  bool _submittingExerciseRecord = false;
  String? _error;
  String? _dashboardMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthGuard',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView();
    }

    final error = _error;
    if (error != null) {
      return ErrorView(message: error, onRetry: _retryCurrentStep);
    }

    switch (_stage) {
      case AppStage.login:
        return LoginView(onSubmit: _handleLogin);
      case AppStage.onboarding:
        return OnboardingView(onSubmit: _handleOnboardingSubmit);
      case AppStage.dashboard:
        final dashboard = _dashboard;
        if (dashboard == null) {
          return ErrorView(
            message: '未获取到仪表盘数据',
            onRetry: _retryCurrentStep,
          );
        }
        return DashboardShell(
          data: dashboard,
          selectedTabIndex: _selectedTab.index,
          onTabChanged: (index) => setState(() {
            _selectedTab = DashboardTab.values[index];
          }),
          weightTrend: _weightTrend,
          heartRateTrend: _heartRateTrend,
          recommendations: _recommendations,
          profileCenter: _profileCenter,
          dietHistory: _dietHistory,
          exerciseHistory: _exerciseHistory,
          historyLoading: _historyLoading,
          historyError: _historyError,
          onRefreshHistory: _refreshHistory,
          onDeleteDietRecord: _handleDeleteDietRecord,
          onDeleteExerciseRecord: _handleDeleteExerciseRecord,
          onRefresh: _loadDashboard,
          onSubmitDietRecord: _handleDietRecordSubmit,
          onSubmitExerciseRecord: _handleExerciseRecordSubmit,
          submittingDietRecord: _submittingDietRecord,
          submittingExerciseRecord: _submittingExerciseRecord,
          message: _dashboardMessage,
          onLogout: _logout,
        );
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
      final supplemental = await _loadSupplementalDashboardData(token);
      await _loadHistory(token);
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _weightTrend = supplemental.weightTrend;
        _heartRateTrend = supplemental.heartRateTrend;
        _recommendations = supplemental.recommendations;
        _profileCenter = supplemental.profileCenter;
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

  Future<_SupplementalDashboardData> _loadSupplementalDashboardData(
    String token,
  ) async {
    try {
      final results = await Future.wait<dynamic>([
        _apiClient.fetchTrend(token, metric: 'weight', period: 'week'),
        _apiClient.fetchTrend(token, metric: 'heartRate', period: 'week'),
        _apiClient.fetchTodayRecommendations(token),
        _apiClient.fetchProfileCenter(token),
      ]);
      return _SupplementalDashboardData(
        weightTrend: results[0] as HealthTrendView,
        heartRateTrend: results[1] as HealthTrendView,
        recommendations: results[2] as AiRecommendationsTodayView,
        profileCenter: results[3] as ProfileCenterView,
      );
    } catch (_) {
      return const _SupplementalDashboardData();
    }
  }

  Future<void> _loadHistory(
    String token, {
    String? mealType,
    String? exerciseType,
  }) async {
    if (mounted) {
      setState(() {
        _historyLoading = true;
        _historyError = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _apiClient.fetchDietHistory(token, limit: 50, mealType: mealType),
        _apiClient.fetchExerciseHistory(
          token,
          limit: 50,
          exerciseType: exerciseType,
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _dietHistory = results[0] as List<DietHistoryItem>;
        _exerciseHistory = results[1] as List<ExerciseHistoryItem>;
        _historyLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _historyLoading = false;
        _historyError = '记录历史加载失败：$error';
      });
    }
  }

  Future<void> _refreshHistory({String? mealType, String? exerciseType}) async {
    final token = _accessToken;
    if (token == null) {
      return;
    }
    await _loadHistory(token, mealType: mealType, exerciseType: exerciseType);
  }

  Future<void> _handleDeleteDietRecord(
    String id, {
    String? mealType,
    String? exerciseType,
  }) async {
    final token = _accessToken;
    if (token == null) {
      setState(() {
        _stage = AppStage.login;
        _error = '登录态已失效，请重新登录';
      });
      return;
    }

    await _apiClient.deleteDietRecord(token, id);
    await _loadDashboard();
    await _refreshHistory(mealType: mealType, exerciseType: exerciseType);
  }

  Future<void> _handleDeleteExerciseRecord(
    String id, {
    String? mealType,
    String? exerciseType,
  }) async {
    final token = _accessToken;
    if (token == null) {
      setState(() {
        _stage = AppStage.login;
        _error = '登录态已失效，请重新登录';
      });
      return;
    }

    await _apiClient.deleteExerciseRecord(token, id);
    await _loadDashboard();
    await _refreshHistory(mealType: mealType, exerciseType: exerciseType);
  }

  Future<void> _handleDietRecordSubmit(DietRecordInput input) async {
    final token = _accessToken;
    if (token == null) {
      setState(() {
        _stage = AppStage.login;
        _error = '登录态已失效，请重新登录';
      });
      return;
    }

    setState(() {
      _submittingDietRecord = true;
      _dashboardMessage = null;
    });

    try {
      await _apiClient.createMyDietRecord(token, input);
      await _loadDashboard();
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingDietRecord = false;
        _dashboardMessage = '饮食记录已保存，仪表盘已刷新';
        _selectedTab = DashboardTab.home;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingDietRecord = false;
        _dashboardMessage = '饮食记录提交失败：$error';
      });
    }
  }

  Future<void> _handleExerciseRecordSubmit(ExerciseRecordInput input) async {
    final token = _accessToken;
    if (token == null) {
      setState(() {
        _stage = AppStage.login;
        _error = '登录态已失效，请重新登录';
      });
      return;
    }

    setState(() {
      _submittingExerciseRecord = true;
      _dashboardMessage = null;
    });

    try {
      await _apiClient.createMyExerciseRecord(token, input);
      await _loadDashboard();
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingExerciseRecord = false;
        _dashboardMessage = '运动记录已保存，仪表盘已刷新';
        _selectedTab = DashboardTab.home;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submittingExerciseRecord = false;
        _dashboardMessage = '运动记录提交失败：$error';
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

  void _logout() {
    setState(() {
      _stage = AppStage.login;
      _selectedTab = DashboardTab.home;
      _accessToken = null;
      _dashboard = null;
      _weightTrend = null;
      _heartRateTrend = null;
      _recommendations = null;
      _profileCenter = null;
      _dietHistory = const [];
      _exerciseHistory = const [];
      _historyLoading = false;
      _historyError = null;
      _error = null;
      _dashboardMessage = null;
    });
  }
}

class _SupplementalDashboardData {
  const _SupplementalDashboardData({
    this.weightTrend,
    this.heartRateTrend,
    this.recommendations,
    this.profileCenter,
  });

  final HealthTrendView? weightTrend;
  final HealthTrendView? heartRateTrend;
  final AiRecommendationsTodayView? recommendations;
  final ProfileCenterView? profileCenter;
}
