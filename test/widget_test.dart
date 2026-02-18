import 'package:flutter_test/flutter_test.dart';
import 'package:flow/main.dart';

void main() {
  testWidgets('App boot dan menampilkan halaman pemulihan',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AndrewApp());
    await tester.pumpAndSettle();

    expect(find.text('Youneka'), findsOneWidget);
    expect(find.text('Aplikasi berhasil dipulihkan.'), findsOneWidget);
  });
}
