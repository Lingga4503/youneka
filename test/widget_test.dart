import 'package:flutter_test/flutter_test.dart';
import 'package:flow/app/app.dart';

void main() {
  testWidgets('App boot menampilkan splash Youneka', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const YounekaApp());
    expect(find.text('Youneka'), findsOneWidget);
  });
}
