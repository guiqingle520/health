import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/views.dart';
import '../components/app_screen.dart';
import '../components/prototype_card.dart';
import '../components/section_header.dart';

/// 个人中心页，展示档案摘要、功能入口和退出登录操作。
class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.data,
    required this.profileCenter,
    required this.onLogout,
  });

  final DashboardView data;
  final ProfileCenterView? profileCenter;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final center = profileCenter ?? ProfileCenterView.fallback(data);
    return AppScreen(
      bottomPadding: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            eyebrow: '个人中心',
            title: '我的',
            subtitle: '管理健康档案、设备和数据偏好。',
          ),
          const SizedBox(height: 16),
          PrototypeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(color: mintColor, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.person_rounded, color: primaryDarkColor, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(center.nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(
                            '目标：${center.goalLabel} · 已坚持 ${center.streakDays} 天',
                            style: const TextStyle(color: mutedTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _ProfileStat(value: '${center.healthScore}', label: '健康分')),
                    Expanded(child: _ProfileStat(value: '${center.streakDays}', label: '坚持天')),
                    Expanded(child: _ProfileStat(value: '${center.reportCount}', label: '报告')),
                    Expanded(child: _ProfileStat(value: '${center.connectedDevices}', label: '设备')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProCard(center: center),
          const SizedBox(height: 14),
          _ProfileMenuGroup(
            items: center.sections
                .map(
                  (section) => _ProfileMenuItem(
                    profileSectionIcon(section.id),
                    section.title,
                    section.subtitle,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryDarkColor,
              side: const BorderSide(color: lineColor),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: mutedTextColor, fontSize: 12)),
      ],
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.center});

  final ProfileCenterView center;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102B24), Color(0xFF0D4E45)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D4E45).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD28A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  center.proTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  center.proSubtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 将个人中心 section id 映射为对应图标，保持菜单语义稳定。
IconData profileSectionIcon(String id) {
  return switch (id) {
    'profile' => Icons.badge_rounded,
    'reports' => Icons.description_rounded,
    'devices' => Icons.watch_rounded,
    'family' => Icons.family_restroom_rounded,
    'preferences' => Icons.settings_rounded,
    _ => Icons.help_rounded,
  };
}

class _ProfileMenuItem {
  const _ProfileMenuItem(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

class _ProfileMenuGroup extends StatelessWidget {
  const _ProfileMenuGroup({required this.items});

  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return PrototypeCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: mintColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(items[i].icon, color: primaryDarkColor, size: 21),
              ),
              title: Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(items[i].subtitle),
              trailing: const Icon(Icons.chevron_right_rounded, color: mutedTextColor),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 72, endIndent: 16, color: lineColor),
          ],
        ],
      ),
    );
  }
}
