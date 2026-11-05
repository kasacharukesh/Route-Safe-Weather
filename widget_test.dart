import 'package:flutter_test/flutter_test.dart';
import 'package:routesafe/main.dart';

void main() {
  testWidgets('RouteSafe app renders dashboard', (tester) async {
    await tester.pumpWidget(const RouteSafeApp());
    expect(find.text('RouteSafe'), findsOneWidget);
  });
}
