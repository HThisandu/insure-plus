import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/main.dart';

void main() {
  testWidgets('opens the dashboard and navigates between tabs', (tester) async {
    await tester.pumpWidget(const InsurePlusApp());
    await tester.pumpAndSettle();

    expect(find.text('Insure Plus'), findsOneWidget);
    expect(find.text('Customer dashboard'), findsOneWidget);

    await tester.tap(find.text('Policies'));
    await tester.pumpAndSettle();
    expect(find.text('Insurance policies'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Customer dashboard'), findsOneWidget);
  });

  testWidgets('opens motor and medical claims from the Claims tab', (
    tester,
  ) async {
    await tester.pumpWidget(const InsurePlusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Claims'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a claim type'), findsOneWidget);

    await tester.tap(find.text('Motor Claims'));
    await tester.pumpAndSettle();
    expect(find.text('Motor claim submission'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Choose a claim type'), findsOneWidget);

    await tester.tap(find.text('Medical Claims'));
    await tester.pumpAndSettle();
    expect(find.text('Medical claim submission'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Choose a claim type'), findsOneWidget);
  });
}
