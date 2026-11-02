import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('catalog capture rejects clipping and reaches its height cap', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(720, 2400);
    const key = ValueKey('specimen:1100 dp regression');
    Future<void> specimen(double height) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Capture regression')),
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.list), label: 'Catalog'),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  key: key,
                  height: height,
                  child: const ColoredBox(
                    color: Colors.amber,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('SPECIMEN TOP'), Text('SPECIMEN BOTTOM')],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await settle(tester);
    }

    await specimen(1100);
    final crop = find.byKey(key);
    debugPrint(
      'Old view proof: specimen=${tester.getRect(crop)}, '
      'gallery=${tester.getRect(find.byType(ListView))}',
    );
    await expectLater(
      capture(binding, tester, 'android_catalog_regression_old', crop: crop),
      throwsA(
        isA<TestFailure>().having(
          (failure) {
            debugPrint('Expected clipping rejection: ${failure.message}');
            return failure.message;
          },
          'message',
          contains('android_catalog_regression_old is truncated'),
        ),
      ),
    );

    tester.view.physicalSize = catalogCaptureSize(tester);
    expect(tester.view.physicalSize.height, lessThan(8192));
    await settle(tester);
    final rect = tester.getRect(crop);
    expect(
      rect.bottom + 16,
      lessThanOrEqualTo(tester.getRect(find.byType(ListView)).bottom),
    );
    await capture(
      binding,
      tester,
      'android_catalog_regression_whole',
      crop: crop,
    );
    final screenshots = binding.reportData!['screenshots'] as List;
    final bytes = (screenshots.last as Map)['bytes'] as List<int>;
    Future<int> imageHeight(List<int> bytes) async {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      final height = frame.image.height;
      frame.image.dispose();
      codec.dispose();
      return height;
    }

    // The crop excludes one physical pixel past the app bar's painted edge.
    expect(await imageHeight(bytes), (1100 + 32) * 2 - 1);

    await specimen(1300);
    await capture(
      binding,
      tester,
      'android_catalog_regression_capped',
      crop: crop,
    );
    expect(
      await imageHeight((screenshots.last as Map)['bytes'] as List<int>),
      catalogCaptureHeight * 2,
    );

    addTearDown(tester.view.resetPadding);
    for (final inset in [0.0, 64.0]) {
      tester.view.padding = FakeViewPadding(top: inset);
      await settle(tester);
      await capture(binding, tester, 'android_regression_flow_$inset');
      expect(
        await imageHeight((screenshots.last as Map)['bytes'] as List<int>),
        tester.view.physicalSize.height - inset,
      );
    }
  });
}
