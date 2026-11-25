import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui_example/auth_blocks_demo.dart';

import 'support/small_screen.dart';

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(buttonLabeled(label));
  await tester.tap(buttonLabeled(label));
  await tester.pumpAndSettle();
}

Future<void> openRegister(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Create account').first);
  await tester.tap(find.text('Create account').first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login validates locally, hides and reveals the password, keeps '
      'a host failure recoverable, then the host navigates home', (
    tester,
  ) async {
    await tester.pumpWidget(const AuthBlocksDemo(delay: Duration.zero));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tapButton(tester, 'Log in');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.text('Couldn’t log you in'), findsNothing);

    final password = find.byType(TextFormField).at(1);
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
      isFalse,
    );
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).at(1)).obscureText,
      isTrue,
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'mina@example.com',
    );
    await tester.enterText(password, 'notes123');
    await tapButton(tester, 'Log in');
    expect(find.text('Couldn’t log you in'), findsOneWidget);
    expect(find.textContaining('then try again'), findsOneWidget);

    await tapButton(tester, 'Log in');
    expect(find.text('Signed in'), findsOneWidget);
    expect(find.textContaining('not Annota’s production'), findsOneWidget);
  });

  testWidgets('login locks the form while the host authenticates and forgot '
      'password is a host recovery destination', (tester) async {
    await tester.pumpWidget(const AuthBlocksDemo(delay: Duration(seconds: 1)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'notes123');
    await tester.tap(buttonLabeled('Log in'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).at(0)).enabled,
      isFalse,
    );
    expect(enabled(tester, 'Log in'), isFalse);
    await tester.pumpAndSettle();

    await tapButton(tester, 'Forgot password?');
    expect(find.text('Reset password'), findsOneWidget);
    await tapButton(tester, 'Send reset message');
    expect(find.text('Reset message recorded'), findsOneWidget);
  });

  testWidgets('register locks the details form while the host creates the '
      'account', (tester) async {
    await tester.pumpWidget(
      const AuthBlocksDemo(
        initialScenario: AuthDemoScenario.registrationFailsOnce,
        delay: Duration(seconds: 1),
      ),
    );
    await tester.pumpAndSettle();
    await openRegister(tester);
    await tester.enterText(find.byType(TextFormField).at(1), 'notes123');
    await tester.tap(buttonLabeled('Create account'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).at(0)).enabled,
      isFalse,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).at(1)).enabled,
      isFalse,
    );
    expect(enabled(tester, 'Create account'), isFalse);

    await tester.pumpAndSettle();
    expect(find.text('Couldn’t create your account'), findsOneWidget);
  });

  testWidgets('register validates policy-helped input, keeps a host failure '
      'recoverable, and reaches the host destination', (tester) async {
    await tester.pumpWidget(
      const AuthBlocksDemo(
        initialScenario: AuthDemoScenario.registrationFailsOnce,
        delay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    await openRegister(tester);

    expect(
      find.text('Use at least 8 characters with a letter and a number.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tapButton(tester, 'Create account');
    expect(find.text('Use at least 8 characters.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'notes123');
    await tapButton(tester, 'Create account');
    expect(find.text('Couldn’t create your account'), findsOneWidget);
    await tapButton(tester, 'Create account');
    expect(find.text('Signed in'), findsOneWidget);
  });

  testWidgets('register policy is host navigation and required verification '
      'rejects a wrong code before accepting the fixture code', (tester) async {
    await tester.pumpWidget(
      const AuthBlocksDemo(
        initialScenario: AuthDemoScenario.verificationRequired,
        delay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    await openRegister(tester);

    await tester.ensureVisible(find.text('Read terms and privacy policy'));
    await tester.tap(find.text('Read terms and privacy policy'));
    await tester.pumpAndSettle();
    expect(find.text('Terms and privacy'), findsOneWidget);
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'notes123');
    await tapButton(tester, 'Create account');
    expect(find.text('Verify your email'), findsOneWidget);

    await tapButton(tester, 'Verify email');
    expect(find.text('Enter the 6-digit code.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '000000');
    await tapButton(tester, 'Verify email');
    expect(find.text('Couldn’t verify your email'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '248913');
    await tapButton(tester, 'Verify email');
    expect(find.text('Signed in'), findsOneWidget);
  });

  testWidgets('320dp at 200% text in dark mode keeps login actions reachable '
      'without overflow', (tester) async {
    useSmallScreenLargeText(tester);
    await tester.pumpWidget(
      const AuthBlocksDemo(initialDark: true, delay: Duration.zero),
    );
    await tester.pumpAndSettle();
    expect(buttonLabeled('Log in').hitTestable(), findsOneWidget);
    expect(buttonLabeled('Forgot password?').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320dp at 200% text keeps register actions reachable without '
      'overflow', (tester) async {
    useSmallScreenLargeText(tester);
    await tester.pumpWidget(
      const AuthBlocksDemo(initiallyRegister: true, delay: Duration.zero),
    );
    await tester.pumpAndSettle();
    expect(buttonLabeled('Create account').hitTestable(), findsOneWidget);
    await tester.ensureVisible(find.text('Read terms and privacy policy'));
    await tester.pumpAndSettle();
    expect(
      find.text('Read terms and privacy policy').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
