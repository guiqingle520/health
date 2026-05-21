import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// 页面段落标题，统一眉标题、主标题和说明文案。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: primaryDarkColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: mutedTextColor, height: 1.4),
          ),
        ],
      ],
    );
  }
}
