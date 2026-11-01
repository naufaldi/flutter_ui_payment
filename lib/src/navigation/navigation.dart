import '../foundation/payment_icons.dart';
import '../foundation/payment_tokens.dart';
import '../controls/actions.dart';
import 'package:flutter/material.dart';

import '../foundation/focus_ring.dart';
import '../foundation/kit_strings.dart';
import '../foundation/payment_localizations.dart';
import '../foundation/payment_theme.dart';
import '../foundation/payment_type.dart';

/// One destination in a [NavSidebar] or [AdaptiveNavShell].
@immutable
class PaymentNavItem {
  const PaymentNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.enabled = true,
    this.disabledReason,
    this.badge,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final bool enabled;

  /// Shown under a disabled item so people know why it can't be opened.
  final String? disabledReason;

  /// Short count or tag, e.g. "2" pending payments or "New".
  final String? badge;
}

/// A titled group of [PaymentNavItem]s.
@immutable
class PaymentNavSection {
  const PaymentNavSection({this.title, required this.items});

  final String? title;
  final List<PaymentNavItem> items;
}

/// Vertical navigation list. Used as the permanent sidebar on wide screens
/// and as the content of the modal drawer on narrow ones.
///
/// Selection is controlled: the host passes [selectedId] and reacts to
/// [onSelected]. Disabled items stay visible but are not focusable.
class NavSidebar extends StatelessWidget {
  const NavSidebar({
    super.key,
    required this.sections,
    required this.selectedId,
    required this.onSelected,
    this.header,
    this.footer,
  });

  final List<PaymentNavSection> sections;
  final String? selectedId;
  final ValueChanged<PaymentNavItem> onSelected;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final l10n = PaymentLocalizations.of(context);
    final type = PaymentType.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.navigation,
      child: FocusTraversalGroup(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: theme.space(PaymentSpace.block),
            vertical: theme.space(PaymentSpace.group),
          ),
          children: [
            if (header != null) ...[
              header!,
              SizedBox(height: theme.space(PaymentSpace.related)),
            ],
            for (final section in sections) ...[
              if (section.title != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    theme.space(PaymentSpace.block),
                    theme.space(PaymentSpace.block),
                    theme.space(PaymentSpace.block),
                    theme.space(PaymentSpace.inline),
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      section.title!,
                      style: type.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              for (final item in section.items)
                _NavTile(
                  item: item,
                  selected: item.id == selectedId,
                  onTap: item.enabled ? () => onSelected(item) : null,
                ),
            ],
            if (footer != null) ...[
              SizedBox(height: theme.space(PaymentSpace.related)),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PaymentNavItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    final enabled = onTap != null;
    final radius = theme.controlBorderRadius;
    final foreground = selected
        ? theme.accent
        : enabled
        ? theme.textPrimary
        : theme.textSecondary;
    // The icon and badge center on the label's first line, so a wrapped
    // label at large text keeps them beside its start.
    final line = PaymentType.firstLineHeight(context);
    // Selection is instant: navigation is used constantly and keyboard users
    // move through it fast, so it should never wait on an animation. It is
    // shown by color and a muted fill (a shape, so not by color alone), never
    // by a change of weight, so the label does not shift.
    return Padding(
      padding: EdgeInsets.only(bottom: theme.space(PaymentSpace.inline)),
      child: Semantics(
        selected: selected,
        enabled: enabled,
        button: true,
        child: PaymentFocusRing(
          radius: radius,
          child: Material(
            color: selected ? theme.surfaceMuted : Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              focusColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.space(PaymentSpace.block),
                      vertical: theme.space(PaymentSpace.related),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaymentIcon(
                          selected
                              ? (item.selectedIcon ?? item.icon)
                              : item.icon,
                          color: selected
                              ? PaymentTextColor.accent
                              : enabled
                              ? PaymentTextColor.primary
                              : PaymentTextColor.secondary,
                        ),
                        SizedBox(width: theme.space(PaymentSpace.block)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: type.label.copyWith(color: foreground),
                              ),
                              if (!enabled && item.disabledReason != null)
                                Text(item.disabledReason!, style: type.caption),
                            ],
                          ),
                        ),
                        if (item.badge != null) ...[
                          SizedBox(width: theme.space(PaymentSpace.related)),
                          ConstrainedBox(
                            constraints: BoxConstraints(minHeight: line),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: theme.space(PaymentSpace.related),
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item.badge!,
                                  style: type.tag.tabular.copyWith(
                                    color: theme.onAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// App shell that shows [NavSidebar] permanently when the window is at
/// least [breakpoint] wide, and in a modal drawer behind a menu button when
/// it is narrower.
///
/// The drawer closes with the scrim, Back or Escape, and focus returns to
/// the menu button afterwards. While closed, its items are not in the tree,
/// so Tab never lands on something off-screen.
class AdaptiveNavShell extends StatefulWidget {
  const AdaptiveNavShell({
    super.key,
    required this.title,
    required this.sections,
    required this.selectedId,
    required this.onSelected,
    required this.body,
    this.actions = const [],
    this.sidebarHeader,
    this.sidebarFooter,
    this.breakpoint = 840,
    this.sidebarWidth = 280,
  });

  final Widget title;
  final List<PaymentNavSection> sections;
  final String? selectedId;
  final ValueChanged<PaymentNavItem> onSelected;
  final Widget body;
  final List<Widget> actions;
  final Widget? sidebarHeader;
  final Widget? sidebarFooter;
  final double breakpoint;
  final double sidebarWidth;

  @override
  State<AdaptiveNavShell> createState() => _AdaptiveNavShellState();
}

class _AdaptiveNavShellState extends State<AdaptiveNavShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  final _menuFocus = FocusNode(debugLabel: 'nav-menu');

  @override
  void dispose() {
    _menuFocus.dispose();
    super.dispose();
  }

  void _select(PaymentNavItem item, {required bool fromDrawer}) {
    if (fromDrawer) _scaffold.currentState?.closeDrawer();
    widget.onSelected(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = PaymentLocalizations.of(context);
    final theme = PaymentTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= widget.breakpoint;
    NavSidebar sidebar({required bool fromDrawer}) => NavSidebar(
      sections: widget.sections,
      selectedId: widget.selectedId,
      onSelected: (item) => _select(item, fromDrawer: fromDrawer),
      header: widget.sidebarHeader,
      footer: widget.sidebarFooter,
    );
    return Scaffold(
      key: _scaffold,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: wide
            ? null
            : PaymentIconButton(
                focusNode: _menuFocus,
                icon: Icons.menu,
                tooltip: l10n.openNavigation,
                onPressed: () => _scaffold.currentState?.openDrawer(),
              ),
        title: widget.title,
        actions: widget.actions,
      ),
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: theme.surface,
              surfaceTintColor: Colors.transparent,
              shape: const RoundedRectangleBorder(),
              child: SafeArea(child: sidebar(fromDrawer: true)),
            ),
      onDrawerChanged: (open) {
        if (!open && _menuFocus.context != null) _menuFocus.requestFocus();
      },
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: widget.sidebarWidth,
                  child: sidebar(fromDrawer: false),
                ),
                VerticalDivider(width: 1, color: theme.outline),
                Expanded(child: widget.body),
              ],
            )
          : widget.body,
    );
  }
}
