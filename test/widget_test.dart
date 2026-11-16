import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Smart Rosary launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartRosaryApp());

    expect(find.text('Hello, Little Prayer Star!'), findsOneWidget);
  });
}