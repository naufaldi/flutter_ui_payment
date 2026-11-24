import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/collection_block.dart';

void main() => runBlockDemo(const CollectionBlockDemo());

enum CollectionDemoScenario {
  ready,
  firstEmpty,
  firstError,
  laterEmpty,
  laterError,
}

typedef CollectionSample = ({String title, String detail});
typedef CollectionDemoPage = ({
  List<CollectionSample> rows,
  String? nextCursor,
});
typedef CollectionDemoSource =
    Future<CollectionDemoPage> Function(String? cursor);

const _samples = <CollectionSample>[
  (title: 'Workshop notes', detail: 'PDF · 6 pages'),
  (title: 'Field guide', detail: 'PDF · 12 pages'),
  (title: 'Reading list', detail: 'PDF · 3 pages'),
  (title: 'Site sketches', detail: 'PDF · 4 pages'),
];

/// Synthetic host. The same composition can render notes, scans or documents.
class CollectionBlockDemo extends StatefulWidget {
  const CollectionBlockDemo({
    super.key,
    this.embedded = false,
    this.initialDark = false,
    this.initialScenario = CollectionDemoScenario.ready,
    this.fetchPage,
    this.fixtureDelay = const Duration(milliseconds: 280),
  });

  final bool embedded;
  final bool initialDark;
  final CollectionDemoScenario initialScenario;
  final CollectionDemoSource? fetchPage;
  final Duration fixtureDelay;

  @override
  State<CollectionBlockDemo> createState() => _CollectionBlockDemoState();
}

class _CollectionBlockDemoState extends State<CollectionBlockDemo> {
  late bool _dark = widget.initialDark;
  late CollectionDemoScenario _scenario = widget.initialScenario;
  List<CollectionSample> _rows = [];
  String? _nextCursor;
  CollectionPageState _pageState = CollectionPageStatus.loading;
  int _generation = 0;
  int _failureAttempt = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_fetch(null));
  }

  void _restart(CollectionDemoScenario scenario) {
    setState(() {
      _scenario = scenario;
      _generation++;
      _rows = [];
      _nextCursor = null;
      _pageState = CollectionPageStatus.loading;
    });
    unawaited(_fetch(null));
  }

  void _requestPage() {
    if (_pageState != CollectionPageStatus.moreAvailable &&
        _pageState is! CollectionPageFailure) {
      return;
    }
    setState(() => _pageState = CollectionPageStatus.loading);
    unawaited(_fetch(_nextCursor));
  }

  Future<void> _fetch(String? cursor) async {
    final generation = _generation;
    try {
      final page = await (widget.fetchPage ?? _fixturePage)(cursor);
      if (!mounted || generation != _generation) return;
      setState(() {
        _rows = [..._rows, ...page.rows];
        _nextCursor = page.rows.isEmpty ? null : page.nextCursor;
        _pageState = switch ((cursor, page.rows.isEmpty, _nextCursor)) {
          (_?, true, _) => CollectionPageStatus.laterEmpty,
          (_, _, null) => CollectionPageStatus.ready,
          _ => CollectionPageStatus.moreAvailable,
        };
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _pageState = CollectionPageFailure(
          message: cursor == null
              ? 'The collection couldn’t load. Try again.'
              : 'The next page couldn’t load. Your earlier items are still here.',
          attempt: ++_failureAttempt,
        );
      });
    }
  }

  Future<CollectionDemoPage> _fixturePage(String? cursor) async {
    final scenario = _scenario;
    final fail = cursor == null
        ? scenario == CollectionDemoScenario.firstError
        : scenario == CollectionDemoScenario.laterError;
    if (fail) _scenario = CollectionDemoScenario.ready;
    if (widget.fixtureDelay > Duration.zero) {
      await Future<void>.delayed(widget.fixtureDelay);
    }
    if (fail) throw StateError('Synthetic page failure');
    return switch ((cursor, scenario)) {
      (null, CollectionDemoScenario.firstEmpty) ||
      (
        _?,
        CollectionDemoScenario.laterEmpty,
      ) => (rows: const <CollectionSample>[], nextCursor: null),
      (null, _) => (rows: _samples.take(2).toList(), nextCursor: 'more'),
      _ => (rows: _samples.skip(2).toList(), nextCursor: null),
    };
  }

  Widget _block(BuildContext context) => CollectionBlock(
    key: PageStorageKey('collection-$_generation'),
    header: Text('Documents', style: PaymentType.of(context).title),
    rowCount: _rows.length,
    rowBuilder: (context, index) {
      final row = _rows[index];
      final type = PaymentType.of(context);
      return PaymentBox(
        key: ValueKey(row.title),
        padding: PaymentSpace.group,
        gap: PaymentSpace.inline,
        radius: PaymentRadius.box,
        background: PaymentBoxBackground.surface,
        keyline: PaymentKeyline.neutral,
        children: [
          Text(row.title, style: type.heading),
          Text(row.detail, style: type.caption),
        ],
      );
    },
    pageState: _pageState,
    firstEmpty: StateMessage(
      icon: Icons.folder_open_outlined,
      title: 'No documents yet',
      message: 'Add a document to start your collection.',
      actionLabel: 'Add sample documents',
      onAction: () => _restart(CollectionDemoScenario.ready),
    ),
    laterEmptyMessage: 'No more documents on this page.',
    errorTitle: 'Couldn’t load documents',
    loadMoreLabel: 'Load more',
    retryLabel: 'Retry',
    onRequestPage: _requestPage,
  );

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _block(context)
      : BlockDemoShell(
          title: 'Collection demo',
          dark: _dark,
          onToggleDark: () => setState(() => _dark = !_dark),
          scenarios: [
            for (final (scenario, label) in [
              (CollectionDemoScenario.ready, 'Documents available'),
              (CollectionDemoScenario.firstEmpty, 'Empty first page'),
              (CollectionDemoScenario.firstError, 'Fail first page once'),
              (CollectionDemoScenario.laterEmpty, 'Empty next page'),
              (CollectionDemoScenario.laterError, 'Fail next page once'),
            ])
              (label: label, onSelected: () => _restart(scenario)),
          ],
          body: _block,
        );
}
