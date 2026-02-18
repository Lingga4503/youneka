import 'package:flutter_test/flutter_test.dart';
import 'package:flow/app/app.dart';

void main() {
  testWidgets('App boot dan menampilkan halaman pemulihan',
      (WidgetTester tester) async {
    await tester.pumpWidget(const YounekaApp());
    await tester.pumpAndSettle();

    expect(find.text('Youneka'), findsOneWidget);
    expect(find.text('Aplikasi berhasil dipulihkan.'), findsOneWidget);
  });
}
