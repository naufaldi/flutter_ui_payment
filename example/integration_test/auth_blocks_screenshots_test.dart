import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui_example/auth_blocks_demo.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Native Android proof for the connected Authentication blocks (#391).
/// `--dart-define=CAPTURE_ONLY=<name>` is intentionally not used: the set is
/// small and each later capture depends on a fresh demo session.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture Authentication host blocks', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 2;

    Future<void> size(double width, double height) async {
      tester.view.physicalSize = Size(width * 2, height * 2);
      await tester.pump();
    }

    Future<void> start(
      Widget child, {
      double width = 360,
      double height = 640,
    }) async {
      await size(width, height);
      await tester.pumpWidget(child);
      await tester.pumpAndSettle();
    }

    Future<void> pressButton(String label) async {
      final target = find.byWidgetPredicate(
        (w) => w is PaymentButton && w.label == label,
      );
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> openRegister() async {
      final target = find.text('Create account').first;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> fillPassword([String value = 'notes123']) async {
      await tester.enterText(find.byType(TextFormField).at(1), value);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    }

    // Phone captures.
    for (final dark in [false, true]) {
      await start(
        AuthBlocksDemo(
          key: UniqueKey(),
          initialDark: dark,
          delay: Duration.zero,
          textScale: 1,
        ),
      );
      await capture(
        binding,
        tester,
        'android_block_login${dark ? '_dark' : ''}',
      );
    }

    await start(
      AuthBlocksDemo(key: UniqueKey(), delay: Duration.zero, textScale: 1),
    );
    await fillPassword();
    await pressButton('Log in');
    await capture(binding, tester, 'android_block_login_error');
    await pressButton('Log in');
    await capture(binding, tester, 'android_block_auth_home');

    for (final dark in [false, true]) {
      await start(
        AuthBlocksDemo(
          key: UniqueKey(),
          initialDark: dark,
          initialScenario: AuthDemoScenario.verificationRequired,
          delay: Duration.zero,
          textScale: 1,
        ),
      );
      await openRegister();
      await capture(
        binding,
        tester,
        'android_block_register${dark ? '_dark' : ''}',
      );
    }

    await start(
      AuthBlocksDemo(
        key: UniqueKey(),
        initialScenario: AuthDemoScenario.registrationFailsOnce,
        delay: Duration.zero,
        textScale: 1,
      ),
    );
    await openRegister();
    await fillPassword();
    await pressButton('Create account');
    await capture(binding, tester, 'android_block_register_error');

    await start(
      AuthBlocksDemo(
        key: UniqueKey(),
        initialScenario: AuthDemoScenario.verificationRequired,
        delay: Duration.zero,
        textScale: 1,
      ),
    );
    await openRegister();
    await fillPassword();
    await pressButton('Create account');
    await capture(binding, tester, 'android_block_verify');
    await tester.enterText(find.byType(TextFormField).first, '000000');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await pressButton('Verify email');
    await capture(binding, tester, 'android_block_verify_error');

    // Wide layout: the same full-page composition centres in its content
    // column without introducing a tablet-only layout.
    await start(
      AuthBlocksDemo(key: UniqueKey(), delay: Duration.zero, textScale: 1),
      width: 800,
      height: 700,
    );
    await capture(binding, tester, 'android_block_login_wide');
    await openRegister();
    await capture(binding, tester, 'android_block_register_wide');

    // B4 capture size: 320 dp at 200% text.
    await start(
      AuthBlocksDemo(key: UniqueKey(), delay: Duration.zero, textScale: 2),
      width: 320,
      height: 640,
    );
    await capture(binding, tester, 'android_block_login_200');
    await start(
      AuthBlocksDemo(
        key: UniqueKey(),
        delay: Duration.zero,
        textScale: 2,
        initiallyRegister: true,
      ),
      width: 320,
      height: 640,
    );
    await capture(binding, tester, 'android_block_register_200');
  });
}
