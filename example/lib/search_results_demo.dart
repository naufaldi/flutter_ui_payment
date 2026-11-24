import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/search_results_block.dart';

void main() => runBlockDemo(const SearchResultsDemo());

const _pages = [
  'The house stands at the end of a quiet lane.',
  'A narrow path leads through the garden to the front door.',
  'The front room looks out over the valley.',
  'Inside, a stairway leads to the upper floor.',
  'The garden wall is built from stone found on the property.',
  'The lane continues uphill past a small orchard.',
];

String _text(BuildContext context, String en, String id) =>
    Localizations.localeOf(context).languageCode == 'id' ? id : en;

/// A synthetic reader. Find does not depend on a PDF or OCR engine.
class SearchResultsDemo extends StatefulWidget {
  const SearchResultsDemo({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SearchResultsDemo> createState() => _SearchResultsDemoState();
}

class _SearchResultsDemoState extends State<SearchResultsDemo> {
  bool _dark = false;
  bool _failNextSearch = false;
  int _page = 1;

  Stream<SearchUpdate<int>> _search(String query, String pageLabel) {
    final fail = _failNextSearch;
    _failNextSearch = false;
    var matches = <SearchMatch<int>>[];
    var page = 0;
    final needle = query.toLowerCase();
    late Timer scan;
    late StreamController<SearchUpdate<int>> updates;
    updates = StreamController(
      onListen: () {
        scan = Timer.periodic(const Duration(milliseconds: 300), (timer) {
          if (fail) {
            timer.cancel();
            updates.addError(StateError('Synthetic Find failure'));
            unawaited(updates.close());
            return;
          }
          page++;
          final excerpt = _pages[page - 1];
          if (excerpt.toLowerCase().contains(needle)) {
            matches = [
              ...matches,
              (value: page, title: '$pageLabel $page', excerpt: excerpt),
            ];
          }
          updates.add((matches: matches, progress: page / _pages.length));
          if (page == _pages.length) {
            timer.cancel();
            unawaited(updates.close());
          }
        });
      },
      onCancel: () => scan.cancel(),
    );
    return updates.stream;
  }

  Future<void> _find(BuildContext context) async {
    final title = _text(context, 'Find in document', 'Cari di dokumen');
    final pageLabel = _text(context, 'Page', 'Halaman');
    final theme = PaymentTheme.of(context);
    final motion = PaymentMotion.of(context);
    final match = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Fixed route chrome can take all the space above a landscape keyboard.
      showDragHandle: false,
      backgroundColor: theme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: theme.sheetBorderRadius.topLeft,
        ),
      ),
      sheetAnimationStyle: motion.reduced
          ? AnimationStyle.noAnimation
          : AnimationStyle(
              duration: motion.sheetEnter,
              reverseDuration: motion.sheetExit,
              curve: PaymentMotion.drawer,
            ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: SafeArea(
            top: false,
            child: SearchResultsBlock<int>(
              header: PaymentSheetHeader(
                title: title,
                onClose: () => Navigator.pop(context),
              ),
              queryLabel: _text(context, 'Search text', 'Teks pencarian'),
              search: (query) => _search(query, pageLabel),
              onOpen: (page) => Navigator.pop(context, page),
            ),
          ),
        ),
      ),
    );
    if (mounted && match != null) setState(() => _page = match);
  }

  Widget _reader(BuildContext context) {
    final type = PaymentType.of(context);
    final group = PaymentTheme.of(context).space(PaymentSpace.group);
    final page = _text(context, 'Page', 'Halaman');
    return ListView(
      padding: EdgeInsets.all(group),
      children: [
        Text(_text(context, 'House tour', 'Tur rumah'), style: type.title),
        SizedBox(height: group),
        PaymentButton(
          label: _text(context, 'Find in document', 'Cari di dokumen'),
          variant: PaymentButtonVariant.secondary,
          onPressed: () => _find(context),
        ),
        SizedBox(height: group),
        Text('$page $_page', style: type.heading),
        Text(_pages[_page - 1], style: type.bodyFor(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => widget.embedded
      ? _reader(context)
      : BlockDemoShell(
          title: 'Cari · Demo',
          dark: _dark,
          onToggleDark: () => setState(() => _dark = !_dark),
          scenarios: [
            (
              label: 'Gagal mencari sekali',
              onSelected: () => _failNextSearch = true,
            ),
          ],
          body: _reader,
        );
}
