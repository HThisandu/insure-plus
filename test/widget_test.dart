import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/main.dart';

void main() {
  testWidgets('InsureCare home uses the new insurance dashboard layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('InsureCare'), findsOneWidget);
    expect(find.text("You're in safe hands."), findsOneWidget);
    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('View Claims'), findsOneWidget);
    expect(find.text('Make a Claim'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
  });
}
