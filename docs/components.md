# Components

Every public component of `flutter_ui_payment`, what it is for, what the host still owns, and where to see it. All of them are exported from `package:flutter_ui_payment/flutter_ui_payment.dart`, take their colors from `PaymentTheme`, their strings from `PaymentLocalizations` (English and Indonesian), and their motion from `PaymentMotion` (which goes to zero under reduced motion).

"Gallery" means the **Galeri** tab of the example app (`example/`), opened from the menu button on phones or the sidebar on wide windows.

## Inventory

| Module | Component | What it does | The host owns | Gallery section |
| --- | --- | --- | --- | --- |
| Foundation | `PaymentTheme`, `PaymentMotion`, `PaymentLocalizations`, `KitStrings` | Brand tokens, motion tokens, en/id strings and formatters | Brand values, locale | Fondasi |
| Foundation | `Money`, `MoneyFormat`, `AmountText` | Integer money, strict parsing, amounts that scale down instead of clipping | Currency, amounts | Fondasi |
| Foundation | `InfoRow`, `MiddleEllipsisText` | Label/value rows; values keep up to 60% of the row; long file names keep their extension (`ktp_demo_ret…ake.png`) | — | Fondasi, Verifikasi |
| Foundation | `PaymentButton`, `StatusBadge`, `NoticeBanner`, `PaymentSection` (`trailing:` header action), `StatusBand`, `PrivacyMask`, `CountdownText` | Primitives with idle/busy/disabled states; buttons are primary, secondary, quiet or destructive; `StatusBand` is hatched for an unknown outcome | Callbacks | Fondasi |
| Foundation | `PaymentSpinner`, `PaymentDivider` | Indeterminate wait (still hourglass under reduced motion); 1 px outline rule | — | Kontrol |
| Controls | `PaymentCheckbox`, `PaymentRadio`, `PaymentSwitch` | Label rows, one 48 dp target and one screen-reader node each; disabled with a reason | The value | Kontrol |
| Controls | `PaymentTabs`, `PaymentTooltip` | Text tabs on a hairline (also the history filters); long-press/hover hint in ink | Selected index and the content | Kontrol, Riwayat |
| Interaction | `ActionTile`, `ActionTileGroup` | Row with icon, subtitle, disabled reason, destructive tone | What the tap does | Interaksi |
| Interaction | `ActionMenu`, `ActionMenuEntry` | Overflow menu (keyboard arrows, Escape, focus return via `MenuAnchor`) | Entries and callbacks | Interaksi |
| Interaction | `showPaymentConfirmDialog` | Yes/no before an irreversible action; destructive puts focus on Cancel | The action itself | Interaksi, Sheet & drawer |
| Interaction | `showPaymentSnackBar` | Toned feedback with optional undo | What undo does | Interaksi |
| Interaction | `ExpandableSection` | Controlled or uncontrolled disclosure | Content | Interaksi |
| Interaction | `LoadingSkeleton`, `StateMessage` | Static loading placeholder; empty/error/no-match state with one action | Retry | Interaksi, Riwayat |
| Navigation | `PaymentNavItem`, `PaymentNavSection`, `NavSidebar` | Grouped navigation with selected, disabled-with-reason and badge | Selection, routing | Navigasi |
| Navigation | `AdaptiveNavShell` | Sidebar at ≥ breakpoint, modal drawer below it; Escape/Back/scrim close; focus returns to the menu button | Selected id, pages | The whole gallery |
| Sheets | `PaymentSheet`, `PaymentSheetHeader` | Header / scrolling body / fixed footer; safe area and keyboard inset | Content and actions | Sheet & drawer |
| Sheets | `showPaymentSheet`, `showPaymentSideSheet` | Bottom sheet and end-edge side panel | Whether it may be dismissed | Sheet & drawer, Riwayat |
| Media | `PaymentVideoController`, `VideoPlaybackValue`, `VideoPhase` | Contract between the widget and any media engine | The engine (plugin), the source, its lifetime | Video |
| Media | `PaymentVideoPlayer` | Play/pause, seek, mute, retry, loading/buffering/ended/error; no autoplay; pauses when hidden or backgrounded | — | Video |
| Promotions | `PromoContent`, `PromoKind`, `PromoCard`, `PromoLayout` | Labeled sponsored or own promotion with CTA, dismiss and "why this?" | Campaigns, what CTA/dismiss do, tracking (if any) | Promosi |
| Promotions | `PromoSlot`, `PromoSlotState` | Loading/ready/empty/error placement; empty and failed collapse by default | Loading the content | Promosi |
| Checkout | `AmountInput`, `PaymentSummary`, `PaymentMethodPicker`, `PaymentConfirmation`, `AuthorizationPrompt` | Unchanged v0.1 checkout | Quote, methods, auth | Checkout |
| Checkout | `PaymentActionBar` | Pinned total + main action; "Updating total…" while re-quoting | Enabling the action | Checkout, Demo checkout |
| Checkout | `MerchantHeader` | Payee name, category, order reference, verified badge | Verification flag, logo | Checkout |
| Checkout | `PaymentStepIndicator` | "Step 2 of 4: Checkout" bars | Current step | Checkout |
| Checkout | `BalanceCard`, `BalanceState` | Balance, insufficient warning with shortfall, limit usage | Whether balance covers the payment | Checkout |
| Checkout | `PromoCodeInput`, `PromoCodeStatus` | Code entry with checking/applied/rejected | Validation and the discounted quote | Checkout |
| Status | `PaymentInstructions`, `PaymentStatusView`, `RefundSection`, `PaymentAttempt` | Unchanged v0.1 status logic; hero simplified | Status, idempotency, refunds | Status & struk |
| History | `TransactionRecord`, `TransactionFilter` | Presentation record; local `where(query, filter)` helper | Records, server search | Riwayat |
| History | `TransactionHistory`, `TransactionListItem`, `TransactionDetail` | Search, filter chips, list, loading/error/empty/no-match, detail with separate refund | Query/filter state, actions | Riwayat |
| Receipt | `PaymentReceipt` | Unchanged v0.1 | Share and clipboard | Status & struk |
| Verification | `VerificationIntro`, `IdentityForm`, `DocumentUploadTile`, `VerificationReview`, `VerificationStatusView` | Unchanged v0.1 flow; review edit buttons moved into section headers | KYC decision | Verifikasi (KYC) |

