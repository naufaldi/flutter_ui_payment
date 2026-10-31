// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://flutter-ui-payment.netlify.app',
  // Pages that moved or were split into the component catalog. Astro writes a
  // redirect page for each; public/_redirects makes them real 301s on Netlify.
  redirects: {
    '/components/foundation': '/components/',
    '/components/interaction': '/components/',
    '/concepts/motion': '/foundations/motion/',
    '/concepts/localization': '/foundations/localization/',
  },
  integrations: [
    starlight({
      title: 'flutter_ui_payment',
      description:
        'Composable Flutter UI for checkout, payment status, receipts and optional KYC that stays honest when a payment result is not known yet.',
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/naufaldi/flutter_ui_payment',
        },
      ],
      editLink: {
        baseUrl: 'https://github.com/naufaldi/flutter_ui_payment/edit/main/website/',
      },
      customCss: ['./src/styles/hairline.css'],
      components: {
        Hero: './src/components/Hero.astro',
      },
      lastUpdated: false,
      pagination: true,
      expressiveCode: {
        themes: ['github-dark', 'github-light'],
        styleOverrides: {
          borderRadius: '6px',
          borderColor: 'var(--fup-rule)',
          frames: {
            shadowColor: 'transparent',
            editorActiveTabIndicatorTopColor: 'transparent',
          },
        },
      },
      sidebar: [
        {
          label: 'Start',
          items: [
            { label: 'Introduction', slug: 'start/introduction' },
            { label: 'Installation', slug: 'start/installation' },
            { label: 'Quick start', slug: 'start/quick-start' },
          ],
        },
        {
          label: 'Concepts',
          items: [
            { label: 'Host-owned decisions', slug: 'concepts/host-owned' },
            { label: 'Payment attempt and status', slug: 'concepts/payment-attempt' },
            { label: 'Theming', slug: 'concepts/theming' },
            { label: 'Accessibility', slug: 'concepts/accessibility' },
          ],
        },
        {
          label: 'Foundations',
          items: [
            { label: 'Color', slug: 'foundations/color' },
            { label: 'Typography', slug: 'foundations/typography' },
            { label: 'Spacing and radius', slug: 'foundations/spacing' },
            { label: 'Surfaces', slug: 'foundations/surfaces' },
            { label: 'Iconography', slug: 'foundations/iconography' },
            { label: 'Motion', slug: 'foundations/motion' },
            { label: 'Focus and press', slug: 'foundations/focus' },
            { label: 'Money and dates', slug: 'foundations/money' },
            { label: 'Localization', slug: 'foundations/localization' },
          ],
        },
        {
          label: 'Components',
          items: [
            { label: 'Overview', slug: 'components' },
            {
              label: 'Actions',
              items: [
                { label: 'Icon button', slug: 'components/icon-button' },
            { label: 'Link', slug: 'components/link' },
            { label: 'Copy button', slug: 'components/copy-button' },
            { label: 'Button', slug: 'components/button' },
                { label: 'List', slug: 'components/action-tile' },
                { label: 'Menu', slug: 'components/action-menu' },
              ],
            },
            { label: 'Layout', items: [{ label: 'Box', slug: 'components/box' }, { label: 'Inline', slug: 'components/inline' }, { label: 'Icon', slug: 'components/icon' }, { label: 'Image', slug: 'components/image' }, { label: 'Code', slug: 'components/code' }] },
            {
              label: 'Forms',
              items: [
                { label: 'Chip', slug: 'components/chip' },
                { label: 'Search field', slug: 'components/search-field' },
                { label: 'Date range picker', slug: 'components/date-range-picker' },

                { label: 'Text area', slug: 'components/text-area' },
                { label: 'Select', slug: 'components/select' },
                { label: 'Date field', slug: 'components/date-field' },
                { label: 'Form field group', slug: 'components/form-field-group' },

                { label: 'Checkbox', slug: 'components/checkbox' },
                { label: 'Radio', slug: 'components/radio' },
                { label: 'Switch', slug: 'components/switch' },
                { label: 'Text field', slug: 'components/text-field' },
            { label: 'Currency field', slug: 'components/amount-input' },
              ],
            },
            {
              label: 'Feedback',
              items: [
                { label: 'Badge', slug: 'components/status-badge' },
                { label: 'Banner', slug: 'components/notice-banner' },
                { label: 'Toast', slug: 'components/toast' },
                { label: 'Status header', slug: 'components/status-header' },
                { label: 'Spinner', slug: 'components/spinner' },
                { label: 'Loading skeleton', slug: 'components/loading-skeleton' },
                { label: 'State message', slug: 'components/state-message' },
              ],
            },
            {
              label: 'Content',
              items: [
              'components/property-list',
              'components/table',
                { label: 'Amount text', slug: 'components/amount-text' },
                { label: 'Info row', slug: 'components/info-row' },
                { label: 'Section', slug: 'components/section' },
                { label: 'Accordion', slug: 'components/expandable-section' },
                { label: 'Divider', slug: 'components/divider' },
                { label: 'Tooltip', slug: 'components/tooltip' },
                { label: 'Countdown', slug: 'components/countdown' },
                { label: 'Privacy mask', slug: 'components/privacy-mask' },
              ],
            },
            {
              label: 'Charts', items: [
                {label: 'Line chart', slug: 'components/line-chart'},
                {label: 'Bar chart', slug: 'components/bar-chart'},
                {label: 'Meter chart', slug: 'components/meter-chart'},
                {label: 'Sparkline', slug: 'components/sparkline'},
              ],
            },
            {
              label: 'Navigation',
              items: [
                { label: 'Tabs', slug: 'components/tabs' },
                { label: 'Navigation shell', slug: 'components/navigation' },
              ],
            },
            {
              label: 'Overlays',
              items: [
                { label: 'Dialog', slug: 'components/dialog' },
                { label: 'Sheet', slug: 'components/sheets' },
                {label: 'Capture source sheet', slug: 'components/capture-source-sheet'},
              ],
            },
          ],
        },
        {
          label: 'Payment flows',
          items: [
            { label: 'Checkout', slug: 'components/checkout' },
            { label: 'Status and receipt', slug: 'components/status-receipt' },
            { label: 'Transaction history', slug: 'components/history' },
            { label: 'Verification (KYC)', slug: 'components/verification' },
            {label: 'KYC capture', slug: 'components/kyc-capture'},
            { label: 'Media', slug: 'components/media' },
            { label: 'Promotions', slug: 'components/promotions' },
          ],
        },
        {
          label: 'Patterns', items: [{label: 'Chart layout', slug: 'patterns/chart-layout'}],
        },
        {
          label: 'Reference',
          items: [
            { label: 'Compatibility', slug: 'reference/compatibility' },
            { label: 'Changelog', slug: 'reference/changelog' },
            { label: 'License', slug: 'reference/license' },
            { label: 'Design decisions', slug: 'reference/design-decisions' },
          ],
        },
      ],
    }),
  ],
});
