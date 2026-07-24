// Smoke test: app boots into the splash while bootstrap runs.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakshi_vani/app.dart';

void main() {
  testWidgets('App builds and shows Hindi title on splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SakshiVaniApp()));
    await tester.pump();

    // While bootstrap is loading, the splash renders the app's Hindi name.
    expect(find.text('साक्षी वाणी'), findsOneWidget);
  });
}
