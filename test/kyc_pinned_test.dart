import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';

// D62 (UI review P7a): the KYC form steps inside PaymentOnboardingView pin
// their submit at the bottom; without a controller or primaryAction they
// keep the inline button.

Widget screen(Widget child, {double scale = 1}) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void surface(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

String? required(String v) => v.isEmpty ? 'Required' : null;

// Enough fields to overflow a small phone at 2x.
final fields = [
  for (final key in ['name', 'nik', 'mother', 'address', 'city'])
    IdentityFieldSpec(key: key, label: 'Field $key', validator: required),
];

const tasks = [
  PaymentTaskListItem(title: 'Details', status: PaymentTaskStatus.inProgress),
  PaymentTaskListItem(title: 'Documents'),
  PaymentTaskListItem(title: 'Review'),
];

bool pinned(Finder f) =>
    find.ancestor(of: f, matching: find.byType(Scrollable)).evaluate().isEmpty;

const doc = DocumentRequirement(
  key: 'id',
  label: 'ID card',
  acceptedTypes: {'image/jpeg'},
  maxBytes: 1000,
);
const file = DocumentFile(
  name: 'ktp.jpg',
  mimeType: 'image/jpeg',
  sizeBytes: 9,
);

void main() {
  testWidgets('identity: pinned primary is on screen at 375x667, 2x', (
    t,
  ) async {
    surface(t, const Size(375, 667));
    final controller = IdentityFormController();
    addTearDown(controller.dispose);
    Map<String, String>? sent;
    await t.pumpWidget(
      screen(
        PaymentOnboardingView(
          title: 'Verify your identity',
          tasks: tasks,
          primaryAction: PaymentButton(
            key: const Key('go'),
            label: 'Continue',
            onPressed: controller.submit,
          ),
          child: IdentityForm(
            fields: fields,
            controller: controller,
            onSubmit: (v) => sent = v,
          ),
        ),
        scale: 2,
      ),
    );
    await t.pump();
    final go = find.byKey(const Key('go'));
    expect(go, findsOneWidget);
    // The form's own button is gone: one Continue, in the footer.
    expect(find.text('Continue'), findsOneWidget);
    expect(pinned(go), isTrue);
    expect(go.hitTestable(), findsOneWidget);
    expect(t.getRect(go).bottom, lessThanOrEqualTo(667));
    expect(t.getRect(go).width, greaterThan(300));
    // The content scrolls behind it: the last field is off screen.
    expect(find.text('Field city').hitTestable(), findsNothing);
    expect(controller.canSubmit, isTrue);

    await t.tap(go);
    await t.pump();
    expect(sent, isNull);
    expect(find.text('Required'), findsWidgets);
  });

  testWidgets('controller.submit validates and focuses the first error', (
    t,
  ) async {
    surface(t, const Size(393, 1400));
    final controller = IdentityFormController();
    addTearDown(controller.dispose);
    final calls = <Map<String, String>>[];
    var notified = 0;
    controller.addListener(() => notified++);
    await t.pumpWidget(
      screen(
        SingleChildScrollView(
          child: IdentityForm(
            fields: fields,
            initialValues: const {'name': 'Sari'},
            controller: controller,
            onSubmit: (v) async {
              expect(controller.busy, isTrue);
              await Future<void>.delayed(const Duration(milliseconds: 10));
              calls.add(v);
            },
          ),
        ),
      ),
    );
    await t.pump();
    expect(controller.canSubmit, isTrue);
    expect(find.byType(PaymentButton), findsNothing);

    var ok = false;
    await t.runAsync(() async => ok = await controller.submit());
    await t.pump();
    expect(ok, isFalse);
    expect(calls, isEmpty);
    // 'name' is filled, so focus lands on the first invalid field, 'nik'.
    final nik = find.ancestor(
      of: find.text('Field nik'),
      matching: find.byType(PaymentTextField),
    );
    expect(
      t.widget<PaymentTextField>(nik).focusNode!.hasFocus,
      isTrue,
      reason: 'focus moves to the first invalid field',
    );
    expect(find.text('Required'), findsNWidgets(4));

    for (final key in ['nik', 'mother', 'address', 'city']) {
      await t.enterText(
        find.descendant(
          of: find.ancestor(
            of: find.text('Field $key'),
            matching: find.byType(PaymentTextField),
          ),
          matching: find.byType(EditableText),
        ),
        'x',
      );
    }
    notified = 0;
    await t.runAsync(() async {
      final first = controller.submit();
      // A second submit while the first runs is refused.
      expect(await controller.submit(), isFalse);
      ok = await first;
    });
    expect(ok, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single['name'], 'Sari');
    expect(controller.busy, isFalse);
    expect(notified, greaterThanOrEqualTo(2));

    // Detached when the form leaves the tree.
    await t.pumpWidget(screen(const SizedBox()));
    await t.pump();
    expect(controller.canSubmit, isFalse);
    expect(await controller.submit(), isFalse);
  });

  testWidgets('back-compat: no controller or action keeps the inline button', (
    t,
  ) async {
    surface(t, const Size(393, 1400));
    Map<String, String>? sent;
    await t.pumpWidget(
      screen(
        PaymentOnboardingView(
          title: 'Verify your identity',
          tasks: tasks,
          child: IdentityForm(
            fields: fields.take(1).toList(),
            onSubmit: (v) => sent = v,
          ),
        ),
      ),
    );
    final inline = find.widgetWithText(PaymentButton, 'Continue');
    expect(inline, findsOneWidget);
    // In the content's scroll region, not a footer.
    expect(pinned(inline), isFalse);
    await t.tap(inline);
    await t.pump();
    expect(sent, isNull);
    expect(find.text('Required'), findsOneWidget);
    await t.enterText(find.byType(EditableText), 'Sari');
    await t.tap(inline);
    await t.pump();
    expect(sent, {'name': 'Sari'});

    // The review keeps its inline submit by default.
    await t.pumpWidget(
      screen(
        SingleChildScrollView(
          child: VerificationReview(
            fields: const [],
            values: const {},
            documents: const [
              (doc, DocumentSlotState.uploaded(file, requestId: 'r')),
            ],
            onSubmit: () async {},
          ),
        ),
      ),
    );
    expect(
      find.widgetWithText(PaymentButton, 'Submit for verification'),
      findsOneWidget,
    );
  });

  testWidgets('review: submit pins at 375x667, 2x; disabled until ready', (
    t,
  ) async {
    surface(t, const Size(375, 667));
    var submits = 0;
    Widget review(DocumentSlotState slot) => screen(
      Builder(
        builder: (context) {
          final documents = [(doc, slot)];
          return PaymentOnboardingView(
            title: 'Verify your identity',
            tasks: tasks,
            primaryAction: VerificationReview.submitButton(
              context,
              key: const Key('submit'),
              documents: documents,
              onSubmit: () async => submits++,
            ),
            child: VerificationReview(
              fields: fields,
              values: const {'name': 'Sari'},
              documents: documents,
              onSubmit: () async => submits++,
              inlineSubmit: false,
            ),
          );
        },
      ),
      scale: 2,
    );
    await t.pumpWidget(
      review(const DocumentSlotState.uploaded(file, requestId: 'r')),
    );
    final submit = find.byKey(const Key('submit'));
    expect(find.text('Submit for verification'), findsOneWidget);
    expect(pinned(submit), isTrue);
    expect(submit.hitTestable(), findsOneWidget);
    await t.tap(submit);
    await t.pump();
    expect(submits, 1);

    await t.pumpWidget(review(const DocumentSlotState.empty()));
    expect(t.widget<PaymentButton>(submit).onPressed, isNull);
    // The missing-documents banner stays in the content.
    expect(find.byType(PaymentBanner), findsOneWidget);
    expect(pinned(find.byType(PaymentBanner)), isFalse);
  });

  testWidgets('no footer while pending or completed', (t) async {
    surface(t, const Size(375, 667));
    Widget view({bool pending = false, bool completed = false}) => screen(
      PaymentOnboardingView(
        title: 'Verify your identity',
        tasks: tasks,
        pending: pending,
        completed: completed,
        primaryAction: PaymentButton(label: 'Go', onPressed: () {}),
        child: const Text('Step'),
      ),
    );
    await t.pumpWidget(view());
    expect(find.text('Go'), findsOneWidget);
    await t.pumpWidget(view(pending: true));
    expect(find.text('Go'), findsNothing);
    await t.pumpWidget(view(completed: true));
    await t.pump();
    expect(find.text('Go'), findsNothing);
  });
}
