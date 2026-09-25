import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/dashboard_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

void main() {
  testWidgets('工作台展示核心入口并可进入辨证', (tester) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
        home: DashboardScreen(onOpenSection: (value) => selected = value),
      ),
    );

    expect(find.text('临证工作台'), findsWidgets);
    expect(find.text('经方检索'), findsOneWidget);
    expect(find.text('本草查询'), findsOneWidget);
    expect(find.text('经络腧穴'), findsOneWidget);
    expect(find.text('经典原文'), findsOneWidget);

    await tester.tap(find.text('开始辨证'));
    expect(selected, 1);
  });
}
