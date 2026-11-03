import 'package:flutter/widgets.dart';

// Internal layout constants shared by the kit. Not exported.

/// The phone/wide breakpoint. Content layouts (stacked footers, tables) compare
/// the available width with it; overlay presentation compares the window's
/// shortest side ([isCompact], D92).
const kCompactBreakpoint = 600.0;

/// Widest content column on wide screens (D53).
const kContentMaxWidth = 640.0;

/// From this width a page with a secondary column shows two columns.
const kTwoColumnBreakpoint = 840.0;

/// Widest two-column page on wide screens (Q1 of the 1 Nov 2026 review).
const kTwoColumnMaxWidth = 1040.0;

/// Leading media tile in large list rows and accordion headers. A component
/// size, not a spacing role (D46), so it is not a `PaymentSpace` value.
const kMediaTile = 40.0;

/// Whether overlays use their phone presentation: the confirm sheet (D45), the
/// search sheet (D50), the menu action sheet (D55) and the bottom focus view.
///
/// True when the window's shortest side is under [kCompactBreakpoint] (D92), so
/// a phone keeps its phone patterns in landscape (640 x 360 dp) while a tablet,
/// whose shortest side is at least 600 dp, keeps the wide patterns either way.
bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide < kCompactBreakpoint;
