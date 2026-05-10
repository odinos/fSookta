import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/main.dart';

void main() {
  testWidgets('renders starter home screen', (tester) async {
    await tester.pumpWidget(const FSooktaApp());

    expect(find.text('fSookta'), findsOneWidget);
    expect(find.text('Flutter starter is ready'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}

