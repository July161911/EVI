import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_query_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialQueryApp());
    await tester.pump();
    expect(find.byIcon(CupertinoIcons.sun_max_fill), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.moon_fill), findsOneWidget);
  });
}
