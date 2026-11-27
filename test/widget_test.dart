import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/main.dart';

void main() {
  test('Insure Plus app can be created', () {
    const app = InsurePlusApp();

    expect(app, isA<InsurePlusApp>());
  });
}
