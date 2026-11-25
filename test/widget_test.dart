import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/features/authentication/screens/login_screen.dart';

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
}