Out of scope on purpose (shown disabled in the gallery navigation): saved cards, PIN entry, ledgers, ad SDKs, real campaigns.

## Interaction

```dart
PaymentSection(
  title: 'Account',
  trailing: ActionMenu(entries: [
    ActionMenuEntry(label: 'Copy account ID', icon: Icons.copy_rounded,
        onSelected: copyId),
    ActionMenuEntry(label: 'Sign out everywhere', icon: Icons.logout,
        destructive: true, onSelected: signOutEverywhere),
  ]),
  child: Column(children: [
    ActionTile(icon: Icons.receipt_long_outlined, title: 'History',
        onTap: openHistory),
    const ActionTile(icon: Icons.pin_outlined, title: 'Change PIN',
        disabledReason: 'Managed by your bank app'),
  ]),
);

Future<void> signOutEverywhere() async {
  final ok = await showPaymentConfirmDialog(context,
      title: 'Sign out of all devices?',
      message: 'Payments already sent are not affected.',
      confirmLabel: 'Sign out', destructive: true);
  if (ok) await host.signOutEverywhere();
}

showPaymentSnackBar(context, message: 'Reference copied',
    tone: StatusTone.success);
```

`ExpandableSection` is uncontrolled by default (`initiallyExpanded`) and controlled when you pass `expanded` with `onExpandedChanged`. Collapsed content is removed from the tree. Do not use it to hide fees.

## Navigation

```dart
AdaptiveNavShell(
  title: const Text('Ruang Bayar'),
  selectedId: current,
  onSelected: (item) => setState(() => current = item.id),
  breakpoint: 840, // sidebar at or above this width, drawer below
  sections: const [
    PaymentNavSection(items: [
      PaymentNavItem(id: 'home', label: 'Home', icon: Icons.home_outlined),
      PaymentNavItem(id: 'history', label: 'History', icon: Icons.history,
          badge: '2'),
      PaymentNavItem(id: 'limits', label: 'Limits', icon: Icons.speed,
          enabled: false, disabledReason: 'Verify first'),
    ]),
  ],
  body: pages[current]!,
);
```

Selection is instant (no animation) because navigation is used constantly. Disabled items are visible with their reason but not focusable. Use `NavSidebar` alone if you already have a shell.

## Sheets and drawers

