import 'package:flutter_test/flutter_test.dart';

import 'package:timetable_scheduler/main.dart';

void main() {
  testWidgets('App shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Login'), findsWidgets);
  });
}
