import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventa/src/features/auth/login_screen.dart';

void main() {
  testWidgets('collects credentials and calls the authentication action', (
    tester,
  ) async {
    String? submittedUsername;
    String? submittedPassword;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (username, password) async {
            submittedUsername = username;
            submittedPassword = password;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'assistant');
    await tester.enterText(find.byType(TextField).at(1), 'secret-password');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(submittedUsername, 'assistant');
    expect(submittedPassword, 'secret-password');
  });

  testWidgets('toggles password visibility from the eye button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onLogin: (_, _) async {})),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
    expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
  });

  testWidgets(
    'shows director signup only when first registration is available',
    (tester) async {
      var openedRegistration = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            onLogin: (_, _) async {},
            canRegisterDirector: () async => true,
            onOpenRegistration: () => openedRegistration = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inscrire le directeur'), findsOneWidget);
      await tester.tap(find.text('Inscrire le directeur'));
      expect(openedRegistration, isTrue);
    },
  );

  testWidgets('hides director signup when a director already exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (_, _) async {},
          canRegisterDirector: () async => false,
          onOpenRegistration: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inscrire le directeur'), findsNothing);
  });

  testWidgets('can retry director availability after a server error', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onLogin: (_, _) async {},
          canRegisterDirector: () async {
            attempts++;
            if (attempts == 1) {
              throw Exception('Serveur indisponible.');
            }
            return true;
          },
          onOpenRegistration: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inscrire le directeur'), findsNothing);
    expect(find.text('Réessayer la vérification'), findsOneWidget);

    await tester.tap(find.text('Réessayer la vérification'));
    await tester.pumpAndSettle();

    expect(find.text('Inscrire le directeur'), findsOneWidget);
    expect(attempts, 2);
  });
}
