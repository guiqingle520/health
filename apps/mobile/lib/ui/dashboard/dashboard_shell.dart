import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/history_items.dart';
import '../../data/models/inputs.dart';
import '../../data/models/views.dart';
import 'ai_advice_tab.dart';
import 'data_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

/// 仪表盘容器，负责底部导航与四个主标签页切换。
class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.data,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.weightTrend,
    required this.heartRateTrend,
    required this.recommendations,
    required this.profileCenter,
    required this.dietHistory,
    required this.exerciseHistory,
    required this.historyLoading,
    required this.historyError,
    required this.onRefreshHistory,
    required this.onDeleteDietRecord,
    required this.onDeleteExerciseRecord,
    required this.onRefresh,
    required this.onSubmitDietRecord,
    required this.onSubmitExerciseRecord,
    required this.submittingDietRecord,
    required this.submittingExerciseRecord,
    required this.message,
    required this.onLogout,
  });

  final DashboardView data;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;
  final HealthTrendView? weightTrend;
  final HealthTrendView? heartRateTrend;
  final AiRecommendationsTodayView? recommendations;
  final ProfileCenterView? profileCenter;
  final List<DietHistoryItem> dietHistory;
  final List<ExerciseHistoryItem> exerciseHistory;
  final bool historyLoading;
  final String? historyError;
  final Future<void> Function({String? mealType, String? exerciseType})
      onRefreshHistory;
  final Future<void> Function(String id, {String? mealType, String? exerciseType})
      onDeleteDietRecord;
  final Future<void> Function(String id, {String? mealType, String? exerciseType})
      onDeleteExerciseRecord;
  final Future<void> Function() onRefresh;
  final Future<void> Function(DietRecordInput input) onSubmitDietRecord;
  final Future<void> Function(ExerciseRecordInput input) onSubmitExerciseRecord;
  final bool submittingDietRecord;
  final bool submittingExerciseRecord;
  final String? message;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(child: _buildTab()),
          Positioned(
            left: 18,
            right: 18,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: PillBottomNav(
                selectedTabIndex: selectedTabIndex,
                onChanged: onTabChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab() {
    switch (selectedTabIndex) {
      case 0:
        return HomeTab(
          data: data,
          onRefresh: onRefresh,
          onGoAi: () => onTabChanged(2),
          message: message,
        );
      case 1:
        return DataTab(
          data: data,
          weightTrend: weightTrend,
          heartRateTrend: heartRateTrend,
          dietHistory: dietHistory,
          exerciseHistory: exerciseHistory,
          historyLoading: historyLoading,
          historyError: historyError,
          onRefreshHistory: onRefreshHistory,
          onDeleteDietRecord: onDeleteDietRecord,
          onDeleteExerciseRecord: onDeleteExerciseRecord,
        );
      case 2:
        return AiAdviceTab(
          data: data,
          recommendations: recommendations,
          onSubmitDietRecord: onSubmitDietRecord,
          onSubmitExerciseRecord: onSubmitExerciseRecord,
          submittingDietRecord: submittingDietRecord,
          submittingExerciseRecord: submittingExerciseRecord,
          message: message,
        );
      case 3:
      default:
        return ProfileTab(
          data: data,
          profileCenter: profileCenter,
          onLogout: onLogout,
        );
    }
  }
}

/// 底部胶囊导航，保持主流程入口的原型视觉和触达面积。
class PillBottomNav extends StatelessWidget {
  const PillBottomNav({
    super.key,
    required this.selectedTabIndex,
    required this.onChanged,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NavItem(
            tabIndex: 0,
            selectedTabIndex: selectedTabIndex,
            icon: Icons.home_rounded,
            label: '首页',
            onTap: onChanged,
          ),
          NavItem(
            tabIndex: 1,
            selectedTabIndex: selectedTabIndex,
            icon: Icons.show_chart_rounded,
            label: '数据',
            onTap: onChanged,
          ),
          NavItem(
            tabIndex: 2,
            selectedTabIndex: selectedTabIndex,
            icon: Icons.auto_awesome_rounded,
            label: 'AI 建议',
            onTap: onChanged,
          ),
          NavItem(
            tabIndex: 3,
            selectedTabIndex: selectedTabIndex,
            icon: Icons.person_rounded,
            label: '我的',
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 单个导航按钮，负责展示图标、标签和选中态。
class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.tabIndex,
    required this.selectedTabIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int tabIndex;
  final int selectedTabIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = tabIndex == selectedTabIndex;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onTap(tabIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? mintColor : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 21,
                  color: selected ? primaryDarkColor : mutedTextColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? primaryDarkColor : mutedTextColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
