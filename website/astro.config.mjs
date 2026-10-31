// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
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
            { label: 'Localization', slug: 'concepts/localization' },
            { label: 'Accessibility', slug: 'concepts/accessibility' },
            { label: 'Motion', slug: 'concepts/motion' },
          ],
        },
        {
          label: 'Components',
          items: [
            { label: 'Foundation', slug: 'components/foundation' },
            { label: 'Checkout', slug: 'components/checkout' },
            { label: 'Status and receipt', slug: 'components/status-receipt' },
            { label: 'Transaction history', slug: 'components/history' },
            { label: 'Verification (KYC)', slug: 'components/verification' },
            { label: 'Interaction', slug: 'components/interaction' },
            { label: 'Navigation', slug: 'components/navigation' },
            { label: 'Sheets', slug: 'components/sheets' },
            { label: 'Media', slug: 'components/media' },
            { label: 'Promotions', slug: 'components/promotions' },
          ],
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
