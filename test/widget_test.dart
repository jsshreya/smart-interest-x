import 'package:flutter_test/flutter_test.dart';

import 'package:smart_interest_x/app/app.dart';

void main() {
  testWidgets('SmartInterestX app loads successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartInterestXApp());

    await tester.pump();

    expect(find.text('SmartInterestX'), findsOneWidget);
  });
}
