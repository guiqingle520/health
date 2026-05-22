import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// 统一页面骨架，复用安全区、背景渐变和滚动边距。
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.child,
    this.scrollable = true,
    this.bottomPadding = 24,
  });

  final Widget child;
  final bool scrollable;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
        child: child,
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBF7), bgColor],
          ),
        ),
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }
}
