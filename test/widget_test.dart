import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test - arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const AppMonitoreo());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
