/// Continuation crops for long catalog specimens (D90).
///
/// Pure arithmetic, no binding, so `example/test` can check it on the host.
library;

/// The tallest single catalog image, in dp (D82).
const catalogCaptureHeight = 1200.0;

/// How much each continuation repeats from the bottom of the image before
/// it, in dp. A row cut at one image's lower edge is whole in the next.
const continuationOverlap = 64.0;

/// One image of a specimen: [start] dp below the crop's top, [height] dp tall.
typedef CaptureSlice = ({double start, double height});

/// Splits a crop [requested] dp tall into ordered images of at most [cap] dp.
///
/// The first image starts at 0. Each later one starts [overlap] dp above the
/// previous image's bottom, and the last ends exactly at [requested], so the
/// images cover the whole crop in reading order.
List<CaptureSlice> captureSlices(
  double requested, {
  double cap = catalogCaptureHeight,
  double overlap = continuationOverlap,
}) {
  assert(requested > 0 && cap > overlap && overlap >= 0);
  final slices = <CaptureSlice>[];
  var start = 0.0;
  while (true) {
    final end = start + cap;
    if (end >= requested) {
      slices.add((start: start, height: requested - start));
      return slices;
    }
    slices.add((start: start, height: cap));
    start = end - overlap;
  }
}

/// File name of image [index] (0-based): the first keeps [base], later ones
/// add `_part2`, `_part3` and so on.
String continuationName(String base, int index) =>
    index == 0 ? base : '${base}_part${index + 1}';

/// Matches a continuation file name and captures its base name.
final continuationPattern = RegExp(r'^(.+)_part([2-9]|[1-9][0-9]+)$');
