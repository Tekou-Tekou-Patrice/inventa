import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/main.dart';

void main() {
  testWidgets('dashboard shortcut opens attendance', (tester) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));

    await tester.tap(find.text('Faire le pointage'));
    await tester.pumpAndSettle();

    expect(find.text('Présences'), findsWidgets);
    expect(find.text('Présents'), findsOneWidget);
  });
}
