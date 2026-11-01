# Integrating the kit into an app

A host app adds the kit in five steps. Each step names what your code must do, because the kit renders state and reports intent but never decides anything about money.

## 1. Depend on it

```yaml
dependencies:
  flutter_ui_payment:
    path: ../flutter-ui-payment # not on pub.dev yet
```

No other dependency is required. Add a media plugin only if you use `PaymentVideoPlayer` (see step 5).

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

Without the extension, the kit derives every token from your `ColorScheme`. The example's two brands live in `example/lib/themes.dart`.

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

Follow `example/lib/coordinator/demo_coordinator.dart` for a single owner of this state, and `example/lib/adapters/fake_host.dart` for the backend contract the UI expects.

## 5. Optional integrations

**Video.** Extend `PaymentVideoController` around your player. Copy `example/lib/adapters/video_adapter.dart` if you use the official `video_player` plugin:

```yaml
dependencies:
  video_player: ^2.11.1 # Android minSdk 24, iOS 13
```

Create the controller in your state, pass it to `PaymentVideoPlayer`, and dispose it yourself.

**Promotions.** Load offers however you like, map them to `PromoContent`, and show them in a `PromoSlot`. Decide in your own callbacks what CTA, dismiss and "Why this?" do, and whether a dismissed offer stays hidden. Keep promotions out of the path between the total and the pay button.

**Feedback.** Use `showPaymentSnackBar` for share/copy results and `showPaymentConfirmDialog` before any irreversible action you run.

## Run the example

```sh
cd example
flutter run                    # Android emulator/device (API 24+) or iOS simulator
flutter run -d chrome          # web gallery (documentation preview, D64)
flutter build web --release    # static build in example/build/web
```

The app has three tabs: **Demo** (full journey), **Skenario** (every PRD edge case) and **Galeri** (every component). The settings icon switches brand, light/dark, language, text size (up to 200%) and reduced motion.
