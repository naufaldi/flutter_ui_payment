import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';

void main() => runBlockDemo(const CollectionPageDemo());

enum _PageStatus { loading, ready, failed }

/// A synthetic host that replaces the current document page on each request.
class CollectionPageDemo extends StatefulWidget {
  const CollectionPageDemo({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CollectionPageDemo> createState() => _CollectionPageDemoState();
}

class _CollectionPageDemoState extends State<CollectionPageDemo> {
  int _page = 1;
  bool _dark = false;
  bool _failPageTwo = true;
  _PageStatus _status = _PageStatus.ready;

  Future<void> _load(int page) async {
    if (_status == _PageStatus.loading) return;
    setState(() {
      _page = page;
      _status = _PageStatus.loading;
    });
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() {
      final failed = page == 2 && _failPageTwo;
      if (failed) _failPageTwo = false;
      _status = failed ? _PageStatus.failed : _PageStatus.ready;
    });
  }

  Widget _body(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final group = theme.space(PaymentSpace.group);
    final rows = switch ((_status, _page)) {
      (_PageStatus.ready, 1) => [
        ('Workshop notes', 'PDF · 6 pages'),
        ('Field guide', 'PDF · 12 pages'),
      ],
      (_PageStatus.ready, 2) => [('Reading list', 'PDF · 3 pages')],
      _ => const <(String, String)>[],
    };

    return RefreshIndicator(
      onRefresh: () => _load(_page),
      child: PaymentCollection(
        key: ValueKey(_page),
        physics: const AlwaysScrollableScrollPhysics(),
        maxContentWidth: 448,
        rowGap: PaymentSpace.block,
        padding: EdgeInsets.fromLTRB(
          group,
          group,
          group,
          theme.space(PaymentSpace.section),
        ),
        rowCount: rows.length,
        rowBuilder: (context, index) {
          final (title, detail) = rows[index];
          return PaymentBox(
            padding: PaymentSpace.group,
            gap: PaymentSpace.inline,
            radius: PaymentRadius.box,
            background: PaymentBoxBackground.surface,
            keyline: PaymentKeyline.neutral,
            children: [
              Text(title, style: type.heading),
              Text(detail, style: type.caption),
            ],
          );
        },
        placeholder: switch (_status) {
          _PageStatus.loading => Semantics(
            liveRegion: true,
            label: 'Loading documents',
            excludeSemantics: true,
            child: const StateMessage(
              icon: Icons.sync,
              title: 'Loading documents',
            ),
          ),
          _PageStatus.failed => StateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Couldn’t load this page',
            message: 'Check your connection and try again.',
            tone: StatusTone.danger,
            actionLabel: 'Try again',
            onAction: () => _load(_page),
          ),
          _PageStatus.ready => const StateMessage(
            icon: Icons.folder_open_outlined,
            title: 'No documents on this page',
            message: 'Go back to see the previous page.',
          ),
        },
        footer: _status == _PageStatus.ready
            ? Column(
                spacing: theme.space(PaymentSpace.related),
                children: [
                  Text('Page $_page', style: type.caption),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: theme.space(PaymentSpace.related),
                    runSpacing: theme.space(PaymentSpace.related),
                    children: [
                      if (_page > 1)
                        PaymentButton(
                          label: 'Previous',
                          variant: PaymentButtonVariant.secondary,
                          onPressed: () => unawaited(_load(_page - 1)),
                        ),
                      if (_page < 3)
                        PaymentButton(
                          label: 'Next',
                          variant: PaymentButtonVariant.secondary,
                          onPressed: () => unawaited(_load(_page + 1)),
                        ),
                    ],
                  ),
                ],
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _body(context)
      : BlockDemoShell(
          title: 'Page collection',
          dark: _dark,
          onToggleDark: () => setState(() => _dark = !_dark),
          body: _body,
        );
}
