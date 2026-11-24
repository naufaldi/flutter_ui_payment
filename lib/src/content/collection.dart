import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation/payment_theme.dart';
import '../foundation/payment_tokens.dart';

/// A bounded, lazy viewport for records with host-defined rows and states.
///
/// Supply either the current page's rows or accumulated rows. The collection
/// does not fetch, select a state, or infer paging availability. Place it in a
/// parent with finite width and height, not another vertical scroll view.
class PaymentCollection extends StatelessWidget {
  /// Creates a collection without prescribing a row, state or pager style.
  const PaymentCollection({
    super.key,
    required this.rowCount,
    required this.rowBuilder,
    this.findItemIndexCallback,
    this.placeholder,
    this.footer,
    this.controller,
    this.physics,
    this.padding,
    this.maxContentWidth,
    this.rowGap = PaymentSpace.related,
  }) : assert(rowCount >= 0),
       assert(
         maxContentWidth == null ||
             (maxContentWidth > 0 && maxContentWidth < double.infinity),
       );

  /// Number of rows in the host's current snapshot.
  final int rowCount;

  /// Builds visible and nearby rows by index, on demand.
  final IndexedWidgetBuilder rowBuilder;

  /// Looks up the current index of a key on a widget from [rowBuilder].
  ///
  /// For reordered rows, give each row a stable key and return its zero-based
  /// index in the current snapshot, not counting separators. Return null for
  /// a key that is no longer present. This lets mounted rows keep their state
  /// when their index changes.
  final ChildIndexGetter? findItemIndexCallback;

  /// Scrolling content shown only when [rowCount] is zero.
  ///
  /// The host selects and labels its loading, empty or error content.
  final Widget? placeholder;

  /// Optional content that scrolls after the rows or [placeholder].
  ///
  /// Also shown with zero rows, so an empty page can still offer a way back.
  final Widget? footer;

  /// Optional host-owned scroll controller. The host disposes it.
  final ScrollController? controller;

  /// Scroll physics. Use [AlwaysScrollableScrollPhysics] with a host refresh
  /// indicator to allow pull-to-refresh on short or empty pages.
  final ScrollPhysics? physics;

  /// Scrollable insets, defaulting to [PaymentSpace.group] on all sides.
  final EdgeInsetsGeometry? padding;

  /// Optional finite positive width cap for all content, excluding [padding].
  /// Extra width is distributed equally beyond the specified side insets.
  final double? maxContentWidth;

  /// Semantic spacing between adjacent rows.
  final PaymentSpace rowGap;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final group = theme.space(PaymentSpace.group);
    final insets = (padding ?? EdgeInsets.all(group)).resolve(
      Directionality.of(context),
    );
    final hasRows = rowCount > 0;
    final slivers = SliverMainAxisGroup(
      slivers: [
        if (hasRows)
          SliverList.separated(
            itemCount: rowCount,
            itemBuilder: rowBuilder,
            findItemIndexCallback: findItemIndexCallback,
            separatorBuilder: (_, _) => SizedBox(height: theme.space(rowGap)),
          )
        else if (placeholder case final placeholder?)
          SliverToBoxAdapter(child: placeholder),
        if (footer case final footer?)
          SliverPadding(
            padding: EdgeInsets.only(
              top: hasRows || placeholder != null ? group : 0,
            ),
            sliver: SliverToBoxAdapter(child: footer),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = maxContentWidth;
        final gutter = cap == null
            ? 0.0
            : math.max(
                0.0,
                (constraints.maxWidth - insets.horizontal - cap) / 2,
              );
        return CustomScrollView(
          primary: false,
          controller: controller,
          physics: physics,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          semanticChildCount: rowCount,
          slivers: [
            SliverPadding(
              padding: insets + EdgeInsets.symmetric(horizontal: gutter),
              sliver: slivers,
            ),
          ],
        );
      },
    );
  }
}
