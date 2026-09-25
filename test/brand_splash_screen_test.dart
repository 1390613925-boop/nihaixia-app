import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/brand_splash_screen.dart';

void main() {
  testWidgets('shows exact brand copy and tap skips the introduction', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BrandSplashScreen(child: Scaffold(body: Text('HOME_READY'))),
      ),
    );

    expect(find.text('覓源方'), findsOneWidget);
    expect(find.text('循经典之源，索辨证之方'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('覓源方'), findsNothing);
    expect(find.text('HOME_READY'), findsOneWidget);
  });

  testWidgets('automatically fades after about three seconds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BrandSplashScreen(child: Scaffold(body: Text('HOME_READY'))),
      ),
    );

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('覓源方'), findsNothing);
    expect(find.text('HOME_READY'), findsOneWidget);
  });
}
