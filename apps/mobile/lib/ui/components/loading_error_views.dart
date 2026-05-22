import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'app_screen.dart';
import 'primary_action_button.dart';
import 'prototype_card.dart';

/// 全局加载页，避免主流程在数据请求期间闪烁空白页面。
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      scrollable: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primaryColor),
            SizedBox(height: 16),
            Text('正在加载健康数据...', style: TextStyle(color: mutedTextColor)),
          ],
        ),
      ),
    );
  }
}

/// 全局错误页，统一承接关键流程的重试入口。
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      scrollable: false,
      child: Center(
        child: PrototypeCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: warningColor, size: 42),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, height: 1.4),
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(label: '重试', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
