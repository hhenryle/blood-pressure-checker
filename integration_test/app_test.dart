import 'package:bp_tracker/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> addReading(
    WidgetTester t, String sys, String dia, String pulse, {String? note}) async {
  await t.tap(find.text('Add reading'));
  await t.pumpAndSettle();
  await t.enterText(find.widgetWithText(TextFormField, 'Systolic'), sys);
  await t.enterText(find.widgetWithText(TextFormField, 'Diastolic'), dia);
  await t.enterText(find.widgetWithText(TextFormField, 'Pulse'), pulse);
  if (note != null) {
    await t.enterText(find.widgetWithText(TextField, 'Note (optional)'), note);
  }
  await t.tap(find.text('Save'));
  await t.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full MVP flow', (t) async {
    await app.main();
    await t.pumpAndSettle(const Duration(seconds: 2));

    // Empty state
    expect(find.text('No reading logged today yet'), findsOneWidget);

    // Validation: empty form must not save
    await t.tap(find.text('Add reading'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Required'), findsWidgets);
    // systolic <= diastolic is rejected
    await t.enterText(find.widgetWithText(TextFormField, 'Systolic'), '80');
    await t.enterText(find.widgetWithText(TextFormField, 'Diastolic'), '90');
    await t.enterText(find.widgetWithText(TextFormField, 'Pulse'), '70');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Systolic must be higher than diastolic.'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();

    // Add readings
    await addReading(t, '128', '84', '72', note: 'morning');
    expect(find.text('Done for today'), findsOneWidget);
    expect(find.text('128/84'), findsOneWidget);
    expect(find.text('Stage 1'), findsOneWidget);

    await addReading(t, '190', '125', '95'); // crisis
    expect(find.text('Very high reading'), findsOneWidget);
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(find.text('190/125'), findsOneWidget);

    // History
    await t.tap(find.text('History'));
    await t.pumpAndSettle();
    expect(find.textContaining('128/84 mmHg'), findsOneWidget);
    expect(find.textContaining('190/125 mmHg'), findsOneWidget);

    // Edit
    await t.tap(find.textContaining('128/84 mmHg'));
    await t.pumpAndSettle();
    expect(find.text('Edit reading'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextFormField, 'Systolic'), '118');
    await t.enterText(find.widgetWithText(TextFormField, 'Diastolic'), '76');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.textContaining('118/76 mmHg'), findsOneWidget);
    expect(find.textContaining('128/84 mmHg'), findsNothing);

    // Swipe delete (crisis one)
    await t.drag(find.textContaining('190/125 mmHg'), const Offset(-600, 0));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(find.textContaining('190/125 mmHg'), findsNothing);

    // Trends
    await t.tap(find.text('Trends'));
    await t.pumpAndSettle();
    expect(find.text('Average (7 days)'), findsOneWidget);
    await t.tap(find.text('30 days'));
    await t.pumpAndSettle();
    expect(find.text('Average (30 days)'), findsOneWidget);
    await t.tap(find.text('90 days'));
    await t.pumpAndSettle();
    expect(find.text('Average (90 days)'), findsOneWidget);

    // Settings: default reminders listed, can add and remove one
    await t.tap(find.text('Settings'));
    await t.pumpAndSettle();
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('21:00'), findsOneWidget);
    await t.tap(find.byIcon(Icons.delete_outline).first);
    await t.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('07:00'), findsNothing);
  });
}
