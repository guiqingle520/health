import 'package:flutter_test/flutter_test.dart';

import 'package:health_mobile/main.dart';

void main() {
  testWidgets('Health app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthApp());

    expect(find.text('HealthGuard'), findsOneWidget);
    expect(find.text('欢迎使用健康管家'), findsOneWidget);
    expect(find.text('登录并继续'), findsOneWidget);
  });
}
