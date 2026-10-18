import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ldr_app/shared/widgets/app_shell.dart';

Widget _app() {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          for (final p in ['/dashboard', '/history', '/insights', '/settings'])
            GoRoute(
                path: p,
                builder: (context, state) => Center(child: Text('page $p'))),
        ],
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('phones get a bottom bar with all four tabs', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final label in ['Today', 'Journey', 'Insights', 'Profile']) {
      expect(find.semantics.byLabel(label), findsOne, reason: label);
    }
    expect(find.text('LDR Sync'), findsNothing,
        reason: 'no sidebar on a phone');
    semantics.dispose();
  });

  testWidgets('wide screens get a sidebar that screen readers can use',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('LDR Sync'), findsOneWidget);
    for (final label in ['Today', 'Journey', 'Insights', 'Profile']) {
      expect(find.semantics.byLabel(label), findsOne, reason: label);
    }

    tester.semantics.tap(find.semantics.byLabel('Journey'));
    await tester.pumpAndSettle();
    expect(find.text('page /history'), findsOneWidget);
    semantics.dispose();
  });
}
