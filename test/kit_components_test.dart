import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'first_line_test.dart' show host;

Widget app(Widget home, {bool reduceMotion = false}) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: const [Locale('en'), Locale('id')],
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: home,
);

/// Records the commands the player widget sends to the host's engine.
class FakeVideo extends PaymentVideoController {
  final calls = <String>[];

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    value = value.copyWith(
      phase: VideoPhase.ready,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  Future<void> play() async {
    calls.add('play');
    value = value.copyWith(phase: VideoPhase.playing);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    value = value.copyWith(phase: VideoPhase.paused);
  }

  @override
  Future<void> seekTo(Duration position) async => calls.add('seek');

  @override
  Future<void> setMuted(bool muted) async {
    calls.add('mute:$muted');
    value = value.copyWith(muted: muted);
  }

  @override
  Future<void> retry() async {
    calls.add('retry');
    await initialize();
  }

  @override
  Widget buildSurface(BuildContext context) => const SizedBox.expand();
}

void main() {
  testWidgets('action bar at 2x keeps one height while updating toggles', (
    tester,
  ) async {
    Widget bar(bool updating) => host(
      Align(
        alignment: Alignment.bottomCenter,
        child: PaymentActionBar(
          total: const Money.idr(102500),
          updating: updating,
          action: PaymentButton(
            label: 'Pay',
            width: PaymentWidth.hug,
            onPressed: updating ? null : () {},
          ),
        ),
      ),
      2,
    );
    await tester.pumpWidget(bar(false));
    await tester.pumpAndSettle();
    final settled = tester.getSize(find.byType(PaymentActionBar)).height;
    await tester.pumpWidget(bar(true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PaymentActionBar)).height, settled);
    expect(find.text('Updating total…'), findsOneWidget);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('document tile badge placement at ${scale}x', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          DocumentUploadTile(
            requirement: const DocumentRequirement(
              key: 'ktp',
              label: 'KTP',
              acceptedTypes: {'image/jpeg', 'image/png'},
              acceptedTypesLabel: 'JPG, PNG',
              maxBytes: 5 * 1024 * 1024,
            ),
            state: const DocumentSlotState.empty(),
            onPick: () {},
          ),
          scale,
        ),
      );
      final title = tester.getRect(find.text('KTP'));
      final badge = tester.getRect(find.byType(PaymentBadge));
      final limits = tester.getRect(find.textContaining('5 MB'));
      if (scale == 1) {
        // Beside the title, on its first line.
        expect(badge.left, greaterThan(title.right));
        expect(badge.top, lessThan(limits.top));
      } else {
        // Under the limits, as wide as it needs: no word breaks.
        expect(badge.top, greaterThanOrEqualTo(limits.bottom));
        expect(badge.left, title.left);
      }
    });
  }
  testWidgets('countdown keeps one width from 1:00:00 to 59:59', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 1, 10);
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topLeft,
          child: CountdownText(
            expiresAt: DateTime(2026, 11, 1, 11),
            clock: () => now,
          ),
        ),
        1,
      ),
    );
    expect(find.text('1:00:00'), findsOneWidget);
    final width = tester.getSize(find.byType(CountdownText)).width;
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('59:59'), findsOneWidget);
    expect(tester.getSize(find.byType(CountdownText)).width, width);
  });
  testWidgets('skeleton rows are as tall as two-line list rows', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              PaymentListItem(
                title: 'Groceries',
                secondaryTitle: 'Paid 2 days ago',
                icon: Icons.receipt_long_outlined,
              ),
              LoadingSkeleton(rows: 1),
            ],
          ),
          scale,
        ),
      );
      expect(
        tester.getSize(find.byType(LoadingSkeleton)).height,
        tester.getSize(find.byType(PaymentListItem)).height,
        reason: 'scale $scale',
      );
    }
  });
  group('AdaptiveNavShell', () {
    final sections = [
      const PaymentNavSection(
        items: [
          PaymentNavItem(id: 'a', label: 'Home', icon: Icons.home),
          PaymentNavItem(id: 'b', label: 'History', icon: Icons.history),
          PaymentNavItem(
            id: 'c',
            label: 'Limits',
            icon: Icons.speed,
            enabled: false,
            disabledReason: 'Verify first',
          ),
        ],
      ),
    ];

    Widget shell(ValueChanged<String> onSelected, {String selected = 'a'}) =>
        app(
          AdaptiveNavShell(
            title: const Text('Shell'),
            sections: sections,
            selectedId: selected,
            onSelected: (item) => onSelected(item.id),
            body: const Text('Body'),
          ),
        );

    testWidgets('narrow: drawer selects, closes and never offers disabled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final picked = <String>[];
      await tester.pumpWidget(shell(picked.add));
      // Closed drawer items are not in the tree, so not tabbable.
      expect(find.text('History'), findsNothing);

      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      expect(find.text('Verify first'), findsOneWidget);
      await tester.tap(find.text('Limits'));
      await tester.pumpAndSettle();
      expect(picked, isEmpty);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(picked, ['b']);
      expect(find.text('History'), findsNothing);
    });

    testWidgets('narrow: Escape closes the drawer and focus returns', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(shell((_) {}));
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('History'), findsNothing);
      final menu = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.menu),
      );
      expect(menu.focusNode!.hasFocus, isTrue);
    });

    testWidgets('wide: permanent sidebar marks the selected item', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(shell((_) {}, selected: 'b'));
      expect(find.byTooltip('Open navigation'), findsNothing);
      expect(
        tester.getSemantics(find.text('History')),
        isSemantics(isSelected: true, isButton: true),
      );
      handle.dispose();
    });

    testWidgets('count badge text is at least the 12 px tag size', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: NavSidebar(
              sections: const [
                PaymentNavSection(
                  items: [
                    PaymentNavItem(
                      id: 'p',
                      label: 'Pending',
                      icon: Icons.schedule,
                      badge: '2',
                    ),
                  ],
                ),
              ],
              selectedId: 'p',
              onSelected: (_) {},
            ),
          ),
        ),
      );
      final badge = tester.widget<Text>(find.text('2'));
      expect(badge.style!.fontSize, greaterThanOrEqualTo(12));
    });
    testWidgets('selection shows weight and a start indicator; rows are 48', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: NavSidebar(
              sections: const [
                PaymentNavSection(
                  items: [
                    PaymentNavItem(id: 'a', label: 'Home', icon: Icons.home),
                    PaymentNavItem(
                      id: 'b',
                      label: 'Payments',
                      icon: Icons.list,
                    ),
                  ],
                ),
              ],
              selectedId: 'a',
              onSelected: (_) {},
            ),
          ),
        ),
      );
      final selected = tester.widget<Text>(find.text('Home'));
      final other = tester.widget<Text>(find.text('Payments'));
      expect(selected.style!.fontWeight, FontWeight.w600);
      expect(other.style!.fontWeight, FontWeight.w400);
      final indicator = find.byKey(const ValueKey('nav-selected-indicator'));
      expect(indicator, findsOneWidget);
      final context = tester.element(indicator);
      expect(
        (tester.widget<DecoratedBox>(indicator).decoration as BoxDecoration)
            .color,
        PaymentTheme.of(context).accent,
      );
      expect(tester.getSize(indicator).width, 2);
      expect(
        tester.getTopLeft(indicator).dx,
        tester.getTopLeft(find.byType(InkWell).first).dx,
      );
      expect(
        tester.getTopLeft(find.text('Payments')).dy -
            tester.getTopLeft(find.text('Home')).dy,
        48,
      );
    });
  });

  group('Sheets', () {
    testWidgets('bottom sheet header and body use the 16 dp gutter', (
      tester,
    ) async {
      // Phone width, so the sheet spans the screen instead of centering at
      // its 640 dp maximum.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPaymentSheet<void>(
                  context: context,
                  builder: (_) => const PaymentSheet(
                    header: PaymentSheetHeader(title: 'Title'),
                    body: Text('Body'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Body')).dx, 16);
      expect(tester.getTopLeft(find.text('Title')).dx, 16);
    });
  });

  group('PaymentVideoPlayer', () {
    testWidgets('loading in background cannot trigger autoplay', (
      tester,
    ) async {
      final video = FakeVideo();
      video.value = const VideoPlaybackValue(phase: VideoPhase.loading);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PaymentVideoPlayer(
              controller: video,
              title: 'Demo',
              autoPlay: true,
            ),
          ),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      video.value = video.value.copyWith(
        phase: VideoPhase.ready,
        duration: const Duration(seconds: 8),
      );
      await tester.pump();
      expect(video.calls, isNot(contains('play')));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(video.calls, isNot(contains('play')));
    });

    testWidgets('loads but never autoplays by default', (tester) async {
      final video = FakeVideo();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PaymentVideoPlayer(controller: video, title: 'Demo'),
          ),
        ),
      );
      await tester.pump();
      expect(video.calls, ['initialize']);
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(video.calls.last, 'play');
      await tester.tap(find.byTooltip('Mute'));
      await tester.pump();
      expect(video.calls.last, 'mute:true');
    });

    testWidgets('reduced motion blocks autoPlay', (tester) async {
      final video = FakeVideo();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PaymentVideoPlayer(
              controller: video,
              title: 'Demo',
              autoPlay: true,
            ),
          ),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      expect(video.calls, isNot(contains('play')));
    });

    testWidgets('pauses on background, when hidden and when removed', (
      tester,
    ) async {
      final video = FakeVideo();
      var visible = true;
      late StateSetter set;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return TickerMode(
                  enabled: visible,
                  child: PaymentVideoPlayer(controller: video, title: 'Demo'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await video.play();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(video.calls.last, 'pause');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      // No automatic resume.
      expect(video.value.phase, VideoPhase.paused);

      await video.play();
      set(() => visible = false);
      await tester.pump();
      expect(video.calls.last, 'pause');

      await video.play();
      await tester.pumpWidget(app(const SizedBox()));
      expect(video.calls.last, 'pause');
    });

    testWidgets('pauses in an inactive IndexedStack tab', (tester) async {
      final video = FakeVideo();
      Widget tabs(int index) => app(
        Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              PaymentVideoPlayer(controller: video, title: 'Demo'),
              const Text('Other tab'),
            ],
          ),
        ),
      );
      await tester.pumpWidget(tabs(0));
      await tester.pump();
      await video.play();
      await tester.pumpWidget(tabs(1));
      expect(video.calls.last, 'pause');
    });

    testWidgets('error offers retry that reloads', (tester) async {
      final video = FakeVideo()
        ..value = const VideoPlaybackValue(phase: VideoPhase.error);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PaymentVideoPlayer(controller: video, title: 'Demo'),
          ),
        ),
      );
      expect(find.text('Video can’t play'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(video.calls, ['retry', 'initialize']);
      expect(video.value.phase, VideoPhase.ready);
    });
  });

  group('Promotions', () {
    const sponsored = PromoContent(
      id: 'p1',
      kind: PromoKind.sponsored,
      advertiser: 'Bank Contoh',
      title: 'Cashback 10%',
      ctaLabel: 'See offer',
    );

    testWidgets('always labeled; CTA and dismiss go to the host', (
      tester,
    ) async {
      final events = <String>[];
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PromoCard(
              content: sponsored,
              onAction: () => events.add('cta'),
              onDismiss: () => events.add('dismiss'),
            ),
          ),
        ),
      );
      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Bank Contoh'), findsOneWidget);
      await tester.tap(find.text('See offer'));
      await tester.tap(find.byTooltip('Dismiss: Cashback 10%'));
      expect(events, ['cta', 'dismiss']);
    });

    testWidgets('banner CTA keeps its intrinsic width beside the title', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // The gallery's id copy. The test font draws every glyph 1 em wide, so
      // a short label keeps the check about layout, not glyph widths.
      const title = 'Ajak teman, sama-sama dapat Rp10.000';
      await tester.pumpWidget(
        app(
          Scaffold(
            body: PromoCard(
              content: const PromoContent(
                id: 'p2',
                kind: PromoKind.promotion,
                title: title,
                ctaLabel: 'Ajak',
              ),
              layout: PromoLayout.banner,
              onAction: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      final card = tester.getSize(find.byType(PromoCard)).width;
      expect(tester.getSize(find.text(title)).width, greaterThan(0.6 * card));
    });

    testWidgets('empty and failed slots collapse by default', (tester) async {
      for (final state in [PromoSlotState.empty, PromoSlotState.error]) {
        await tester.pumpWidget(
          app(
            Scaffold(
              body: PromoSlot(state: state, onAction: (_) {}),
            ),
          ),
        );
        expect(find.byType(StateMessage), findsNothing);
      }
    });
  });

  group('Transactions', () {
    final now = DateTime(2026, 10, 30, 12);
    final records = [
      TransactionRecord(
        id: '1',
        title: 'Token listrik',
        merchant: 'PLN Contoh',
        amount: const Money.idr(101500),
        createdAt: now,
        status: null,
      ),
      TransactionRecord(
        id: '2',
        title: 'Pulsa',
        amount: const Money.idr(51000),
        createdAt: now,
        status: PaymentStatus.succeeded,
        refund: const RefundInfo(status: RefundStatus.partial),
      ),
      TransactionRecord(
        id: '3',
        title: 'Air',
        amount: const Money.idr(87300),
        createdAt: now,
        status: PaymentStatus.failed,
      ),
    ];

    testWidgets('failed amounts are struck through, refunded ones are not', (
      tester,
    ) async {
      TextDecoration? decorationOf(TransactionRecord record, String amount) {
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byWidgetPredicate(
              (w) => w is TransactionListItem && w.record.id == record.id,
            ),
            matching: find.text(amount),
          ),
        );
        return text.style?.decoration;
      }

      await tester.pumpWidget(
        app(
          Scaffold(
            body: ListView(
              children: [
                for (final r in records) TransactionListItem(record: r),
              ],
            ),
          ),
        ),
      );
      // A refund is separate from the original success: its amount stands.
      expect(
        decorationOf(records[1], 'Rp51,000'),
        isNot(TextDecoration.lineThrough),
      );
      expect(decorationOf(records[2], 'Rp87,300'), TextDecoration.lineThrough);
    });

    test('unknown outcome counts as in progress, never as failed', () {
      List<String> ids(TransactionFilter f) => [
        for (final r in TransactionRecord.where(records, filter: f)) r.id,
      ];
      expect(ids(TransactionFilter.inProgress), ['1']);
      expect(ids(TransactionFilter.unsuccessful), ['3']);
      expect(ids(TransactionFilter.refunds), ['2']);
      expect(TransactionRecord.where(records, query: 'pln').map((r) => r.id), [
        '1',
      ]);
    });

    testWidgets('no matches offers a reset; no data does not', (tester) async {
      String? query = 'zzz';
      TransactionFilter? filter;
      Widget history(bool narrowed) => app(
        Scaffold(
          body: SingleChildScrollView(
            child: TransactionHistory(
              records: const [],
              query: narrowed ? 'zzz' : '',
              filter: TransactionFilter.all,
              onQueryChanged: (q) => query = q,
              onFilterChanged: (f) => filter = f,
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(history(true));
      expect(find.text('No matches'), findsOneWidget);
      await tester.tap(find.text('Reset filters'));
      expect(query, '');
      expect(filter, TransactionFilter.all);

      await tester.pumpWidget(history(false));
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(find.text('Reset filters'), findsNothing);
    });
  });

  for (final locale in const [Locale('en'), Locale('id')]) {
    testWidgets(
      'promo and KYC fit 320 dp at 200% text (${locale.languageCode})',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const promo = PromoContent(
          id: 'p1',
          kind: PromoKind.sponsored,
          advertiser: 'Bank Contoh Nusantara',
          title: 'Cashback 10% for your first top-up',
          message: 'Valid for transfers from Bank Contoh.',
          terms: 'Until 31 Dec. Min. purchase Rp50.000',
          ctaLabel: 'See offer',
        );
        const requirement = DocumentRequirement(
          key: 'ktp',
          label: 'Identity card (KTP)',
          acceptedTypes: {'image/jpeg', 'image/png'},
          acceptedTypesLabel: 'JPG or PNG',
          maxBytes: 5 * 1024 * 1024,
        );
        const file = DocumentFile(
          name: 'ktp_demo_retake_final_v2.png',
          mimeType: 'image/png',
          sizeBytes: 2400000,
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('id')],
            localizationsDelegates: const [
              PaymentLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final layout in PromoLayout.values)
                      PromoCard(
                        content: promo,
                        layout: layout,
                        onAction: () {},
                        onDismiss: () {},
                        onAbout: () {},
                      ),
                    DocumentUploadTile(
                      requirement: requirement,
                      state: const DocumentSlotState.uploaded(
                        file,
                        requestId: 'r1',
                      ),
                      onPick: () {},
                    ),
                    VerificationReview(
                      fields: const [
                        IdentityFieldSpec(key: 'name', label: 'Full name'),
                      ],
                      values: const {'name': 'Siti Rahmawati'},
                      documents: const [
                        (
                          requirement,
                          DocumentSlotState.uploaded(file, requestId: 'r1'),
                        ),
                      ],
                      onSubmit: () async {},
                      onEditDetails: () {},
                      onEditDocuments: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('MiddleEllipsisText keeps the extension and the full label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              child: MiddleEllipsisText('ktp_demo_retake_final_v2.png'),
            ),
          ),
        ),
      ),
    );
    final shown = tester.widget<Text>(find.byType(Text)).data!;
    expect(shown, contains('…'));
    expect(shown, endsWith('.png'));
    expect(
      find.bySemanticsLabel('ktp_demo_retake_final_v2.png'),
      findsOneWidget,
    );
    handle.dispose();
  });
  testWidgets('state message action hugs its label inside the column', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        StateMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load transactions',
          message: 'Check your connection and try again.',
          actionLabel: 'Retry',
          onAction: () {},
        ),
        1,
      ),
    );
    final button = tester.getSize(find.byType(PaymentButton)).width;
    final column = tester.getSize(find.byType(Column).first).width;
    expect(button, lessThan(column));
    expect(button, greaterThanOrEqualTo(112));
  });
  testWidgets('privacy mask lock keeps its padding in a short strip', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          height: 48,
          width: 300,
          child: PrivacyMask(obscured: true, child: Text('8808 1234')),
        ),
        1,
      ),
    );
    expect(tester.takeException(), isNull);
    final mask = tester.getRect(find.byType(PrivacyMask));
    final lock = tester.getRect(find.byIcon(Icons.lock_outline));
    expect(lock.top - mask.top, greaterThanOrEqualTo(16));
    expect(mask.bottom - lock.bottom, greaterThanOrEqualTo(16));
    // Smaller, but still a legible lock rather than a dot.
    expect(lock.height, 16);
    await tester.pumpWidget(
      host(
        const SizedBox(
          height: 120,
          width: 300,
          child: PrivacyMask(obscured: true, child: Text('8808 1234')),
        ),
        1,
      ),
    );
    expect(tester.getSize(find.byIcon(Icons.lock_outline)).height, 48);
  });
}
