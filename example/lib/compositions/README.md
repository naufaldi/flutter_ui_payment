# Merchant overview: compose a mobile host screen

## History and KYC blocks

- History: run `flutter run -t lib/history_block_demo.dart`. Copy
  `merchant_history.dart`; supply already-filtered records, query/filter and
  safe loading/error state. It composes `TransactionHistory` and a read-only
  `TransactionDetail` sheet with a pinned return action. Use lazy rows and host
  pagination for large datasets. The five-record fixture includes unknown,
  pending, failed, succeeded and a separate partial refund.
- KYC correction: run `flutter run -t lib/kyc_review_demo.dart`. Copy
  `kyc_review_block.dart`; supply document state, host snapshot, typed step and
  callbacks. Replacing a synthetic file does not set verified. Submit moves to
  in-review; only a host verdict changes it to verified. The retry fixture is a
  known pre-acceptance rejection, not an uncertain transport failure. Prior
  consent, auth, document bytes, permissions, validation and retention stay in
  the host. This correction block does not implement initial onboarding.

Source, inspected Android captures and paired pattern contracts are published
in the Blocks section. Roadmap and reference links: GitHub issue #223.

## Checkout and recovery demo

Run `flutter run -t lib/checkout_block_demo.dart` from `example/`.
Copy `host_checkout.dart`, `host_checkout_journey.dart` and
`host_payment_recovery.dart` into your host and replace the synthetic adapter
callbacks. Use a bounded Scaffold body. The demo menu offers lost response,
pending then offline, and receipt retry; light/dark switches in the top bar.
It performs no networking or platform sharing/clipboard operation. The fixture
clock and delayed responses are deterministic, not a production quote/status
source. Persist attempts durably and enforce price/auth/idempotency on your
authoritative side. Full adoption and source are in the website Blocks pages.

## Merchant overview demo

Run from `example/`:

```powershell
. C:/DevTools/Use-FlutterPayment.ps1
flutter run -d <android-device-id> -t lib/merchant_demo.dart
```

`merchant_demo.dart` is the runnable host: a synthetic snapshot, navigation,
account settings and transaction inspection. It sends no payment and calls no
network. **Periksa transaksi** opens the three unknown records; opening a row
explains that the host must check the same attempt. It never invents a verdict.
**Lihat semua** opens all records. Settings switches light/dark.

Copy `merchant_overview.dart` into your own host. Supply your own
`MerchantOverviewData` and callbacks:

```dart
MerchantOverview(
  data: snapshot,
  onInspectUnconfirmed: () => openHistory(unknownOnly: true),
  onViewTransactions: () => openHistory(unknownOnly: false),
  onOpenTransaction: openTransaction,
  onOpenAccount: openAccount,
)
```

The block is a Scaffold-free scrolling body. Your Scaffold owns the safe area
and bottom navigation. The host supplies authoritative balance, revenue, period,
method percentages and unconfirmed count, which may include records outside the
recent preview. Null balance means unavailable, never zero. Do not count unknown
or pending payments as confirmed revenue. Fetching, loading/error/retry of the
snapshot, authentication and status reconciliation belong to the host; this
example starts with a ready synthetic snapshot, not a production data adapter.

`merchant_transaction_detail.dart` composes `PaymentSheet`,
`PaymentSheetHeader`, `AmountText`, `StatusHeader` and `PaymentButton`.
The invoice is supporting text, the amount is the single display value, and
unknown status uses a hatched band plus icon and words. The body scrolls at
large text while the return action stays in the safe-area footer. The demo
detail covers only its confirmed and unknown fixtures; map other provider
states explicitly in a real host. Closing the sheet never changes payment state.

| UI section | Existing library surface |
| --- | --- |
| Balance hero | `AmountText` with `display` variant |
| Unconfirmed notice + action | `PaymentBanner`, `PaymentLink` |
| Revenue and its empty state | `ChartModule`, `PaymentBarChart`, `ChartPoint` |
| Method mix | `PaymentMeterChart`, `MeterSegment` |
| Recent records + unknown badge | `TransactionListItem`, `TransactionRecord` |
| Section rhythm and account action | `PaymentSection`, `PaymentDivider`, `PaymentIconButton` |
| Shared appearance | Existing `buildTheme`, `PaymentTheme`, `PaymentType`, `PaymentSpace` |

There is no new kit API, chart palette or block runtime. D98 composition rules
apply. Native host navigation remains Flutter's `BottomNavigationBar`. Financial
data appears immediately without decorative count-up, chart entrance or stagger.
At large text the content scrolls instead of shrinking to fit the mockup.

The screenshot concept is adapted to supported APIs: the kit owns banner geometry,
chart labels/inspection and transaction presentation. Successful transaction rows
are quiet (their spoken status remains available); unknown rows carry an explicit
badge. These existing contracts are preserved instead of duplicating their logic
to match pixels in an AI mockup.
