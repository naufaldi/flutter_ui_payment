import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_payment_example/coordinator/demo_coordinator.dart';
import '../integration_test/support.dart';

// #237: a person who picks a second scenario while the first is still
// starting lands on the second scenario's screen, not the first one's.
void main() {
  testWidgets('a quick second scenario opens its own start step', (t) async {
    final app = await launch(t);
    app.runScenario(scenarioById('H02'), 0); // starts on checkout
    await t.pump();
    final first = app.coordinator;
    app.runScenario(scenarioById('K02'), 0); // starts on the identity form
    await t.pump();
    expect(app.coordinator, isNot(same(first)));
    await pumpUntil(t, () => !app.coordinator.starting);
    await settle(t);
    expect(app.coordinator.step, FlowStep.kycIdentity);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}
