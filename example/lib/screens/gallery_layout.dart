part of 'gallery_screen.dart';

class _LayoutSpecimen extends StatelessWidget {
  const _LayoutSpecimen(this.name);
  final String name;
  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final examples = switch (name) {
      'PaymentBox' => <Widget>[
        const PaymentBox(
          gap: PaymentSpace.block,
          padding: PaymentSpace.group,
          background: PaymentBoxBackground.muted,
          radius: PaymentRadius.control,
          children: [
            PaymentInline('Transfer details'),
            PaymentInline('Use this account number'),
          ],
        ),
        const PaymentBox(
          stack: PaymentStack.horizontal,
          distribute: PaymentDistribute.spaceBetween,
          alignY: PaymentAlign.center,
          children: [PaymentInline('Total'), PaymentInline('IDR 50.000')],
        ),
        const PaymentBox(
          keyline: PaymentKeyline.critical,
          radius: PaymentRadius.box,
          padding: PaymentSpace.block,
          children: [
            PaymentInline(
              '2 fields need attention',
              color: PaymentTextColor.danger,
            ),
          ],
        ),
        PaymentBox(
          stack: PaymentStack.horizontal,
          wrap: true,
          gap: PaymentSpace.related,
          children: [
            for (final label in ['Transfer', 'QRIS', 'Card', 'Wallet', 'Cash'])
              PaymentBadge(label: label, tone: StatusTone.neutral),
          ],
        ),
        PaymentBox(
          stack: PaymentStack.layered,
          alignX: PaymentAlign.center,
          alignY: PaymentAlign.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ColoredBox(color: theme.surfaceMuted),
            ),
            const PaymentIcon(Icons.schedule),
          ],
        ),
      ],
      'PaymentInline' => <Widget>[
        for (final weight in PaymentFontWeight.values)
          PaymentInline(weight.name, weight: weight),
        const PaymentInline('0123456789', tabular: true),
        for (final role in PaymentTextRole.values)
          PaymentInline(role.name, role: role),
        for (final color in PaymentTextColor.values)
          PaymentInline(color.name, color: color),
        const PaymentInline('TRX-DEMO-42', reference: true),
        const PaymentInline.rich([
          PaymentSpan('Pay '),
          PaymentSpan('before 14:05', weight: PaymentFontWeight.bold),
          PaymentSpan(' to keep this price'),
        ]),
      ],
      'PaymentIcon' => <Widget>[
        Wrap(
          spacing: theme.space(PaymentSpace.related),
          children: [
            for (final size in PaymentIconSize.values)
              Column(
                children: [
                  PaymentIcon(Icons.schedule, size: size),
                  PaymentInline(size.name, role: PaymentTextRole.caption),
                ],
              ),
          ],
        ),
        Wrap(
          spacing: theme.space(PaymentSpace.related),
          children: [
            for (final tone in StatusTone.values) PaymentIcon.tone(tone),
          ],
        ),
      ],
      'PaymentImage' => <Widget>[const _ImageTiles()],
      'PaymentCode' => <Widget>[
        const PaymentCode(
          '8808 0012 3456 7890',
          size: PaymentSize.large,
          onCopy: _copyGalleryValue,
          semanticLabel: 'Virtual account number',
        ),
        const PaymentCode('TRX-DEMO-42'),
        const PaymentCode('Tab', kind: PaymentCodeKind.kbd),
        const PaymentCode('whk_err_8f2c', kind: PaymentCodeKind.samp),
        const PaymentCode(
          'status: paid\nreference: DEMO-42',
          kind: PaymentCodeKind.pre,
        ),
        PaymentCode('DEMO-${'0123456789' * 6}', noWrap: true),
        PaymentCode('DEMO-${'0123456789' * 6}'),
      ],
      _ => <Widget>[
        const PaymentInline('Subtotal'),
        const PaymentDivider(),
        const PaymentInline('Total'),
        PaymentDivider(height: theme.space(PaymentSpace.section)),
      ],
    };
    return _Entry(
      name: '$name · variants',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.group),
        children: examples,
      ),
    );
  }
}

class _ImageTiles extends StatefulWidget {
  const _ImageTiles();
  @override
  State<_ImageTiles> createState() => _ImageTilesState();
}

class _ImageTilesState extends State<_ImageTiles> {
  Future<ImageProvider>? tile;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tile ??= renderSyntheticTile(PaymentTheme.of(context).accent, 'BC');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ImageProvider>(
    future: tile,
    builder: (context, snapshot) {
      final provider = snapshot.data;
      return Column(
        spacing: PaymentTheme.of(context).space(PaymentSpace.group),
        children: [
          Wrap(
            spacing: PaymentTheme.of(context).space(PaymentSpace.related),
            children: [
              if (provider != null)
                PaymentImage(
                  image: provider,
                  alt: 'Bank Contoh',
                  width: 96,
                  height: 64,
                  radius: PaymentRadius.control,
                  bordered: true,
                ),
              const PaymentImage(
                image: _PendingTile(),
                alt: 'Loading bank logo',
                width: 96,
                height: 64,
              ),
              PaymentImage(
                image: MemoryImage(Uint8List.fromList([0, 1, 2])),
                alt: 'Bank Contoh logo',
                width: 96,
                height: 64,
              ),
              if (provider != null)
                PaymentImage(image: provider, alt: '', width: 96, height: 64),
            ],
          ),
          if (provider != null)
            PaymentListItem(
              title: 'Bank Contoh',
              secondaryTitle: 'Virtual account',
              size: PaymentListItemSize.large,
              image: PaymentImage(image: provider, alt: 'Bank Contoh'),
            ),
          if (provider != null)
            PaymentAccordionItem(
              title: 'Bank information',
              media: PaymentImage(image: provider, alt: 'Bank Contoh'),
              child: const PaymentInline('Virtual account'),
            ),
        ],
      );
    },
  );
}

class _PendingTile extends ImageProvider<_PendingTile> {
  const _PendingTile();
  @override
  Future<_PendingTile> obtainKey(ImageConfiguration configuration) async =>
      this;
  @override
  ImageStreamCompleter loadImage(
    _PendingTile key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}
