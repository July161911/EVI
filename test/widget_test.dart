import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EviApp());
    await tester.pump();
    expect(find.byIcon(CupertinoIcons.sun_max_fill), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.moon_fill), findsOneWidget);
  });
}
