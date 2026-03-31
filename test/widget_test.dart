import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebebe/main.dart';

void main() {
  testWidgets('shows notes page on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
