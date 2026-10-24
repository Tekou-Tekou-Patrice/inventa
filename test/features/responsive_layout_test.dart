import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/main.dart';

void main() {
  testWidgets('primary sections render on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const InventaApp(demoMode: true));
    expect(tester.takeException(), isNull);

    for (final section in [
      'Présences',
      'Ouvriers',
      'Tâches',
      'Stocks & achats',
      'Dépenses',
      'Vue d’ensemble',
    ]) {
      await tester.tap(find.byTooltip('Toutes les rubriques'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(section).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: section);
    }
  });

  testWidgets('director app bar fits on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.byTooltip('Changer de profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Directeur').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Choisir un champ'), findsOneWidget);
  });
}
