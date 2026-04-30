import 'package:flutter_test/flutter_test.dart';

import 'package:siptrack_mobile/main.dart';

void main() {
  testWidgets('app renders updated shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SipTrackApp());

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('趋势'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('新增'), findsNothing);
  });
}
