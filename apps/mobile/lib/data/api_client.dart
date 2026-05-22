import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/history_items.dart';
import 'models/inputs.dart';
import 'models/views.dart';

/// 后端 HTTP 客户端，集中维护 HealthGuard 移动端当前使用的 API 契约。
class ApiClient {
  ApiClient({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:3000',
            );

  final String _baseUrl;

  /// 获取指定指标的趋势数据。
  Future<HealthTrendView> fetchTrend(String accessToken,
      {required String metric, required String period}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/trends?metric=$metric&period=$period'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return HealthTrendView.fromJson(_decodeObject(response.body));
  }

  /// 获取今天的 AI 推荐。
  Future<AiRecommendationsTodayView> fetchTodayRecommendations(
      String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/ai/recommendations/today'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return AiRecommendationsTodayView.fromJson(_decodeObject(response.body));
  }

  /// 获取个人中心聚合数据。
  Future<ProfileCenterView> fetchProfileCenter(String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/profile-center/me'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return ProfileCenterView.fromJson(_decodeObject(response.body));
  }

  /// 使用手机号和验证码登录。
  Future<LoginResult> login({required String phone, required String code}) async {
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

  /// 获取当前用户档案；404/null 表示需要进入首次建档流程。
  Future<Map<String, dynamic>?> fetchMyProfile(String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/profiles/me'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode == 404 || response.body.trim() == 'null') {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return _decodeObject(response.body);
  }

  /// 创建或更新当前用户健康档案。
  Future<void> upsertMyProfile(String accessToken, OnboardingInput input) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/health/profiles/me'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// 获取今日首页仪表盘数据。
  Future<DashboardView> fetchDashboard(String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/dashboard/today'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return DashboardView.fromJson(_decodeObject(response.body));
  }

  /// 创建当前用户的饮食记录。
  Future<void> createMyDietRecord(
      String accessToken, DietRecordInput input) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/health/diet-records/me'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// 创建当前用户的运动记录。
  Future<void> createMyExerciseRecord(
      String accessToken, ExerciseRecordInput input) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/health/exercise-records/me'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(input.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// 查询当前用户的饮食历史，可按日期范围、数量和餐次过滤。
  Future<List<DietHistoryItem>> fetchDietHistory(String accessToken,
      {String? from, String? to, int? limit, String? mealType}) async {
    final response = await http.get(
      _buildUri('/health/diet-records',
          from: from, to: to, limit: limit, mealType: mealType),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return _decodeList(response.body)
        .map((item) => DietHistoryItem.fromJson(item))
        .toList();
  }

  /// 查询当前用户的运动历史，可按日期范围、数量和运动类型过滤。
  Future<List<ExerciseHistoryItem>> fetchExerciseHistory(String accessToken,
      {String? from, String? to, int? limit, String? exerciseType}) async {
    final response = await http.get(
      _buildUri('/health/exercise-records',
          from: from, to: to, limit: limit, exerciseType: exerciseType),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return _decodeList(response.body)
        .map((item) => ExerciseHistoryItem.fromJson(item))
        .toList();
  }

  /// 获取单条饮食记录详情。
  Future<DietHistoryItem> fetchDietRecordDetail(
      String accessToken, String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/diet-records/$id'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return DietHistoryItem.fromJson(_decodeObject(response.body));
  }

  /// 获取单条运动记录详情。
  Future<ExerciseHistoryItem> fetchExerciseRecordDetail(
      String accessToken, String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/health/exercise-records/$id'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    return ExerciseHistoryItem.fromJson(_decodeObject(response.body));
  }

  /// 删除当前用户的一条饮食记录。
  Future<void> deleteDietRecord(String accessToken, String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/health/diet-records/$id'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// 删除当前用户的一条运动记录。
  Future<void> deleteExerciseRecord(String accessToken, String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/health/exercise-records/$id'),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Map<String, String> _authHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

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
    String? mealType,
    String? exerciseType,
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
    if (mealType != null) {
      queryParameters['mealType'] = mealType;
    }
    if (exerciseType != null) {
      queryParameters['exerciseType'] = exerciseType;
    }

    return Uri.parse('$_baseUrl$path').replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters);
  }
}
