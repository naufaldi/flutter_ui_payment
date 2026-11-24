import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'paged_block_footer.dart';

sealed class CollectionPageState {
  const CollectionPageState();
}

enum CollectionPageStatus implements CollectionPageState {
  ready,
  moreAvailable,
  loading,
  laterEmpty,
}

/// Display-safe copy and a fresh identity for each accepted failure.
final class CollectionPageFailure extends CollectionPageState {
  const CollectionPageFailure({required this.message, required this.attempt});

  final String message;
  final int attempt;
}

/// A bounded, scrolling body. The host builds the accumulated rows and owns
/// the cursor, authorization, request ordering and all effects.
class CollectionBlock extends StatelessWidget {
  const CollectionBlock({
    super.key,
    this.header,
    required this.rowCount,
    required this.rowBuilder,
    required this.pageState,
    required this.firstEmpty,
    required this.laterEmptyMessage,
    required this.errorTitle,
    required this.loadMoreLabel,
    required this.retryLabel,
    required this.onRequestPage,
  });

  final Widget? header;
  final int rowCount;
  final IndexedWidgetBuilder rowBuilder;
  final CollectionPageState pageState;
  final StateMessage firstEmpty;
  final String laterEmptyMessage;
  final String errorTitle;
  final String loadMoreLabel;
  final String retryLabel;

  /// Load the next page or retry the same failed request in the host.
  final VoidCallback onRequestPage;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final group = theme.space(PaymentSpace.group);
    final status = pageState;
    final error = status is CollectionPageFailure ? status : null;
    final loading = status == CollectionPageStatus.loading;
    final empty = rowCount == 0;
    final Widget? footer = switch (status) {
      CollectionPageStatus.laterEmpty => StateMessage(
        icon: Icons.inbox_outlined,
        title: laterEmptyMessage,
      ),
      CollectionPageStatus.moreAvailable ||
      CollectionPageStatus.loading ||
      CollectionPageFailure() when !empty => PagedBlockFooter(
        label: error == null ? loadMoreLabel : retryLabel,
        loading: loading,
        error: error == null
            ? null
            : (message: error.message, attempt: error.attempt),
        onPressed: onRequestPage,
      ),
      _ => null,
    };

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      semanticChildCount: rowCount,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(group),
          sliver: SliverMainAxisGroup(
            slivers: [
              if (header case final header?) ...[
                SliverToBoxAdapter(child: header),
                SliverToBoxAdapter(child: SizedBox(height: group)),
              ],
              if (!empty)
                SliverList.separated(
                  itemCount: rowCount,
                  itemBuilder: rowBuilder,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: theme.space(PaymentSpace.related)),
                )
              else if (status != CollectionPageStatus.laterEmpty)
                SliverToBoxAdapter(
                  child: switch (status) {
                    CollectionPageStatus.loading => const LoadingSkeleton(
                      rows: 4,
                      leading: false,
                    ),
                    CollectionPageFailure(:final message, :final attempt) =>
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: group),
                            child: VisibleBlockError(
                              key: ValueKey(attempt),
                              message: '$errorTitle\n$message',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: theme.space(PaymentSpace.inline),
                                children: [
                                  Text(errorTitle, style: type.heading),
                                  Text(
                                    message,
                                    style: type
                                        .bodyFor(context)
                                        .copyWith(color: theme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          PaymentButton(
                            label: retryLabel,
                            variant: PaymentButtonVariant.secondary,
                            onPressed: onRequestPage,
                          ),
                        ],
                      ),
                    _ => firstEmpty,
                  },
                ),
              if (footer != null)
                SliverPadding(
                  padding: EdgeInsets.only(top: empty ? 0 : group),
                  sliver: SliverToBoxAdapter(child: footer),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
