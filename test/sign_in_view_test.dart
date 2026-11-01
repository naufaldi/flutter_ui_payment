// learnMore and footnote are deprecated but must keep working until 0.2.0.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'content_host.dart';

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
    expect(
      t.widget<RichText>(legal).text.toPlainText(),
      'By continuing you agree to Ruang Bayar’s Terms and Privacy.',
    );
    Future<void> tapSpan(String label) async {
      final paragraph = t.renderObject<RenderParagraph>(legal);
      final text = paragraph.text.toPlainText();
      final start = text.indexOf(label);
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + label.length),
      );
      await t.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
    }

    await tapSpan('Terms');
    await tapSpan('Privacy');
    expect(opened, ['terms', 'privacy']);
    // The legal sentence sits in the pinned footer, above the primary.
    final primary = t.getRect(find.byKey(const Key('continue')));
    expect(t.getRect(legal).bottom, lessThanOrEqualTo(primary.top));
    final cancel = t.getRect(find.widgetWithText(PaymentButton, 'Cancel'));
    expect(primary.width, cancel.width);
    expect(primary.top, lessThan(cancel.top));
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
    await t.tap(primary);
    expect(calls, 1);
    expect(find.byType(EditableText), findsNothing);
  });
}

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
