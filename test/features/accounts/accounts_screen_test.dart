import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/main.dart';
import 'package:inventa/src/features/accounts/accounts_screen.dart';
import 'package:inventa/src/models/plantation_models.dart';
import 'package:inventa/src/state/plantation_state.dart';

void main() {
  testWidgets('director creates and suspends a recruited field account', (
    tester,
  ) async {
    await tester.pumpWidget(const InventaApp(demoMode: true));
    await tester.tap(find.byTooltip('Changer de profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Directeur'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Toutes les rubriques'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comptes').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'nouveau.terrain');
    await tester.enterText(find.byType(TextFormField).at(1), '+2250102030405');
    await tester.tap(find.byType(DropdownButtonFormField<UserRole>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Responsable de terrain').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), 'abcd');
    expect(
      find.text(
        'Ce responsable verra uniquement les écrans et les données du champ sélectionné.',
      ),
      findsOneWidget,
    );
    final passwordInput = find.descendant(
      of: find.byType(TextFormField).at(2),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(passwordInput).obscureText, isTrue);
    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(passwordInput).obscureText, isFalse);
    await tester.tap(find.text('Créer le compte'));
    await tester.pumpAndSettle();
    expect(
      find.text('Le mot de passe doit contenir au moins 5 caractères'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(2), 'Terrain2026!');
    await tester.tap(find.text('Créer le compte'));
    await tester.pumpAndSettle();

    expect(find.text('nouveau.terrain'), findsOneWidget);
    expect(
      find.text(
        'Responsable de champ · +2250102030405 · Champ de Yaoundé · Accès actif',
      ),
      findsOneWidget,
    );
    expect(find.text('MotDePasseTerrain2026!'), findsNothing);

    await tester.tap(find.byTooltip('Suspendre nouveau.terrain'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suspendre').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Responsable de champ · +2250102030405 · Champ de Yaoundé · Accès suspendu',
      ),
      findsOneWidget,
    );
  });

  testWidgets('field manager account form scrolls above the phone keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final state = PlantationState()..setRole(UserRole.director);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: state,
            builder: (context, _) =>
                SingleChildScrollView(child: AccountsScreen(state: state)),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull, reason: 'accounts page');

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'account form opened');
    await tester.tap(find.byType(DropdownButtonFormField<UserRole>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Responsable de terrain').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'field manager selected');
    await tester.showKeyboard(find.byType(TextFormField).first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(find.text('Champ de rattachement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
