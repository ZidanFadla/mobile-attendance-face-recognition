import 'package:flutter_test/flutter_test.dart';

import 'package:absensi_ob/main.dart';

void main() {
  testWidgets('Login page renders required controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });
}
