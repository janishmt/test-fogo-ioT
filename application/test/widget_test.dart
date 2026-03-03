import 'package:flutter_test/flutter_test.dart';
import 'package:fogo/main.dart';

void main() {
  testWidgets('App démarre sans crash', (WidgetTester tester) async {
    await tester.pumpWidget(const FogoApp());
    expect(find.text('Fogo — IoT Monitor'), findsOneWidget);
  });
}
