# Integrating the kit into an app

Add the package, configure theme and language, then connect host data and callbacks. Your app and backend own pricing, authorization and payment results; the kit displays them.

## 1. Depend on it

```yaml
dependencies:
  rakit_ui: ^0.1.0
```

No other dependency is required. Add a media plugin only if you use `PaymentVideoPlayer` (see step 5).

For an existing `flutter_ui_payment` host, replace the dependency with `rakit_ui` and change imports to `package:rakit_ui/rakit_ui.dart`. Public widget and model names are unchanged; do not mix types from both package identities.

## 2. Theme and language

```dart
MaterialApp(
  localizationsDelegates: const [
    PaymentLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('id'), Locale('en')],
  theme: ThemeData(
    colorScheme: scheme,
    extensions: [
      PaymentTheme.fromColorScheme(scheme).copyWith(radius: 12),
    ],
  ),
);
```

Without the extension, the kit derives tokens from your `ColorScheme`. For a complete public-API brand bridge, see the [existing-app guide](https://flutter-ui-payment.netlify.app/start/existing-app/).

## 3. App shell

On phones and tablets, use `AdaptiveNavShell` for the app frame, or `NavSidebar` inside your own. Put `PaymentActionBar` in `Scaffold.bottomNavigationBar` on any step where the total and the main action must stay reachable. Use `showPaymentSheet` / `showPaymentSideSheet` with `PaymentSheet` for filters, details and option lists.

## 4. Payment state you own

| You provide | Through | Rule the kit keeps |
| --- | --- | --- |
| Quote (lines, fees, discounts, total) | `PaymentQuote` → `PaymentSummary`, `PaymentActionBar` | Totals come from you; a changed quote needs re-approval in `PaymentConfirmation` |
| Methods and availability | `PaymentMethod` → `PaymentMethodPicker` | Unavailable methods show your reason |
| Balance verdict | `BalanceState`, `shortfall` → `BalanceCard` | The widget never compares balance with total |
| Promo code verdict | `PromoCodeStatus`, `message` → `PromoCodeInput`, then a new quote | The widget never computes a discount |
| Authorization | `AuthorizationPhase` → `AuthorizationPrompt` | No PIN/OTP enters the kit |
| One attempt per payment | `PaymentAttempt`, `reconcile()` | Stale, duplicate and other-attempt snapshots are rejected; unknown is not failure |
| History | `TransactionRecord` list, query, filter | Unknown outcome is "in progress"; refunds stay separate |

Keep a single host owner for this state and map your backend responses into the public models.

## 5. Optional integrations

**Video.** Extend `PaymentVideoController` around your player. Copy `example/lib/adapters/video_adapter.dart` if you use the official `video_player` plugin:

```yaml
dependencies:
  video_player: ^2.11.1 # Android minSdk 24, iOS 13
```

Create the controller in your state, pass it to `PaymentVideoPlayer`, and dispose it yourself.

**Promotions.** Load offers however you like, map them to `PromoContent`, and show them in a `PromoSlot`. Decide in your own callbacks what CTA, dismiss and "Why this?" do, and whether a dismissed offer stays hidden. Keep promotions out of the path between the total and the pay button.

**Feedback.** Use `showPaymentToast` for share/copy results and `showPaymentConfirmDialog` before any irreversible action you run.

## Optional: repository examples

The published-package path above requires no clone. For further reading, the [example source](https://github.com/naufaldi/flutter_ui_payment/tree/main/example) includes Hairline, Lumen and Soft themes in `example/lib/themes.dart`, a demo coordinator and a fake host.

For a product look, add `PaymentButtonTheme` and `PaymentFieldTheme` to the app theme or to a feature's scoped `Theme`, keeping the parent's other extensions. Reuse a repeated look through a named host preset that takes `BuildContext`. `example/lib/compositions/host_checkout.dart` builds two checkout layouts from the same host data and callbacks.

For a connected host example, copy `host_checkout.dart`, `host_payment_recovery.dart` and `host_checkout_journey.dart` from `example/lib/compositions/`. `HostCheckoutJourney` pins the invoice pay action and then renders the existing recovery/receipt composition from host callback results. Its gallery fixture demonstrates a lost submit response and pending/offline recovery without `DemoCoordinator`. The host persists the attempt before sending and supplies revalidated quotes, authoritative snapshots and matching receipt data; the screen keeps only mounted presentation state. The website's Checkout pattern explains callback ownership and session identity.

To run the synthetic demo locally, clone the repository first:

```sh
git clone https://github.com/naufaldi/flutter_ui_payment.git
cd flutter_ui_payment
```

### Run the example

```sh
cd example
flutter run                    # Android emulator/device (API 24+) or iOS simulator
flutter run -d chrome          # web gallery (documentation preview, D64)
flutter build web --release    # static build in example/build/web
```

The app has three tabs: **Demo** (full journey), **Skenario** (every PRD edge case) and **Galeri** (every component). The settings icon switches brand, light/dark, language, text size (up to 200%) and reduced motion.
