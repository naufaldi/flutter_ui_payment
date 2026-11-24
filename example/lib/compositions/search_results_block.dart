import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

/// A host match and its display text. Use a stable, unique value per hit.
typedef SearchMatch<T> = ({T value, String title, String excerpt});

/// A cumulative result snapshot. Don't mutate a published list. Progress is
/// null when unknown, or a fraction from 0 to 1.
typedef SearchUpdate<T> = ({List<SearchMatch<T>> matches, double? progress});

/// Start a fresh search for a trimmed query. Close the stream on success or
/// emit an error on failure. Stop the host work on subscription cancellation.
typedef SearchSource<T> = Stream<SearchUpdate<T>> Function(String query);

enum _SearchPhase { idle, running, complete, canceled, failed }

/// A Find form and lazy results in one scroll view. Give it bounded height.
/// The host owns the source, cancellation of its work and opening a match.
/// Key this widget by the search scope (for example, the document ID).
class SearchResultsBlock<T> extends StatefulWidget {
  const SearchResultsBlock({
    super.key,
    required this.queryLabel,
    required this.search,
    required this.onOpen,
    this.header,
  });

  final String queryLabel;
  final SearchSource<T> search;
  final ValueChanged<T> onOpen;

  /// Scrolls with the form, so it cannot squeeze it out above the keyboard.
  final Widget? header;

  @override
  State<SearchResultsBlock<T>> createState() => _SearchResultsBlockState<T>();
}

class _SearchResultsBlockState<T> extends State<SearchResultsBlock<T>> {
  final _queryFocus = FocusNode();
  double _keyboardInset = 0;
  String _query = '';
  _SearchPhase _phase = _SearchPhase.idle;
  List<SearchMatch<T>> _matches = [];
  double? _progress;
  int _generation = 0;
  StreamSubscription<SearchUpdate<T>>? _request;

  void _detach() {
    _generation++;
    final request = _request;
    _request = null;
    // The host handles cleanup errors; the detached search cannot affect UI.
    request?.cancel().ignore();
  }

  void _reset(_SearchPhase phase) {
    _phase = phase;
    _matches = [];
    _progress = null;
  }

  void _edit(String value) {
    final query = value.trim();
    if (query == _query) return;
    _detach();
    setState(() {
      _query = query;
      _reset(_SearchPhase.idle);
    });
  }

  void _cancel() {
    if (_phase != _SearchPhase.running) return;
    _detach();
    setState(() => _reset(_SearchPhase.canceled));
  }

  bool get _canSearch => _query.isNotEmpty && _phase != _SearchPhase.running;

  void _submit() {
    if (!_canSearch) return;
    final generation = ++_generation;
    setState(() => _reset(_SearchPhase.running));
    FocusScope.of(context).unfocus();

    bool isCurrent() => mounted && generation == _generation;
    void fail() {
      if (!isCurrent()) return;
      _detach();
      setState(() => _reset(_SearchPhase.failed));
    }

    try {
      _request = widget
          .search(_query)
          .listen(
            (update) {
              if (!isCurrent()) return;
              setState(() {
                _matches = update.matches;
                _progress = update.progress;
              });
            },
            onError: (Object _, StackTrace _) => fail(),
            onDone: () {
              if (!isCurrent()) return;
              _request = null;
              setState(() => _phase = _SearchPhase.complete);
            },
          );
    } catch (_) {
      fail();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final grew = inset > _keyboardInset;
    _keyboardInset = inset;
    if (grew &&
        _queryFocus.hasFocus &&
        MediaQuery.sizeOf(context).height - inset <
            2 * kMinInteractiveDimension) {
      // Flutter reveals the caret with padding that may not fit this viewport.
      // Center the focused editor after the framework's caret reveal.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final editor = _queryFocus.context;
        if (mounted && _queryFocus.hasFocus && editor != null) {
          unawaited(Scrollable.ensureVisible(editor, alignment: .5));
        }
      });
    }
  }

  @override
  void dispose() {
    _detach();
    _queryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final strings = PaymentLocalizations.of(context);
    final group = theme.space(PaymentSpace.group);
    final related = theme.space(PaymentSpace.related);
    final running = _phase == _SearchPhase.running;
    final generation = _generation;
    final id = Localizations.localeOf(context).languageCode == 'id';
    final searching = id ? 'Mencari…' : 'Searching…';
    final canceled = id ? 'Pencarian dibatalkan' : 'Search canceled';
    final empty = id ? 'Tidak ada hasil' : 'No results';
    final count = _matches.length;
    final status = switch (_phase) {
      _SearchPhase.running => Padding(
        padding: EdgeInsets.symmetric(vertical: group),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: related,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(searching, style: type.label),
            ),
            if (_progress != null || !PaymentMotion.of(context).reduced)
              LinearProgressIndicator(
                value: _progress,
                color: theme.accent,
                backgroundColor: theme.surfaceMuted,
              ),
          ],
        ),
      ),
      _SearchPhase.failed => StateMessage(
        icon: Icons.error_outline,
        title: id ? 'Pencarian gagal' : 'Search failed',
        message: id
            ? 'Coba lagi dengan kata kunci yang sama.'
            : 'Try again with the same query.',
        tone: StatusTone.danger,
        actionLabel: strings.retry,
        onAction: _submit,
      ),
      _SearchPhase.complete when _matches.isEmpty => Semantics(
        liveRegion: true,
        label: empty,
        child: ExcludeSemantics(
          child: StateMessage(icon: Icons.search_off, title: empty),
        ),
      ),
      _SearchPhase.complete => Padding(
        padding: EdgeInsets.only(top: group),
        child: Semantics(
          liveRegion: true,
          child: Text(
            id ? '$count hasil' : (count == 1 ? '1 result' : '$count results'),
            style: type.caption,
          ),
        ),
      ),
      _SearchPhase.canceled => Semantics(
        liveRegion: true,
        label: canceled,
        child: ExcludeSemantics(
          child: StateMessage(
            icon: Icons.stop_circle_outlined,
            title: canceled,
          ),
        ),
      ),
      _ => null,
    };

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      semanticChildCount: _matches.length,
      slivers: [
        if (widget.header case final header?) SliverToBoxAdapter(child: header),
        SliverPadding(
          padding: EdgeInsets.all(group),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: related,
                  children: [
                    PaymentTextField(
                      label: widget.queryLabel,
                      focusNode: _queryFocus,
                      type: PaymentTextFieldType.search,
                      prefixIcon: const PaymentIcon(Icons.search),
                      onChanged: _edit,
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_phase != _SearchPhase.failed)
                      PaymentButton(
                        label: running ? strings.cancel : strings.search,
                        variant: running
                            ? PaymentButtonVariant.secondary
                            : PaymentButtonVariant.primary,
                        onPressed: running
                            ? _cancel
                            : (_canSearch ? _submit : null),
                      ),
                  ],
                ),
              ),
              if (status != null) SliverToBoxAdapter(child: status),
              if (_matches.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.only(top: running ? 0 : related),
                  sliver: SliverList.separated(
                    itemCount: _matches.length,
                    separatorBuilder: (_, _) => SizedBox(height: related),
                    itemBuilder: (_, index) {
                      final match = _matches[index];
                      return PaymentListItem(
                        // A streamed insert must not retarget an in-flight tap.
                        key: ValueKey((generation, match.value)),
                        title: match.title,
                        secondaryTitle: match.excerpt,
                        onPressed: () {
                          if (generation == _generation) {
                            widget.onOpen(match.value);
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
