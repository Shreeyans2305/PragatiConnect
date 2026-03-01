import 'package:flutter_test/flutter_test.dart';
import 'package:pragati_connect/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const PragatiConnectApp());
    expect(find.text('Pragati'), findsOneWidget);
  });
}
