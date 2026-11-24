// learnMore and footnote are deprecated but still supported in 0.3.0.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:rakit_ui/rakit_ui.dart';
import 'package:rakit_ui/src/foundation/focus_ring.dart';
import 'package:rakit_ui/src/foundation/motion_swap.dart';
import 'content_host.dart';
import 'helpers/reduced_motion.dart';

void main() {
  testWidgets(
    'every sign-in slot contains no credential editor and calls host',
    (t) async {
      await setSurface(t, const Size(800, 900));
      var calls = 0;
      await t.pumpWidget(
        contentHost(
          SizedBox(
            height: 700,
            child: PaymentSignInView(
              primaryAction: PaymentButton(
                label: 'Continue with bank',
                onPressed: () {
                  calls++;
                },
              ),
              brand: const PaymentIcon(Icons.account_balance),
              description: 'Connect with your bank app',
              secondaryAction: PaymentButton(
                label: 'Another account',
                variant: PaymentButtonVariant.secondary,
                onPressed: () {
                  calls++;
                },
              ),
              learnMore: PaymentSignInLearnMore(
                label: 'What we can see',
                title: 'Permissions',
                builder: (_) => const Text('Payment history only'),
              ),
              legalLinks: [PaymentLink(label: 'Privacy', onPressed: () {})],
              footnote: 'We never ask for your PIN here.',
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(PaymentSignInView),
          matching: find.byType(EditableText),
        ),
        findsNothing,
      );
      expect(find.byType(PaymentListItem), findsOneWidget);
      // The brand tile starts on the title edge.
      expect(
        t
            .getTopLeft(
              find
                  .ancestor(
                    of: find.byType(PaymentIcon).first,
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .dx,
        t.getTopLeft(find.text('Sign in to continue')).dx,
      );
      await t.tap(find.text('Continue with bank'));
      await t.pumpAndSettle();
      expect(calls, 1);
      await t.tap(find.text('What we can see'));
      await t.pumpAndSettle();
      expect(find.byType(PaymentFocusView), findsOneWidget);
      expect(find.text('Permissions'), findsOneWidget);
    },
  );
  testWidgets('error banner is focused and default title is localized', (
    t,
  ) async {
    await t.pumpWidget(
      contentHost(
        SizedBox(
          height: 700,
          child: PaymentSignInView(
            primaryAction: PaymentButton(label: 'Continue', onPressed: () {}),
            errorText: 'Sign-in canceled',
          ),
        ),
        locale: const Locale('id'),
      ),
    );
    await t.pump();
    expect(find.text('Masuk untuk melanjutkan'), findsOneWidget);
    expect(find.byType(PaymentBanner), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(t.takeException(), isNull);
  });

  // D61: account linking, can / cannot in plain view, pinned footer.
  PaymentSignInView linking({
    required VoidCallback onTerms,
    required VoidCallback onPrivacy,
    required VoidCallback onContinue,
    bool id = false,
  }) => PaymentSignInView(
    requesterBrand: const PaymentIcon(Icons.school_outlined),
    brand: const PaymentIcon(Icons.account_balance_wallet_outlined),
    title: id ? 'Masuk dengan Ruang Bayar' : 'Sign in with Ruang Bayar',
    description: id
        ? 'Untuk membayar dan melihat pembayaran Anda di Toko Belajar.'
        : 'To pay and see your payments in Toko Belajar.',
    canDo: id
        ? [
            'Melihat nama dan nomor akun Anda',
            'Meminta pembayaran, selalu dengan konfirmasi Anda',
          ]
        : [
            'See your name and account number',
            'Request payments, always with your confirmation',
          ],
    cannotDo: [id ? 'Melihat PIN atau saldo Anda' : 'See your PIN or balance'],
    legalNotice: id
        ? 'Dengan melanjutkan, Anda menyetujui {0} dan {1} Ruang Bayar.'
        : 'By continuing you agree to Ruang Bayar’s {0} and {1}.',
    legalLinks: [
      PaymentLink(label: id ? 'Ketentuan' : 'Terms', onPressed: onTerms),
      PaymentLink(label: id ? 'Privasi' : 'Privacy', onPressed: onPrivacy),
    ],
    primaryAction: PaymentButton(
      key: const Key('continue'),
      label: id ? 'Lanjutkan' : 'Continue',
      onPressed: onContinue,
    ),
    secondaryAction: PaymentButton(
      label: id ? 'Batal' : 'Cancel',
      variant: PaymentButtonVariant.quiet,
      onPressed: () {},
    ),
  );

  testWidgets('can and cannot lists render and legal links call the host', (
    t,
  ) async {
    await setSurface(t, const Size(393, 844));
    final opened = <String>[];
    await t.pumpWidget(
      boundedHost(
        linking(
          onTerms: () => opened.add('terms'),
          onPrivacy: () => opened.add('privacy'),
          onContinue: () => opened.add('continue'),
        ),
      ),
    );
    expect(find.text('This app can'), findsOneWidget);
    expect(find.text('It can never'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    final legal = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().startsWith('By continuing'),
    );
    // The links sit inside the one sentence, in reading order.
    expect(
      t.widget<RichText>(legal).text.toPlainText(),
      'By continuing you agree to Ruang Bayar’s ￼ and ￼.',
    );
    expect(
      find.descendant(of: legal, matching: find.text('Terms')),
      findsOneWidget,
    );
    await t.tap(find.text('Terms'));
    await t.tap(find.text('Privacy'));
    expect(opened, ['terms', 'privacy']);
    // The legal sentence sits in the pinned footer, above the primary.
    final primary = t.getRect(find.byKey(const Key('continue')));
    expect(t.getRect(legal).bottom, lessThanOrEqualTo(primary.top));
    final cancel = t.getRect(find.widgetWithText(PaymentButton, 'Cancel'));
    expect(primary.width, cancel.width);
    expect(primary.top, lessThan(cancel.top));
  });

  // #235: a keyboard user reaches Terms and Privacy in the sentence, sees
  // the focus ring and opens each with Enter or Space.
  testWidgets('keyboard reaches and opens the inline legal links', (t) async {
    await setSurface(t, const Size(393, 844));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final opened = <String>[];
    await t.pumpWidget(
      boundedHost(
        linking(
          onTerms: () => opened.add('terms'),
          onPrivacy: () => opened.add('privacy'),
          onContinue: () => opened.add('continue'),
        ),
      ),
    );
    bool focusedOn(String label) =>
        Focus.of(t.element(find.text(label))).hasPrimaryFocus;

    Finder ring(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.foregroundPainter is FocusRingPainter,
      ),
    );

    for (var i = 0; i < 8 && !focusedOn('Terms'); i++) {
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
    }
    expect(focusedOn('Terms'), isTrue);
    expect(ring('Terms'), findsOneWidget);
    expect(ring('Privacy'), findsNothing);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(opened, ['terms']);

    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(focusedOn('Privacy'), isTrue);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    expect(opened, ['terms', 'privacy']);

    // Reading order continues to the primary action.
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(focusedOn('Continue'), isTrue);

    // Screen readers still get a named link.
    final terms = t.getSemantics(find.text('Terms'));
    expect(terms.label, 'Terms');
    expect(terms.flagsCollection.isLink, isTrue);
  });

  testWidgets('small phone, 2x, Indonesian: the primary is on screen (#58-1)', (
    t,
  ) async {
    await setSurface(t, const Size(375, 667));
    var calls = 0;
    await t.pumpWidget(
      boundedHost(
        linking(
          id: true,
          onTerms: () {},
          onPrivacy: () {},
          onContinue: () => calls++,
        ),
        scale: 2,
        locale: const Locale('id'),
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.text('Aplikasi ini bisa'), findsOneWidget);
    final primary = find.byKey(const Key('continue'));
    expect(primary.hitTestable(), findsOneWidget);
    expect(t.getRect(primary).bottom, lessThanOrEqualTo(667));
    // The legal links stay readable and tappable in the wrapped sentence.
    expect(find.text('Ketentuan').hitTestable(), findsOneWidget);
    expect(find.text('Privasi').hitTestable(), findsOneWidget);
    await t.tap(primary);
    expect(calls, 1);
    expect(find.byType(EditableText), findsNothing);
  });

  // #310, D128: the error slot hands off with the shared full-width swap.
  group('error slot motion', () {
    PaymentSignInView signIn(String? error, {VoidCallback? onContinue}) =>
        PaymentSignInView(
          primaryAction: PaymentButton(
            label: 'Continue',
            onPressed: onContinue ?? () {},
          ),
          footnote: 'We never ask for your PIN here.',
          errorText: error,
        );

    double groupGap(WidgetTester t) => PaymentTheme.of(
      t.element(find.byType(PaymentSignInView)),
    ).space(PaymentSpace.group);

    testWidgets('a canceled attempt exposes the error without scrolling '
        'and Continue can retry at large text', (t) async {
      await setSurface(t, const Size(320, 640));
      final semantics = t.ensureSemantics();
      var attempts = 0;
      await t.pumpWidget(
        boundedHost(
          StatefulBuilder(
            builder: (context, setState) => PaymentSignInView(
              canDo: List.filled(6, 'See your name and account number'),
              primaryAction: PaymentButton(
                label: 'Continue',
                onPressed: () => setState(() => attempts++),
              ),
              errorText: attempts == 1
                  ? 'Sign-in was canceled. Try again.'
                  : null,
            ),
          ),
          scale: 2,
        ),
      );

      await t.tap(find.text('Continue'));
      await t.pump();
      expect(_spoken(t, visibleOnly: true), contains('Sign-in was canceled.'));
      await t.pumpAndSettle();
      expect(
        find.text('Sign-in was canceled. Try again.').hitTestable(),
        findsOneWidget,
      );
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(attempts, 2);
      expect(_spoken(t), isNot(contains('Sign-in was canceled.')));
      expect(t.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('a long legal notice leaves Cancel usable before an error', (
      t,
    ) async {
      await setSurface(t, const Size(320, 440));
      var canceled = false;
      await t.pumpWidget(
        boundedHost(
          PaymentSignInView(
            legalNotice: List.filled(8, 'Terms').join('\n'),
            primaryAction: PaymentButton(label: 'Continue', onPressed: () {}),
            secondaryAction: PaymentButton(
              label: 'Cancel',
              variant: PaymentButtonVariant.quiet,
              onPressed: () => canceled = true,
            ),
          ),
          scale: 2,
        ),
      );
      expect(t.takeException(), isNull);
      await t.tap(find.text('Cancel'));
      expect(canceled, isTrue);
    });

    testWidgets('adding legal text does not hide an error in a short host', (
      t,
    ) async {
      await setSurface(t, const Size(320, 240));
      final semantics = t.ensureSemantics();
      var attempts = 0;
      final notice = List.filled(8, 'Terms').join('\n');
      await t.pumpWidget(
        boundedHost(
          StatefulBuilder(
            builder: (context, setState) => PaymentSignInView(
              legalNotice: attempts > 0 ? notice : null,
              errorText: attempts > 1 ? 'Try again' : 'Retry',
              primaryAction: PaymentButton(
                label: 'Continue',
                onPressed: () => setState(() => attempts++),
              ),
              secondaryAction: PaymentButton(
                label: 'Cancel',
                variant: PaymentButtonVariant.quiet,
                onPressed: () {},
              ),
            ),
          ),
          scale: 2,
        ),
      );
      expect(_spoken(t, visibleOnly: true), contains('Retry'));
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(_spoken(t, visibleOnly: true), contains('Retry'));
      final noticeScroll = find.ancestor(
        of: find.text(notice),
        matching: find.byType(Scrollable),
      );
      await t.drag(noticeScroll, const Offset(0, -150));
      await t.pumpAndSettle();
      expect(_spoken(t, visibleOnly: true), contains('Terms'));
      expect(_spoken(t, visibleOnly: true), isNot(contains('Retry')));
      await t.tap(find.text('Continue'));
      await t.pump();
      expect(_spoken(t, visibleOnly: true), contains('Try again'));
      expect(t.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets(
      'a long error leaves permissions scrollable and Continue visible',
      (t) async {
        await setSurface(t, const Size(320, 440));
        var retried = false;
        const lastPermission = 'Name';
        await t.pumpWidget(
          boundedHost(
            PaymentSignInView(
              canDo: const [
                'See your name and account number',
                'Ask you to confirm a payment',
                lastPermission,
              ],
              legalNotice:
                  'By continuing you agree to the terms and privacy policy.',
              primaryAction: PaymentButton(
                label: 'Continue',
                onPressed: () => retried = true,
              ),
              secondaryAction: PaymentButton(
                label: 'Cancel',
                variant: PaymentButtonVariant.quiet,
                onPressed: () {},
              ),
              errorText:
                  'Sign-in was canceled. Return to your bank app and '
                  'approve the connection, then try again here.',
            ),
            scale: 2,
          ),
        );
        expect(t.takeException(), isNull);
        expect(t.getBottomLeft(find.text('Cancel')).dy, lessThanOrEqualTo(440));
        final permission = find.text(lastPermission);
        expect(permission.hitTestable(), findsNothing);
        final permissionsScroll = find.ancestor(
          of: permission,
          matching: find.byType(Scrollable),
        );
        await t.dragUntilVisible(
          permission.hitTestable(),
          permissionsScroll,
          const Offset(0, -48),
          maxIteration: 40,
        );
        expect(permission.hitTestable(), findsOneWidget);
        await t.tap(find.text('Continue'));
        expect(retried, isTrue);
      },
    );

    testWidgets('a new long error starts at the top after the previous one', (
      t,
    ) async {
      await setSurface(t, const Size(320, 440));
      var attempts = 0;
      await t.pumpWidget(
        boundedHost(
          StatefulBuilder(
            builder: (context, setState) => PaymentSignInView(
              legalNotice: 'Terms apply.',
              errorText: switch (attempts) {
                0 =>
                  'Canceled. ${List.filled(12, 'Check your bank.').join(' ')}',
                1 => null,
                _ => 'Expired. ${List.filled(12, 'Open your bank.').join(' ')}',
              },
              primaryAction: PaymentButton(
                label: 'Continue',
                onPressed: () => setState(() => attempts++),
              ),
            ),
          ),
          scale: 2,
        ),
      );
      final banner = find.byType(PaymentBanner);
      final start = banner.hitTestable(at: const Alignment(0, -0.98));
      expect(start, findsOneWidget);
      await t.drag(
        find.ancestor(of: banner, matching: find.byType(Scrollable)),
        const Offset(0, -160),
      );
      await t.pumpAndSettle();
      expect(start, findsNothing);
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(banner, findsNothing);
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(start, findsOneWidget);
    });

    testWidgets('the error fades beside the pinned action and '
        'the empty slot leaves no gap', (t) async {
      await t.pumpWidget(boundedHost(signIn(null)));
      final body = find.byType(SingleChildScrollView);
      final readyBody = t.getSize(body);
      final action = find.widgetWithText(PaymentButton, 'Continue');
      final actionRect = t.getRect(action);
      final gap = groupGap(t);

      await t.pumpWidget(boundedHost(signIn('Sign-in failed')));
      await t.pump(const Duration(milliseconds: 60));
      expect(t.hasRunningAnimations, isTrue, reason: 'mid-swap');
      final banner = find.byType(PaymentBanner);
      expect(banner, findsOneWidget);
      expect(t.getRect(action), actionRect);
      await t.pumpAndSettle();
      expect(
        t.getTopLeft(action).dy - t.getBottomLeft(banner).dy,
        closeTo(gap, 0.5),
      );

      await t.pumpWidget(boundedHost(signIn(null)));
      await t.pumpAndSettle();
      expect(find.byType(PaymentBanner), findsNothing);
      expect(t.getSize(body), readyBody);
      expect(t.getRect(action), actionRect);
    });

    testWidgets('the error reaches semantics on the first frame of each '
        'handoff', (t) async {
      final semantics = t.ensureSemantics();
      await t.pumpWidget(boundedHost(signIn(null)));

      await t.pumpWidget(boundedHost(signIn('Sign-in failed')));
      expect(_opacityOf(t, find.text('Sign-in failed')), 0);
      expect(
        _spoken(t, visibleOnly: true),
        contains('Sign-in failed'),
        reason: 'visible to accessibility on the first frame',
      );
      await t.pump(const Duration(milliseconds: 40));
      // Still fading in, already in the semantics tree.
      expect(
        _opacityOf(t, find.text('Sign-in failed')),
        inExclusiveRange(0, 1),
      );
      expect(_spoken(t), contains('Sign-in failed'));
      await t.pumpAndSettle();

      await t.pumpWidget(boundedHost(signIn(null)));
      // The swap's first clear frame: still painted, already out of
      // semantics (topLayout's ExcludeSemantics).
      expect(find.text('Sign-in failed'), findsOneWidget);
      expect(_spoken(t), isNot(contains('Sign-in failed')));
      await t.pump(const Duration(milliseconds: 40));
      expect(find.text('Sign-in failed'), findsOneWidget, reason: 'fading');
      expect(_spoken(t), isNot(contains('Sign-in failed')));
      await t.pumpAndSettle();
      expect(find.byType(PaymentBanner), findsNothing);
      semantics.dispose();
    });

    testWidgets('a rapid clear and reappear shows only the current error', (
      t,
    ) async {
      await t.pumpWidget(boundedHost(signIn('First problem')));
      await t.pumpAndSettle();
      await t.pumpWidget(boundedHost(signIn(null)));
      await t.pump(const Duration(milliseconds: 40)); // mid-exit
      await t.pumpWidget(boundedHost(signIn('Second problem')));
      await t.pumpAndSettle();
      expect(find.byType(PaymentBanner), findsOneWidget);
      expect(find.text('Second problem'), findsOneWidget);
      expect(find.text('First problem'), findsNothing);
    });

    testWidgets('error focus drops on clear, returns on reappear, and the '
        'primary stays usable', (t) async {
      var calls = 0;
      await t.pumpWidget(boundedHost(signIn(null, onContinue: () => calls++)));
      await t.pumpWidget(
        boundedHost(signIn('Sign-in failed', onContinue: () => calls++)),
      );
      await t.pump();
      // One stable Focus wraps the swap; it is the node focusError asked for.
      final focusFinder = find.byWidgetPredicate(
        (w) => w is Focus && w.child is MotionSwap,
      );
      expect(focusFinder, findsOneWidget);
      final node = t.widget<Focus>(focusFinder).focusNode!;
      expect(FocusManager.instance.primaryFocus, same(node));

      // Outside the swap: the primary works while the banner fades in.
      await t.tap(find.text('Continue'));
      expect(calls, 1);

      await t.pumpWidget(boundedHost(signIn(null)));
      await t.pump();
      expect(node.hasFocus, isFalse);
      expect(FocusManager.instance.primaryFocus, isNot(same(node)));

      await t.pumpWidget(boundedHost(signIn('Try again later')));
      await t.pump();
      expect(FocusManager.instance.primaryFocus, same(node));
    });

    testWidgets('the error swap is instant under reduced motion', (t) async {
      const setup = ReducedMotion.mediaQuery;
      await t.pumpWidget(setup.apply(t, boundedHost(signIn(null))));
      await expectStill(
        t,
        () =>
            t.pumpWidget(setup.apply(t, boundedHost(signIn('Sign-in failed')))),
      );
      expect(find.byType(PaymentBanner), findsOneWidget);
      expect(find.byType(AnimatedSize), findsNothing);
    });

    testWidgets('reduced motion turned on mid-swap ends it at once', (t) async {
      await t.pumpWidget(boundedHost(signIn(null)));
      await t.pumpWidget(boundedHost(signIn('Sign-in failed')));
      await t.pump(const Duration(milliseconds: 60));
      expect(find.byType(AnimatedSize), findsOneWidget, reason: 'easing');

      ReducedMotion.iosReduceMotion.apply(t, const SizedBox());
      await t.pump();
      expect(find.byType(AnimatedSize), findsNothing);
      expect(find.byType(PaymentBanner), findsOneWidget);
      expect(_opacityOf(t, find.text('Sign-in failed')), 1);
      expect(t.hasRunningAnimations, isFalse);
    });
  });
}

/// The lowest opacity any fade above [finder] paints it at.
double _opacityOf(WidgetTester t, Finder finder) => t
    .widgetList<FadeTransition>(
      find.ancestor(of: finder, matching: find.byType(FadeTransition)),
    )
    .map((fade) => fade.opacity.value)
    .reduce((a, b) => a < b ? a : b);

/// What a screen reader's traversal can reach, as one string.
String _spoken(WidgetTester t, {bool visibleOnly = false}) => t.semantics
    .simulatedAccessibilityTraversal()
    .map((node) => node.getSemanticsData())
    .where((data) => !visibleOnly || !data.flagsCollection.isHidden)
    .map((data) => '${data.label} ${data.value} ${data.hint}')
    .join(' | ');

Widget boundedHost(
  Widget child, {
  double scale = 1,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  theme: ThemeData(platform: TargetPlatform.iOS),
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  ),
);
