<<<<<<< HEAD
import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/main.dart';

void main() {
  test('Insure Plus app can be created', () {
    const app = InsurePlusApp();

    expect(app, isA<InsurePlusApp>());
=======
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/features/authentication/screens/login_screen.dart';
import 'package:insure_plus/main.dart';

void main() {
  testWidgets(
    'Login and password reset validate the form before using Firebase',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final reset = find.text('Forgot password?');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pump();
      expect(find.text('Enter your email address'), findsOneWidget);

      final password = tester.state<FormFieldState<String>>(
        find.byType(TextFormField).last,
      );
      expect(password.hasError, isFalse);

      final login = find.text('Log in');
      await tester.ensureVisible(login);
      await tester.tap(login);
      await tester.pump();
      expect(password.errorText, 'Enter your password');
    },
  );

  testWidgets('Insure Plus home displays the Motor Claims dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MyHomePage(title: 'Insure Plus')),
    );
    await tester.pump();

    expect(find.text('Insure Plus'), findsOneWidget);
    expect(find.text("You're in safe hands."), findsOneWidget);
    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('View Claims'), findsOneWidget);
    expect(find.text('Make a Claim'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
>>>>>>> origin/develop
  });
}
