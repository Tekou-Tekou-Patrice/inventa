import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/src/features/auth/director_registration_screen.dart';

void main() {
  testWidgets('submits validated first-director registration details', (
    tester,
  ) async {
    String? submittedUsername;
    String? submittedPassword;
    String? submittedPhoneNumber;
    await tester.pumpWidget(
      MaterialApp(
        home: DirectorRegistrationScreen(
          onBack: () {},
          onRegister:
              ({
                required username,
                required password,
                required phoneNumber,
              }) async {
                submittedUsername = username;
                submittedPassword = password;
                submittedPhoneNumber = phoneNumber;
              },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'patron');
    await tester.enterText(find.byType(TextFormField).at(1), '+2250700000000');
    await tester.enterText(find.byType(TextFormField).at(2), '1234');
    await tester.enterText(find.byType(TextFormField).at(3), '1234');
    final submit = find.text('Créer le compte directeur');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('5 caractères minimum'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), '1234567890123');
    await tester.enterText(find.byType(TextFormField).at(3), '1234567890123');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('12 caractères maximum'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'Directeur42!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Directeur42!');
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submittedUsername, 'patron');
    expect(submittedPassword, 'Directeur42!');
    expect(submittedPhoneNumber, '+2250700000000');
  });
}
