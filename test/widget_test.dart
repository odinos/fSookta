import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/app/sookta_app.dart';

void main() {
  testWidgets('renders onboarding language screen after splash', (tester) async {
    await tester.pumpWidget(const SooktaApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('สุขท่า'), findsOneWidget);
    expect(find.text('กรุณาเลือกภาษาเพื่อเริ่มต้นใช้งาน'), findsOneWidget);
  });
}
