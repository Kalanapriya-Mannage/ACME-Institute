// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acme_institute/core/providers/auth_provider.dart';
import 'package:acme_institute/main.dart';

void main() {
  testWidgets('App starts and shows role selection', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authProvider: AuthProvider()));

    await tester.pumpAndSettle();

    expect(find.text('ACME Institute'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
