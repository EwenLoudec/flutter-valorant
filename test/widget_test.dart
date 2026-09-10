import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybmw/app.dart';

void main() {
  testWidgets('Home shows the agents page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('AGENTS'), findsWidgets);
    expect(find.text('ARMES'), findsOneWidget);
  });
}
