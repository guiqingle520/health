import 'package:flutter/material.dart';

void main() {
  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const HealthHomePage(),
    );
  }
}

class HealthHomePage extends StatelessWidget {
  const HealthHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Dashboard')),
      body: const Center(
        child: Text('MVP: 日常饮食/运动记录与营养仪表盘'),
      ),
    );
  }
}
