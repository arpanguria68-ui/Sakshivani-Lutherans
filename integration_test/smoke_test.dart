import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sakshi_vani/main.dart' as app;

Future<void> pumpUntilAppReady(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 120),
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (find.text('छोड़ें').evaluate().isNotEmpty ||
        find.text('अगला').evaluate().isNotEmpty ||
        find.text('HOME').evaluate().isNotEmpty ||
        find.text('Initialization failed').evaluate().isNotEmpty ||
        find.byIcon(Icons.menu_book_outlined).evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for app UI');
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('skip onboarding, reach home, open Bible tab', (WidgetTester tester) async {
    app.main();
    await pumpUntilAppReady(tester);

    if (find.text('Initialization failed').evaluate().isNotEmpty) {
      fail('App bootstrap failed on device');
    }

    if (find.text('छोड़ें').evaluate().isNotEmpty) {
      await tester.tap(find.text('छोड़ें'));
      await pumpUntilFound(tester, find.text('HOME'));
    }

    expect(find.text('HOME'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pump(const Duration(seconds: 2));

    final Finder bibleUi = find.byWidgetPredicate(
      (Widget w) =>
          (w is Text &&
              (w.data?.contains('Downloading Bible') == true ||
                  w.data?.contains('Loading Bible') == true ||
                  w.data == 'Retry download')) ||
          w is DropdownButtonFormField<int>,
    );
    await pumpUntilFound(tester, bibleUi, timeout: const Duration(seconds: 45));

    expect(bibleUi, findsWidgets);
  });
}
