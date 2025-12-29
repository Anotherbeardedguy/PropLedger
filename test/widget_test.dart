import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:propledger/app/app.dart';

void main() {
  testWidgets('PropLedger app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PropLedgerApp()));

    expect(find.text('PropLedger - Coming Soon'), findsOneWidget);
  });
}