```dart
await showPaymentSheet<void>(
  context: context,
  builder: (sheet) => PaymentSheet(
    header: PaymentSheetHeader(title: 'Pending payment',
        onClose: () => Navigator.pop(sheet)),
    body: const Text('Closing this panel does not cancel the payment.'),
    footer: PaymentButton(
      label: 'Request cancellation',
      variant: PaymentButtonVariant.secondary,
      // Do not return the Future: PaymentButton would show a spinner while
      // the confirmation dialog is open.
      onPressed: () => unawaited(confirmThenAskHost(sheet)),
    ),
  ),
);
```

The header's **Close** only closes the panel. Cancelling a payment is a separate footer action, behind `showPaymentConfirmDialog`, and the host decides the result. `showPaymentSideSheet` takes the same `PaymentSheet`, which then fills the height so the footer sits at the bottom. Pass `isDismissible: false` / `barrierDismissible: false` while a host call that must finish is running.

## Video

The package has no media dependency. You adapt your player once:

```dart
class MyVideo extends PaymentVideoController {
  @override Future<void> initialize() async { /* load, then */
    value = value.copyWith(phase: VideoPhase.ready, duration: d); }
  @override Future<void> play() => engine.play();
  @override Future<void> pause() => engine.pause();
  @override Future<void> seekTo(Duration p) => engine.seekTo(p);
  @override Future<void> setMuted(bool m) => engine.setVolume(m ? 0 : 1);
  @override Future<void> retry() => initialize();
  @override Widget buildSurface(BuildContext context) => engine.view();
}

PaymentVideoPlayer(controller: myVideo, title: 'How to pay with QRIS');
```

A complete adapter for the official `video_player` plugin is in `example/lib/adapters/video_adapter.dart` (about 100 lines). Report safe `errorMessage` text only; never show raw player errors.

Behavior: no autoplay unless `autoPlay: true`, and never under reduced motion. Pauses on app background, in an inactive `IndexedStack` tab, under a covering route, inside `TickerMode(false)`, and on dispose. It does not resume by itself. The host creates and disposes the controller.

## Promotions

```dart
PromoSlot(
  state: offersState, // loading / ready / empty / error
  content: const PromoContent(
    id: 'cb-10', kind: PromoKind.sponsored, advertiser: 'Bank Contoh',
    title: 'Cashback 10% on bills', ctaLabel: 'See offer'),
  onAction: (promo) => host.openOffer(promo.id),
  onDismiss: (promo) => host.hidePromo(promo.id),
  onAbout: (promo) => host.explainPlacement(promo.id),
);
```

Every promotion is labeled ("Sponsored · advertiser" or "Promo"), and the label wraps rather than truncates. The kit never fetches campaigns, counts impressions, applies discounts or changes a quote. To use an ad network, load its content in the host and pass it in; native-ad SDK views and their policies remain the host's integration.

## Payment additions

```dart
Scaffold(
  body: ListView(children: [
    const MerchantHeader(name: 'Ruang Bayar Akademi',
        orderReference: 'RB-118', verified: true),
    PaymentStepIndicator(steps: const ['Verify', 'Checkout', 'Pay'], current: 1),
    PaymentSummary(quote: quote),
    BalanceCard(state: host.balanceState, balance: balance,
        shortfall: host.shortfall),
    PromoCodeInput(status: codeStatus, onApply: host.applyCode,
        appliedCode: code, discount: discount, message: codeError,
        onRemove: host.removeCode),
  ]),
  bottomNavigationBar: PaymentActionBar(
    total: quote.total,
    updating: requoting,
    action: PaymentButton(label: 'Review payment',
        onPressed: requoting ? null : review),
  ),
);
```

A promo code changes the price only through a new host quote (a `QuoteLineKind.discount` line). `BalanceCard` never compares balance with the total; the host passes `BalanceState`.

## Transaction history

```dart
TransactionHistory(
  records: TransactionRecord.where(all, query: query, filter: filter),
  query: query,
  filter: filter,
  loading: loading,
  error: loadError,
  onRetry: reload,
  onQueryChanged: (q) => setState(() => query = q),
  onFilterChanged: (f) => setState(() => filter = f),
  onOpen: (r) => showPaymentSheet(context: context,
      builder: (_) => PaymentSheet(body: TransactionDetail(record: r))),
);
```

A record with `status: null` is "not confirmed yet". It falls under **In progress**, never **Unsuccessful**, and its detail should offer a status check, never paying again. Refunds appear as their own section next to the original payment. `TransactionHistory` lays records out in a column; for long lists, build `TransactionListItem`s in a `ListView.builder`.
