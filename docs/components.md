# Components

Use this inventory to find a component, its host responsibilities and an example. Import from `package:rakit_ui/rakit_ui.dart`. The generated [API data](../website/src/data/api.json) lists models and enum values; the [export file](../lib/rakit_ui.dart) identifies public modules. Contributors can use the [daily guide](design-system.md) for requirements.

"Gallery" means the example app's Galeri tab. The catalog groups families alphabetically; payment patterns also appear in the demo screens. The website owns usage examples and Props tables.

## Inventory

| Module / current public names | The host owns | Canonical docs / example location |
| --- | --- | --- |
| Foundation: `PaymentTheme`, `PaymentType`, `PaymentMotion`, `PaymentLocalizations`, `KitStrings`, `HostError` | Brand, locale, safe error content | [Theming](https://rakit-ui.netlify.app/concepts/theming/), [localization](https://rakit-ui.netlify.app/foundations/localization/); foundation gallery |
| Money: `Money`, `MoneyFormat`, `AmountText`, `CountdownText` | Amount/currency, authoritative time | [Money](https://rakit-ui.netlify.app/foundations/money/), [countdown](https://rakit-ui.netlify.app/components/countdown/); foundation gallery |
| Layout: `PaymentBox`, `PaymentInline`, `PaymentSpan`, `PaymentIcon`, `PaymentIcons`, `PaymentImage` | Content, media widget/source | [Box](https://rakit-ui.netlify.app/components/box/), [inline](https://rakit-ui.netlify.app/components/inline/), [image](https://rakit-ui.netlify.app/components/image/); catalog specimens |
| Actions: `PaymentButton`, `PaymentIconButton`, `PaymentLink`, `PaymentCopyButton`, `PaymentButtonGroup` | Callbacks, clipboard/URLs | [Button](https://rakit-ui.netlify.app/components/button/), [button group](https://rakit-ui.netlify.app/components/button-group/), [copy](https://rakit-ui.netlify.app/components/copy-button/); catalog and flow |
| Feedback: `PaymentBadge`, `PaymentBanner`, `StatusHeader`, `StatusBand`, `PaymentSpinner`, `PaymentDivider`, `PrivacyMask` | Status truth, banner removal, OS screenshot protection | [Badge](https://rakit-ui.netlify.app/components/badge/), [banner](https://rakit-ui.netlify.app/components/banner/), [privacy](https://rakit-ui.netlify.app/components/privacy-mask/); foundation gallery |
| Content: `InfoRow`, `MiddleEllipsisText`, `PaymentSection`, `PaymentCode`, `PaymentPropertyList`, `PaymentPropertyListItem` | Values, slots and copy callbacks | [Section](https://rakit-ui.netlify.app/components/section/), [property list](https://rakit-ui.netlify.app/components/property-list/), [code](https://rakit-ui.netlify.app/components/code/); catalog, status/receipt |
| Controls: `PaymentCheckbox`, `PaymentRadio`, `PaymentSwitch`, `PaymentTabs`, `PaymentTab`, `PaymentTabPanels`, `PaymentTooltip` | Values, selection and panel content | [Checkbox](https://rakit-ui.netlify.app/components/checkbox/), [tabs](https://rakit-ui.netlify.app/components/tabs/), [tooltip](https://rakit-ui.netlify.app/components/tooltip/); controls gallery |
| Forms: `PaymentTextField`, `PaymentTextArea`, `PaymentCurrencyField`, `PaymentSelect`, `PaymentDateField`, `PaymentFormFieldGroup` | Controllers, validation, options, allowed dates | [Forms](https://rakit-ui.netlify.app/patterns/forms/), [currency field](https://rakit-ui.netlify.app/components/currency-field/); catalog, identity and checkout |
| Search/filter: `PaymentSearchField`, `PaymentSearchOption`, `PaymentChip`, `PaymentChipList`, `PaymentDateRangePicker`, `PaymentDateRange` | Query/results, filters, date range and loading | [Search](https://rakit-ui.netlify.app/components/search-field/), [date range](https://rakit-ui.netlify.app/components/date-range-picker/); catalog and history |
| Lists/disclosure: `PaymentList`, `PaymentListItem`, `PaymentAccordion`, `PaymentAccordionItem` | Actions, content and optional controlled expansion | [List](https://rakit-ui.netlify.app/components/list/), [accordion](https://rakit-ui.netlify.app/components/accordion/); interaction gallery |
| Tables/tasks: `PaymentTable`, `PaymentTableRow`, `PaymentTableCell`, `PaymentTableHeaderCell`, `PaymentDataTable`, `PaymentDataColumn`, `PaymentTaskList`, `PaymentTaskListItem` | Rows, sort/pagination, task state and actions | [Table](https://rakit-ui.netlify.app/components/table/), [data table](https://rakit-ui.netlify.app/components/data-table/), [task list](https://rakit-ui.netlify.app/components/task-list/); fees, statement, onboarding |
| States: `LoadingSkeleton`, `StateMessage`, `PaymentEmptyMessage` | Loading/error truth and retry | [Loading](https://rakit-ui.netlify.app/patterns/loading/), [empty/error](https://rakit-ui.netlify.app/patterns/empty-and-error/); catalog and history |
| Overlays: `PaymentMenu`, `PaymentMenuEntry`, `PaymentMenuItem`, `PaymentMenuGroup`, `showPaymentConfirmDialog`, `showPaymentToast`, `PaymentToastController` | Menu actions, destructive result, undo | [Menu](https://rakit-ui.netlify.app/components/menu/), [dialog](https://rakit-ui.netlify.app/components/dialog/), [toast](https://rakit-ui.netlify.app/components/toast/); interaction gallery |
| Navigation: `AdaptiveNavShell`, `NavSidebar`, `PaymentNavItem`, `PaymentNavSection` | Selection, routing, pages | [Navigation](https://rakit-ui.netlify.app/components/navigation/); gallery shell |
| Sheets: `PaymentSheet`, `PaymentSheetHeader`, `showPaymentSheet`, `showPaymentSideSheet`, `PaymentFocusView`, `showPaymentFocusView` | Content, actions, dismissal policy | [Sheets](https://rakit-ui.netlify.app/components/sheets/), [focus view](https://rakit-ui.netlify.app/components/focus-view/); sheet gallery, report problem |
| Views: `PaymentContextView`, `PaymentFullPageView`, `PaymentSettingsView`, `PaymentSignInView`, `PaymentOnboardingView` | Shell/routes, slots, save/auth/onboarding decisions | [Views and pages](https://rakit-ui.netlify.app/patterns/views-and-pages/); catalog, settings, sign-in, KYC |
| Pages: `PaymentPageModule`, `PaymentBreadcrumb`, `PaymentDetailPage`, `PaymentOverviewPage`, `PaymentDetailPagePropertyList`, `PaymentDetailPageTable` | Header/content slots, navigation, authoritative records | [Overview](https://rakit-ui.netlify.app/components/overview-page/), [detail](https://rakit-ui.netlify.app/components/detail-page/); overview and transaction detail |
| Media: `PaymentVideoPlayer`, `PaymentVideoController`, `VideoPlaybackValue`, `VideoPhase` | Media engine, source, controller lifecycle | [Media](https://rakit-ui.netlify.app/components/media/); video gallery |
| Promotions: `PromoCard`, `PromoSlot`, `PromoContent`, `PromoLayout`, `PromoKind`, `PromoSlotState` | Campaigns, tracking, CTA and dismiss effects | [Promotions](https://rakit-ui.netlify.app/patterns/promotions/); promotion gallery |
| Checkout: `PaymentSummary`, `PaymentMethodPicker`, `PaymentConfirmation`, `AuthorizationPrompt`, `PaymentQuote`, `PaymentMethod` | Quote, methods, revalidation and auth SDK | [Checkout](https://rakit-ui.netlify.app/patterns/checkout/); demo checkout |
| Checkout additions: `PaymentActionBar`, `MerchantHeader`, `PaymentStepIndicator`, `BalanceCard`, `BalanceState`, `PromoCodeInput`, `PromoCodeStatus` | Action eligibility, merchant verdict, balance/limits, new discounted quote | [Action bar](https://rakit-ui.netlify.app/components/action-bar/), [checkout](https://rakit-ui.netlify.app/patterns/checkout/); checkout gallery |
| Status: `PaymentInstructions`, `PaymentStatusView`, `RefundSection`, `PaymentAttempt`, `PaymentStatusSnapshot` | Status reconciliation inputs, idempotency, polling, refunds | [Status/receipt](https://rakit-ui.netlify.app/patterns/status-receipt/), [attempt](https://rakit-ui.netlify.app/concepts/payment-attempt/); status gallery |
| History: `TransactionHistory`, `TransactionListItem`, `TransactionDetail`, `TransactionRecord`, `TransactionFilter` | Records, server search, query/filter state, actions | [History](https://rakit-ui.netlify.app/patterns/history/); history gallery and flow |
| Receipt: `PaymentReceipt`, `PaymentReceiptData`, `ReceiptShareData`, `ShareOutcome` | Safe receipt data, sharing and clipboard | [Status/receipt](https://rakit-ui.netlify.app/patterns/status-receipt/); receipt flow |
| Verification: `VerificationIntro`, `IdentityForm`, `IdentityFormController`, `DocumentUploadTile`, `VerificationReview`, `VerificationStatusView`, `checkDocumentLimits` | Field specs, validators, document policy/storage/upload and KYC verdict | [Verification](https://rakit-ui.netlify.app/patterns/verification/); verification gallery and flow |
| Charts: `PaymentLineChart`, `PaymentBarChart`, `PaymentMeterChart`, `PaymentSparkline`, `ChartModule`, `ChartPoint`, `ChartPointStatus`, `MeterSegment`, `ChartState` | Ordered data, units, authoritative readings and selection callbacks | [Chart layout](https://rakit-ui.netlify.app/patterns/chart-layout/); chart gallery and overview |
| Capture: `CaptureSource`, `CaptureKind`, `showCaptureSourceSheet`, `CaptureFrameOverlay`, `KycCaptureGuide` | Permissions, camera/gallery, capture, upload | [KYC capture](https://rakit-ui.netlify.app/patterns/kyc-capture/); capture gallery |

**Deprecated compatibility names still present (D34):** `StatusBadge` → `PaymentBadge`, `NoticeBanner` → `PaymentBanner`, `ActionTile` / `ActionTileGroup` → `PaymentListItem` / `PaymentList`, `ActionMenu` / `ActionMenuEntry` → `PaymentMenu` / `PaymentMenuItem`, `AmountInput` → `PaymentCurrencyField`, `ExpandableSection` → `PaymentAccordionItem`, `showPaymentSnackBar` → `showPaymentToast`. These are deprecated now, with removal scheduled for 0.3.0 (D123), not already removed. New integrations use the current names above.

Saved-card storage, PIN/OTP/secret entry, ledgers and ad SDK integration remain outside the kit. All platform effects stay host-owned; see [integration](integration.md).

## Interaction

Use the canonical [list](https://rakit-ui.netlify.app/components/list/), [menu](https://rakit-ui.netlify.app/components/menu/), [dialog](https://rakit-ui.netlify.app/components/dialog/) and [toast](https://rakit-ui.netlify.app/components/toast/) examples. Tooltips also open on tap; longer explanations belong in a sheet.

`PaymentAccordionItem` is uncontrolled by default (`initiallyExpanded`) and controlled with `expanded` / `onExpandedChanged`. Collapsed content is removed from the tree. Never hide required fees in disclosure.

## Navigation

[Navigation usage](https://rakit-ui.netlify.app/components/navigation/) covers shell/sidebar selection, disabled reasons and focus. Selection is instant. Use `NavSidebar` alone when the host already has a shell; the host owns routing.

## Sheets and drawers

[Sheet usage](https://rakit-ui.netlify.app/components/sheets/) covers headers, scrolling bodies, pinned footers and dismissal. Closing a panel does not cancel a payment; cancellation is a separate host action with confirmation. While required work is running, the host chooses the documented dismissal controls.

When a button only opens a confirmation, do not return the confirmation's entire Future as the button's work: that would keep its busy state active while the person decides. The host action itself owns submission state.

## Video

Adapt your media engine to `PaymentVideoController`; [media usage](https://rakit-ui.netlify.app/components/media/) describes its contract. A working adapter is [video_adapter.dart](../example/lib/adapters/video_adapter.dart). Report safe `errorMessage` text, never raw engine errors. The host creates and disposes the controller.

Autoplay is opt-in and respects reduced motion and platform video preferences. The player pauses when backgrounded, hidden by its tab/route, disabled by ticker mode or disposed; it does not resume itself.

## Promotions

[Promotion usage](https://rakit-ui.netlify.app/patterns/promotions/) covers labeled sponsored/own content and slot states. Labels wrap. The kit never fetches campaigns, counts impressions, applies discounts or changes a quote. Native-ad SDK views and policies remain host integrations.

## Payment additions

[Checkout usage](https://rakit-ui.netlify.app/patterns/checkout/) composes summary, methods, balance, promo input and action bar. A promo changes price through a new host quote (`QuoteLineKind.discount`). `BalanceCard` does not compare balance with the total; the host supplies `BalanceState`.

## Transaction history

[History usage](https://rakit-ui.netlify.app/patterns/history/) covers search, filters, loading/error/empty/no-match and separate refunds. A record with `status: null` means not confirmed, under In progress; offer status checking, never paying again. For long lists, build `TransactionListItem`s in `ListView.builder` rather than the column used by `TransactionHistory`.

### Charts and capture

[Chart layout](https://rakit-ui.netlify.app/patterns/chart-layout/) explains ordered trends, comparisons, category snapshots and exact values. [KYC capture](https://rakit-ui.netlify.app/patterns/kyc-capture/) separates source intent from host permission, capture and upload. Passive frames never open a camera themselves.
