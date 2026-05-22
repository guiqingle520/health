import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// 原型风格卡片容器，统一圆角、阴影和边框表现。
class PrototypeCard extends StatelessWidget {
  const PrototypeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = cardColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF143629).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
