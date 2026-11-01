import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import 'package:flutter_ui_payment_example/main.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// English, one-component-per-shot captures for the docs component catalog:
/// the controls in light and dark, plus the interaction components that the
/// `kit_` set only shows in Indonesian. Files are prefixed `catalog_` so
/// earlier evidence is kept. Run with `flutter drive` and
/// test_driver/integration_driver.dart.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture catalog entries', (tester) async {
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    final app = await launch(tester);
    final platform = Platform.isIOS ? 'ios' : 'android';

    Future<void> shot(String name) async {
      await settle(tester);
      await tester.pump(const Duration(milliseconds: 400));
      debugPrint('Capture: $name');
      await binding.takeScreenshot('${platform}_catalog_$name');
    }

    Future<void> open(String label) async {
      await tester.tap(find.byTooltip('Open navigation'));
      await settle(tester);
      final item = find.descendant(
        of: find.byType(Drawer),
        matching: find.text(label),
      );
      await tester.scrollUntilVisible(
        item,
        180,
        scrollable: find
            .descendant(
              of: find.byType(Drawer),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(item);
      await tester.tap(item);
      await settle(tester);
    }

    // Move the outer gallery directly: specimen bodies own their own scrolls.
    Future<void> top(String entry) async {
      final gallery = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      final position = tester.state<ScrollableState>(gallery).position;
      position.jumpTo(position.minScrollExtent);
      await tester.pump();
      final caption = find.text(entry);
      for (
        var attempt = 0;
        caption.evaluate().isEmpty && attempt < 100;
        attempt++
      ) {
        position.jumpTo(
          (position.pixels + 200).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
        await tester.pump();
      }
      expect(caption, findsOneWidget);
      await Scrollable.ensureVisible(tester.element(caption));
      final specimen = find
          .ancestor(of: caption, matching: find.byType(Column))
          .first;
      for (final element
          in find
              .descendant(of: specimen, matching: find.byType(Scrollable))
              .evaluate()) {
        final state = tester.state<ScrollableState>(
          find.byWidget(element.widget),
        );
        state.position.jumpTo(state.position.minScrollExtent);
      }
      await settle(tester);
    }

    void clearSnackBars() => tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();

    Future<void> hoverShot(String key, String message, String name) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(Key(key))));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 700)),
      );
      await tester.pump();
      expect(find.text(message), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      final bubble = find.text(message);
      final opacity = tester
          .widget<Opacity>(
            find.ancestor(of: bubble, matching: find.byType(Opacity)).first,
          )
          .opacity;
      debugPrint(
        'Tooltip proof $name rect=${tester.getRect(bubble)} opacity=$opacity',
      );
      expect(opacity, 1);
      await binding.takeScreenshot('${platform}_catalog_$name');
      await mouse.removePointer();
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
    }

    app.updateSettings(const DemoSettings(locale: Locale('en')));
    app.selectTab(2);
    await settle(tester);
    // Selective session: --dart-define=CAPTURE_ONLY=<entries> with entries
    // `slug` (every look in CAPTURE_LOOKS) or `slug@look` (that look only),
    // and CAPTURE_LOOKS from light,dark,200,id,id_200 (default: all). Files
    // are `<slug>_variants` plus '', _dark, _200, _id or _id_200. Without
    // CAPTURE_ONLY the modes below run as before.
    const only = String.fromEnvironment('CAPTURE_ONLY');
    if (only.isNotEmpty) {
      const looksDefine = String.fromEnvironment('CAPTURE_LOOKS');
      final entries = only.split(',').map((e) => e.trim()).toSet();
      final looks = looksDefine.isEmpty
          ? const ['light', 'dark', '200', 'id', 'id_200']
          : looksDefine.split(',').map((e) => e.trim()).toList();
      const states = {'menu_sheet', 'tooltip_tap'};
      bool want(String slug, String look) =>
          looks.contains(look) &&
          (entries.contains(slug) || entries.contains('$slug@$look'));
      // Drawer pages by their English and Indonesian labels.
      const pages = {
        'Kit components': 'Komponen kit',
        'Content': 'Konten',
        'Interaction': 'Interaksi',
        'Controls': 'Kontrol',
        'Forms': 'Formulir',
        'Feedback': 'Umpan balik',
        'Layout': 'Tata letak',
        'Charts': 'Grafik',
      };
      // slug → (page, caption, steps before the shot, cleanup after it).
      final specimens =
          <
            String,
            (
              String,
              String,
              Future<void> Function(bool id)?,
              Future<void> Function()?,
            )
          >{
            'text_field': ('Controls', 'PaymentTextField', null, null),
            'currency_field': ('Controls', 'PaymentCurrencyField', null, null),
            'tabs': ('Controls', 'PaymentTabs', null, null),
            'copy_button': (
              'Controls',
              'PaymentCopyButton',
              (_) async {
                await tapVisible(tester, find.byKey(const Key('copy-failed')));
                await top('PaymentCopyButton · variants');
              },
              null,
            ),
            'select': ('Forms', 'PaymentSelect', null, null),
            'date_field': ('Forms', 'PaymentDateField', null, null),
            'chip': ('Forms', 'PaymentChip', null, null),
            'search_field': (
              'Forms',
              'PaymentSearchField',
              (_) async {
                final field = find.descendant(
                  of: find.byKey(const Key('search-province')),
                  matching: find.byType(EditableText),
                );
                await tester.tap(field);
                await tester.enterText(field, 'jawa');
                await top('PaymentSearchField · variants');
              },
              () async {
                FocusManager.instance.primaryFocus?.unfocus();
                await settle(tester);
              },
            ),
            'list': ('Interaction', 'PaymentList', null, null),
            'accordion': ('Interaction', 'PaymentAccordion', null, null),
            // On a phone the menu opens as an action sheet (D55): `menu`
            // shows the specimen at rest, `menu_sheet` the open sheet.
            'menu': ('Interaction', 'PaymentMenu', null, null),
            'menu_sheet': (
              'Interaction',
              'PaymentMenu',
              (_) async {
                await tester.tap(
                  find.descendant(
                    of: find.byKey(const Key('menu-specimen')),
                    matching: find.byType(IconButton),
                  ),
                );
                await settle(tester);
              },
              () async {
                await tester.tapAt(const Offset(10, 10));
                await settle(tester);
              },
            ),
            'banner': ('Feedback', 'PaymentBanner', null, null),
            // A tap opens the hint (D49); a second tap closes it.
            'tooltip_tap': (
              'Feedback',
              'PaymentTooltip',
              (_) async {
                await tester.tap(find.byKey(const Key('tooltip-description')));
                await tester.pump();
              },
              () async {
                await tester.tap(find.byKey(const Key('tooltip-description')));
                await settle(tester);
              },
            ),
            'toast': (
              'Feedback',
              'showPaymentToast',
              (_) => tapVisible(tester, find.byKey(const Key('toast-pending'))),
              () async {
                clearSnackBars();
                await settle(tester);
              },
            ),
            'button_group': ('Content', 'PaymentButtonGroup', null, null),
            'dialog': (
              'Kit components',
              'showPaymentConfirmDialog',
              (_) => tapVisible(
                tester,
                find.byKey(const Key('phase6-dialog-open')),
              ),
              // The scrim resolves false, so no localized Cancel label.
              () async {
                await tester.tapAt(const Offset(10, 10));
                await settle(tester);
              },
            ),
            'sheets': ('Kit components', 'PaymentSheet', null, null),
            'privacy_mask': ('Kit components', 'PrivacyMask', null, null),
            'action_bar': ('Kit components', 'PaymentActionBar', null, null),
            'loading_skeleton': (
              'Kit components',
              'LoadingSkeleton',
              null,
              null,
            ),
            'countdown': ('Kit components', 'CountdownText', null, null),
            'status_header': ('Kit components', 'StatusHeader', null, null),
            'state_message': (
              'Kit components',
              'StateMessage · PaymentEmptyMessage',
              null,
              null,
            ),
            // UI review P3.
            'info_row': ('Kit components', 'InfoRow', null, null),
            'section': ('Kit components', 'PaymentSection', null, null),
            'navigation': ('Kit components', 'AdaptiveNavShell', null, null),
            'chart_module': ('Kit components', 'ChartModule', null, null),
            'property_list': ('Content', 'PaymentPropertyList', null, null),
            'table': ('Content', 'PaymentTable', null, null),
            'data_table': ('Content', 'PaymentDataTable', null, null),
            'task_list': ('Content', 'PaymentTaskList', null, null),
            'code': ('Layout', 'PaymentCode', null, null),
            'image': ('Layout', 'PaymentImage', null, null),
            'line_chart': ('Charts', 'PaymentLineChart', null, null),
            'bar_chart': ('Charts', 'PaymentBarChart', null, null),
            'meter_chart': ('Charts', 'PaymentMeterChart', null, null),
            'sparkline': ('Charts', 'PaymentSparkline', null, null),
          };
      // State captures named `<slug><suffix>` rather than `_variants`.
      final states = <String, (String, Future<void> Function())>{
        // D58: the latest value is labelled with no pointer at all.
        'chart_line_rest': ('Charts', () => top('PaymentLineChart')),
        'chart_bar_selected': (
          'Charts',
          () async {
            await top('PaymentBarChart');
            final bar = tester.getRect(
              find.byType(PaymentBarChart).hitTestable().first,
            );
            await tester.tapAt(
              Offset(bar.left + bar.width * .45, bar.center.dy),
            );
            await settle(tester);
          },
        ),
      };
      for (final (look, settings) in [
        ('light', const DemoSettings(locale: Locale('en'))),
        (
          'dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('200', const DemoSettings(locale: Locale('en'), textScale: 2)),
        ('id', const DemoSettings(locale: Locale('id'))),
        ('id_200', const DemoSettings(locale: Locale('id'), textScale: 2)),
      ]) {
        final id = look.startsWith('id');
        final suffix = look == 'light' ? '' : '_$look';
        final wanted = [
          ...specimens.keys.where((slug) => want(slug, look)),
          ...states.keys.where((slug) => want(slug, look)),
          if (want('tooltip', look)) 'tooltip',
        ];
        if (wanted.isEmpty) continue;
        app.updateSettings(settings);
        await settle(tester);
        String? current;
        Future<void> openPage(String page) async {
          if (current == page) return;
          await tester.tap(
            find.byTooltip(id ? 'Buka navigasi' : 'Open navigation'),
          );
          await settle(tester);
          final item = find.descendant(
            of: find.byType(Drawer),
            matching: find.text(id ? pages[page]! : page),
          );
          await tester.scrollUntilVisible(
            item,
            180,
            scrollable: find
                .descendant(
                  of: find.byType(Drawer),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          // Centre the item: one at the drawer's bottom edge misses the tap.
          await Scrollable.ensureVisible(tester.element(item), alignment: .5);
          await settle(tester);
          await tester.tap(item);
          await settle(tester);
          current = page;
        }

        for (final slug in wanted) {
          if (slug == 'tooltip') {
            await openPage('Feedback');
            await top('PaymentTooltip · variants');
            await hoverShot(
              'tooltip-label',
              id
                  ? 'Waktu pembayaran: 29 Okt 2026, 14.05'
                  : 'Payment time: 29 Oct 2026, 14:05',
              'tooltip_variants$suffix',
            );
            continue;
          }
          if (states[slug] case (final page, final steps)?) {
            await openPage(page);
            await steps();
            await shot('$slug$suffix');
            continue;
          }
          final (page, entry, before, after) = specimens[slug]!;
          await openPage(page);
          await top('$entry · variants');
          await before?.call(id);
          // State captures are named `<slug><look>`, not `_variants`.
          await shot(
            states.contains(slug) ? '$slug$suffix' : '${slug}_variants$suffix',
          );
          await after?.call();
        }
      }
      // The kit and flow captures P2 refreshes, in this one session: the
      // Indonesian destructive confirm over the pending-payment sheet, and
      // the fees screen with its ⓘ.
      if (entries.contains('kit_sheet_confirm')) {
        app.updateSettings(const DemoSettings());
        app.selectTab(2);
        await settle(tester);
        await tester.tap(find.byTooltip('Buka navigasi'));
        await settle(tester);
        final item = find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Sheet & drawer'),
        );
        await tester.scrollUntilVisible(
          item,
          120,
          scrollable: find.descendant(
            of: find.byType(Drawer),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.ensureVisible(item);
        await settle(tester);
        await tester.tap(item);
        await settle(tester);
        await tester.tap(find.text('Tutup vs. batalkan pembayaran'));
        await settle(tester);
        await tester.tap(find.text('Minta pembatalan'));
        await settle(tester);
        await tester.pump(const Duration(milliseconds: 400));
        await binding.takeScreenshot('${platform}_kit_sheet_confirm');
        await tester.tap(find.text('Tetap bayar'));
        await settle(tester);
        await tester.tap(find.byTooltip('Tutup panel'));
        await settle(tester);
      }
      if (entries.contains('fees_light')) {
        app.updateSettings(const DemoSettings());
        await settle(tester);
        await runScenario(tester, app, 'A04');
        await settle(tester);
        await tester.pump(const Duration(milliseconds: 400));
        await binding.takeScreenshot('${platform}_fees_light');
      }
      return;
    }
    if (const bool.fromEnvironment('CAPTURE_PHASE6_ONLY')) {
      const onlyEntry = String.fromEnvironment('CAPTURE_PHASE6_ENTRY');
      const onlyLook = String.fromEnvironment('CAPTURE_PHASE6_LOOK');
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
      ]) {
        if (onlyLook.isNotEmpty &&
            (onlyLook == '_light' ? look.isNotEmpty : onlyLook != look)) {
          continue;
        }
        app.updateSettings(settings);
        await settle(tester);
        await open('Kit components');
        if ((onlyEntry.isEmpty || onlyEntry.split(',').contains('dialog'))) {
          await top('showPaymentConfirmDialog · variants');
          await tapVisible(tester, find.byKey(const Key('phase6-dialog-open')));
          await shot('dialog_variants$look');
          await tapVisible(tester, find.text('Cancel'));
          await settle(tester);
        }
        if ((onlyEntry.isEmpty || onlyEntry.split(',').contains('sheets'))) {
          await top('PaymentSheet · variants');
          await shot('sheets_variants$look');
        }
        if ((onlyEntry.isEmpty || onlyEntry.split(',').contains('section')) &&
            look != '_200') {
          await top('PaymentSection · variants');
          await shot('section_variants$look');
        }
        if ((onlyEntry.isEmpty ||
                onlyEntry.split(',').contains('navigation')) &&
            look != '_200') {
          await top('AdaptiveNavShell · variants');
          await shot('navigation_variants$look');
        }
        if ((onlyEntry.isEmpty ||
                onlyEntry.split(',').contains('step_indicator')) &&
            look != '_200') {
          await top('PaymentStepIndicator · variants');
          await shot('step_indicator_variants$look');
        }
        if ((onlyEntry.isEmpty || onlyEntry.split(',').contains('info_row'))) {
          await top('InfoRow · variants');
          await shot('info_row_variants$look');
        }
        if ((onlyEntry.isEmpty || onlyEntry.split(',').contains('countdown')) &&
            look != '_200') {
          await top('CountdownText · variants');
          await shot('countdown_variants$look');
        }
        if ((onlyEntry.isEmpty ||
                onlyEntry.split(',').contains('privacy_mask')) &&
            look != '_200') {
          await top('PrivacyMask · variants');
          await shot('privacy_mask_variants$look');
        }
        if ((onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('action_bar'))) {
          await top('PaymentActionBar · variants');
          await shot('action_bar_variants$look');
        }
        if ((onlyEntry.isEmpty || onlyEntry.split(',').contains('media')) &&
            look != '_200') {
          await top('PaymentVideoPlayer · variants');
          await shot('media_variants$look');
        }
        if ((onlyEntry.isEmpty ||
                onlyEntry.split(',').contains('status_header')) &&
            look != '_200') {
          await top('StatusHeader · variants');
          await shot('status_header_variants$look');
        }
        if ((onlyEntry.isEmpty ||
                onlyEntry.split(',').contains('loading_skeleton')) &&
            look != '_200') {
          await top('LoadingSkeleton · variants');
          await shot('loading_skeleton_variants$look');
        }
        if ((onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('state_message'))) {
          await top('StateMessage · PaymentEmptyMessage · variants');
          await shot('state_message_variants$look');
        }
        if ((onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('chart_module'))) {
          await top('ChartModule · variants');
          await shot('chart_module_variants$look');
        }
      }
      return;
    }
    if (const bool.fromEnvironment('CAPTURE_ACTIONS_ONLY')) {
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
      ]) {
        app.updateSettings(settings);
        await settle(tester);
        await open('Controls');
        await top('PaymentIconButton · variants');
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        Focus.of(
          tester.element(
            find.descendant(
              of: find.byKey(const Key('icon-button-focus')),
              matching: find.byType(Icon),
            ),
          ),
        ).requestFocus();
        await shot('icon_button_variants$look');
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
        FocusManager.instance.primaryFocus?.unfocus();
        await top('PaymentCopyButton · variants');
        await tapVisible(tester, find.byKey(const Key('copy-failed')));
        await top('PaymentCopyButton · variants');
        await shot('copy_button_variants$look');
      }
      return;
    }
    if (const bool.fromEnvironment('CAPTURE_TOOLTIP_ONLY')) {
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
      ]) {
        app.updateSettings(settings);
        await settle(tester);
        await open('Feedback');
        await top('PaymentTooltip · variants');
        await hoverShot(
          'tooltip-label',
          'Payment time: 29 Oct 2026, 14:05',
          'tooltip_variants$look',
        );
      }
      app.updateSettings(const DemoSettings(locale: Locale('en')));
      await settle(tester);
      await open('Feedback');
      await top('PaymentTooltip · variants');
      await hoverShot(
        'tooltip-flip',
        'Flips to the start when there is no room',
        'tooltip_flip',
      );
      return;
    }
    if (const bool.fromEnvironment('CAPTURE_PHASE4CD_ONLY')) {
      const onlyEntry = String.fromEnvironment('CAPTURE_PHASE4CD_ENTRY');
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
      ]) {
        const onlyLook = String.fromEnvironment('CAPTURE_PHASE4CD_LOOK');
        if (onlyLook.isNotEmpty &&
            (onlyLook == '_light' ? look.isNotEmpty : onlyLook != look)) {
          continue;
        }
        app.updateSettings(settings);
        await settle(tester);
        await open('Content');
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('property_list')) {
          await top('PaymentPropertyList · variants');
          await shot('property_list_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty || onlyEntry.split(',').contains('table')) {
          await top('PaymentTable · variants');
          await shot('table_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty || onlyEntry.split(',').contains('data_table')) {
          await top('PaymentDataTable · variants');
          await shot('data_table_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty || onlyEntry.split(',').contains('task_list')) {
          await top('PaymentTaskList · variants');
          await shot('task_list_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('button_group')) {
          await top('PaymentButtonGroup · variants');
          await shot('button_group_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        await open('Views & pages');
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('context_view')) {
          await top('PaymentContextView · variants');
          await shot('context_view_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('full_page_view')) {
          await top('PaymentFullPageView · variants');
          await shot('full_page_view_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty || onlyEntry.split(',').contains('focus_view')) {
          await top('PaymentFocusView · variants');
          await shot('focus_view_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('settings_view')) {
          await top('PaymentSettingsView · variants');
          await shot('settings_view_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('sign_in_view')) {
          await top('PaymentSignInView · variants');
          await shot('sign_in_view_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('onboarding_view')) {
          await top('PaymentOnboardingView · variants');
          await shot('onboarding_view_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty || onlyEntry.split(',').contains('detail_page')) {
          await top('PaymentDetailPage · variants');
          await shot('detail_page_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('overview_page')) {
          await top('PaymentOverviewPage · variants');
          await shot('overview_page_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('detail_page_property_list')) {
          await top('PaymentDetailPagePropertyList · variants');
          await shot('detail_page_property_list_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        if (onlyEntry.isEmpty ||
            onlyEntry.split(',').contains('detail_page_table')) {
          await top('PaymentDetailPageTable · variants');
          await shot('detail_page_table_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        await open('Layout');
        if (onlyEntry.isEmpty || onlyEntry.split(',').contains('code')) {
          await top('PaymentCode · variants');
          await shot('code_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
        await open('Controls');
        if (onlyEntry.isEmpty || onlyEntry.split(',').contains('tabs')) {
          await top('PaymentTabs · variants');
          await shot('tabs_variants$look');
          FocusManager.instance.primaryFocus?.unfocus();
        }
      }
      return;
    }
    if (const bool.fromEnvironment('CAPTURE_PHASE4_ONLY')) {
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
      ]) {
        const onlyLook = String.fromEnvironment('CAPTURE_PHASE4_LOOK');
        if (onlyLook.isNotEmpty && onlyLook != look) continue;
        app.updateSettings(settings);
        await settle(tester);
        await open('Layout');
        for (final (entry, name) in [
          if (look != '_200') ('PaymentBox', 'box'),
          ('PaymentInline', 'inline'),
          if (look != '_200') ('PaymentIcon', 'icon'),
          if (look != '_200') ('PaymentImage', 'image'),
          ('PaymentCode', 'code'),
          if (look != '_200') ('PaymentDivider', 'divider'),
        ]) {
          await top('$entry · variants');
          await shot('${name}_variants$look');
        }
        await open('Forms');
        for (final (entry, name) in [
          ('PaymentTextArea', 'text_area'),
          ('PaymentSelect', 'select'),
          ('PaymentDateField', 'date_field'),
          ('PaymentFormFieldGroup', 'form_field_group'),
          ('PaymentDateRangePicker', 'date_range_picker'),
          ('PaymentChip', 'chip'),
        ]) {
          await top('$entry · variants');
          await shot('${name}_variants$look');
        }
        await top('PaymentSearchField · variants');
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('search-province')),
            matching: find.byType(EditableText),
          ),
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('search-province')),
            matching: find.byType(EditableText),
          ),
          'jawa',
        );
        await top('PaymentSearchField · variants');
        await shot('search_field_variants$look');
        FocusManager.instance.primaryFocus?.unfocus();
        await settle(tester);
        await open('Controls');
        for (final (entry, name) in [
          ('PaymentCurrencyField', 'currency_field'),
          ('PaymentTextField', 'text_field'),
        ]) {
          await top('$entry · variants');
          await shot('${name}_variants$look');
        }
        await open('Interaction');
        await top('PaymentAccordion · variants');
        await shot('accordion_variants$look');
        await top('PaymentList · variants');
        await shot('list_variants$look');
        await open('Charts');
        await top('PaymentMeterChart · variants');
        await shot('meter_chart_variants$look');
      }
      return;
    }
    if (!const bool.fromEnvironment('CAPTURE_TAIL_ONLY')) {
      const buttons = 'PaymentButton · variants';
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
      ]) {
        app.updateSettings(settings);
        app.selectTab(2);
        await settle(tester);
        await open('Controls');
        await top(buttons);
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        Focus.of(
          tester.element(
            find.descendant(
              of: find.byKey(const ValueKey('button-specimen-focus')),
              matching: find.text('Edit'),
            ),
          ),
        ).requestFocus();
        await shot('button_variants$look');
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
        FocusManager.instance.primaryFocus?.unfocus();
        for (final (entry, name) in [
          ('PaymentTabs', 'tabs'),
          ('PaymentCheckbox', 'checkbox'),
          ('PaymentRadio', 'radio'),
          ('PaymentSwitch', 'switch'),
          ('PaymentCurrencyField', 'currency_field'),
          ('PaymentTextField', 'text_field'),
          ('PaymentLink', 'link'),
          if (look != '_200') ('PaymentIconButton', 'icon_button'),
          if (look != '_200') ('PaymentCopyButton', 'copy_button'),
        ]) {
          await top('$entry · variants');
          if (name == 'copy_button') {
            await tapVisible(tester, find.byKey(const Key('copy-failed')));
            await top('$entry · variants');
          }
          await shot('${name}_variants$look');
        }
        await open('Foundation');
        await top('AmountText · variants');
        await shot('amount_text_variants$look');
        await open('Feedback');
        await top('PaymentBadge · variants');
        await shot('badge_variants$look');
        await top('PaymentBanner · variants');
        await shot('banner_variants$look');
        if (look != '_200') {
          await top('PaymentSpinner · variants');
          await shot('spinner_variants$look');
        }
        await top('showPaymentToast · variants');
        await tapVisible(tester, find.widgetWithText(PaymentButton, 'Pending'));
        await shot('toast_variants$look');
        clearSnackBars();
        await settle(tester);
        await top('PaymentTooltip · variants');
        await hoverShot(
          'tooltip-label',
          'Payment time: 29 Oct 2026, 14:05',
          'tooltip_variants$look',
        );
        await open('Interaction');
        await top('PaymentMenu · variants');
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('menu-specimen')),
            matching: find.byType(IconButton),
          ),
        );
        await settle(tester);
        await shot('menu_variants$look');
        await tester.tapAt(const Offset(10, 10));
        await settle(tester);
        await top('PaymentAccordion · variants');
        await shot('accordion_variants$look');
        await top('PaymentList · variants');
        await shot('list_variants$look');
        await open('Charts');
        for (final (entry, name) in [
          ('PaymentLineChart', 'line_chart'),
          ('PaymentBarChart', 'bar_chart'),
          ('PaymentMeterChart', 'meter_chart'),
          if (look != '_200') ('PaymentSparkline', 'sparkline'),
        ]) {
          await top('$entry · variants');
          await shot('${name}_variants$look');
        }
      }

      for (final dark in [false, true]) {
        final suffix = dark ? '_dark' : '';
        app.updateSettings(
          DemoSettings(
            locale: const Locale('en'),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          ),
        );
        await settle(tester);
        await open('Charts');
        for (final (entry, name) in [
          ('PaymentLineChart', 'chart_line'),
          ('PaymentBarChart', 'chart_bar'),
          ('PaymentMeterChart', 'chart_meter'),
          ('PaymentSparkline · beside a KPI', 'chart_sparkline'),
          ('In context: spending above history', 'chart_in_context'),
        ]) {
          await top(entry);
          await shot('$name$suffix');
        }
        await open('Verification (KYC)');
        await top('showCaptureSourceSheet');
        await tapVisible(tester, find.text('Add a photo'));
        await shot('capture_source_sheet$suffix');
        await tester.tap(find.byTooltip('Close panel'));
        await settle(tester);
        clearSnackBars();
        await top('KycCaptureGuide');
        await shot('capture_ktp$suffix');
        await tapVisible(tester, find.text('selfie'));
        await top('KycCaptureGuide');
        await shot('capture_selfie$suffix');
      }
      app.updateSettings(const DemoSettings(locale: Locale('en')));
      await settle(tester);
      await open('Charts');
      await top('ChartModule · states');
      await shot('chart_states');
      for (final state in ['error', 'empty']) {
        await tapVisible(tester, find.text(state));
        await top('ChartModule · states');
        await shot('chart_states_$state');
      }
      // D58: the latest value is labelled at rest; a tap selects a bar.
      await top('PaymentLineChart');
      await shot('chart_line_rest');
      await top('PaymentBarChart');
      final bar = tester.getRect(
        find.byType(PaymentBarChart).hitTestable().first,
      );
      await tester.tapAt(Offset(bar.left + bar.width * .45, bar.center.dy));
      await settle(tester);
      await shot('chart_bar_selected');
      await open('Verification (KYC)');
      await top('KycCaptureGuide');
      for (final state in ['review', 'rejected', 'permission']) {
        await tapVisible(tester, find.text(state));
        await top('KycCaptureGuide');
        await shot('capture_$state');
      }
      app.updateSettings(
        const DemoSettings(locale: Locale('en'), textScale: 2),
      );
      await settle(tester);
      await open('Charts');
      await top('In context: spending above history');
      await shot('chart_in_context_200');
      await open('Verification (KYC)');
      await top('KycCaptureGuide');
      await tapVisible(tester, find.text('selfie'));
      await top('KycCaptureGuide');
      await Scrollable.ensureVisible(
        tester.element(
          find.text(
            'Keep your face in the oval and hold the card below your chin.',
          ),
        ),
        alignment: 0,
      );
      await shot('capture_selfie_200');
    }
    app.updateSettings(const DemoSettings(locale: Locale('en')));
    await settle(tester);
    await open('Feedback');
    await top('showPaymentToast · variants');
    await tapVisible(tester, find.widgetWithText(PaymentButton, 'Pending'));
    await tester.pump(const Duration(seconds: 2));
    await shot('toast_updated');
    clearSnackBars();
    await settle(tester);
    await top('PaymentTooltip · variants');
    await hoverShot(
      'tooltip-flip',
      'Flips to the start when there is no room',
      'tooltip_flip',
    );

    await open('Foundation');
    tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(0);
    await shot('foundation');

    await open('Interaction');
    await top('PaymentList · PaymentMenu · showPaymentConfirmDialog');
    if (const bool.fromEnvironment('CAPTURE_TAIL_ONLY')) {
      for (final (look, settings) in [
        ('', const DemoSettings(locale: Locale('en'))),
        (
          '_dark',
          const DemoSettings(locale: Locale('en'), themeMode: ThemeMode.dark),
        ),
        ('_200', const DemoSettings(locale: Locale('en'), textScale: 2)),
      ]) {
        app.updateSettings(settings);
        await settle(tester);
        await open('Feedback');
        await top('PaymentTooltip · variants');
        await hoverShot(
          'tooltip-label',
          'Payment time: 29 Oct 2026, 14:05',
          'tooltip_variants$look',
        );
      }
      app.updateSettings(const DemoSettings(locale: Locale('en')));
      await settle(tester);
      await open('Interaction');
      await top('PaymentList · PaymentMenu · showPaymentConfirmDialog');
    }
    await tester.tap(find.byTooltip('More actions').first);
    await settle(tester);
    await shot('menu_open');
    await tester.tapAt(const Offset(8, 8));
    await settle(tester);

    await open('Video');
    await top('PaymentVideoPlayer + video_player adapter');
    await tapVisible(tester, find.text('Loading'));
    await top('PaymentVideoPlayer + video_player adapter');
    await shot('video_loading');
  });
}
