import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/main.dart';

void main() {
  testWidgets('MyApp renders the injected home widget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(
        home: Scaffold(body: Center(child: Text('NBA Test Home'))),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('NBA Test Home'), findsOneWidget);
  });

  testWidgets('MyButtons invokes its callback when tapped', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyButtons(
            ontap: () {
              tapped = true;
            },
            text: 'LOG IN',
            color: Colors.red,
          ),
        ),
      ),
    );

    await tester.tap(find.text('LOG IN'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
