import 'package:flutter/widgets.dart';

// Internal layout constants shared by the kit. Not exported.

/// Below this width the kit uses its phone layouts (sheets, stacked footers).
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

/// Whether the window is narrower than [kCompactBreakpoint].
bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kCompactBreakpoint;
