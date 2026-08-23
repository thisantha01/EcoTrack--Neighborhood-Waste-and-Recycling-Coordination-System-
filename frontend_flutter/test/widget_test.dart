import 'package:flutter_test/flutter_test.dart';
import 'package:ecotrack/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WasteManagementApp());
    expect(find.byType(WasteManagementApp), findsOneWidget);
  });
}
