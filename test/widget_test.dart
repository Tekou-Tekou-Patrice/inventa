import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/main.dart';

void main() {
  testWidgets('opens the French Inventa overview', (tester) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));

    expect(find.text('inventa'), findsOneWidget);
    expect(find.text('Présents pointés'), findsOneWidget);
    expect(find.textContaining('Mode démonstration'), findsOneWidget);
  });
}
