import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../components/app_screen.dart';
import '../components/info_chip.dart';
import '../components/primary_action_button.dart';
import '../components/prototype_card.dart';

/// 登录入口页，支持手机号和验证码登录。
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
  bool _agreedToTerms = false;
  String? _error;
  String? _codeMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: mintColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: primaryDarkColor,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'HealthGuard',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            '登录后查看今日健康状态与 AI 建议',
            textAlign: TextAlign.center,
            style: TextStyle(color: mutedTextColor, fontSize: 15),
          ),
          const SizedBox(height: 28),
          PrototypeCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '手机号登录',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '请输入手机号和验证码继续',
                  style: TextStyle(color: mutedTextColor),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    hintText: '请输入 11 位手机号',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          hintText: '123456',
                          prefixIcon: Icon(Icons.sms_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryDarkColor,
                          side: const BorderSide(color: lineColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _sendCode,
                        child: const Text('获取验证码'),
                      ),
                    ),
                  ],
                ),
                if (_codeMessage case final message?) ...[
                  const SizedBox(height: 10),
                  InfoChip(label: message, icon: Icons.check_circle_rounded),
                ],
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          activeColor: primaryColor,
                          onChanged: (value) =>
                              setState(() => _agreedToTerms = value ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            '我已阅读并同意用户协议和隐私政策',
                            style: TextStyle(color: mutedTextColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                PrimaryActionButton(
                  label: '登录并继续',
                  onPressed: _submit,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendCode() {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(phone)) {
      setState(() {
        _error = '请输入 11 位手机号';
        _codeMessage = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _codeMessage = '验证码已发送，请使用测试码 123456';
    });
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{11}$').hasMatch(phone)) {
      setState(() => _error = '请输入 11 位手机号');
      return;
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(code)) {
      setState(() => _error = '请输入 4-6 位数字验证码');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _error = '请先阅读并同意用户协议和隐私政策');
      return;
    }

    setState(() => _error = null);
    widget.onSubmit(phone, code);
  }
}