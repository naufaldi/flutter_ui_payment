import 'package:flutter_test/flutter_test.dart';

import '../integration_test/capture_slices.dart';

void main() {
  test('a specimen within the cap stays one image', () {
    expect(captureSlices(1200), [(start: 0.0, height: 1200.0)]);
    expect(captureSlices(693), [(start: 0.0, height: 693.0)]);
  });

  test('the longest specimen is covered in order by capped, overlapping '
      'parts (D90)', () {
    // android_catalog_data_table_variants_id_200 requested 5381.5 dp (#172).
    const requested = 5381.5;
    final slices = captureSlices(requested);
    expect(slices, hasLength(5));
    expect(slices.first.start, 0);
    expect(slices.last.start + slices.last.height, requested);
    for (final slice in slices) {
      expect(slice.height, lessThanOrEqualTo(catalogCaptureHeight));
      expect(slice.height, greaterThan(continuationOverlap));
    }
    for (var i = 1; i < slices.length; i++) {
      final previousEnd = slices[i - 1].start + slices[i - 1].height;
      // No gap: each part repeats the previous part's last 64 dp.
      expect(slices[i].start, previousEnd - continuationOverlap);
    }
    expect(
      [for (var i = 0; i < slices.length; i++) continuationName('x_200', i)],
      ['x_200', 'x_200_part2', 'x_200_part3', 'x_200_part4', 'x_200_part5'],
    );
  });
}
