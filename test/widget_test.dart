import 'package:flutter_test/flutter_test.dart';

import 'package:ldr_app/main.dart';

void main() {
  testWidgets('shows setup guidance when Supabase keys are absent',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LdrApp(isConfigured: false));

    expect(find.text('Sync Setting Required'), findsOneWidget);
    expect(find.text('How to run locally:'), findsOneWidget);
  });

  testWidgets('surfaces the specific configuration error', (WidgetTester tester) async {
    await tester.pumpWidget(const LdrApp(
      isConfigured: false,
      configErrorMessage: 'Something specific went wrong',
    ));

    expect(find.text('Something specific went wrong'), findsOneWidget);
  });
}
