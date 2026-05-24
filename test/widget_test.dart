import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/screens/main/farmer_manager_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders onboarding language screen after splash',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SooktaApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('สุขท่า'), findsOneWidget);
    expect(find.text('กรุณาเลือกภาษาเพื่อเริ่มต้นใช้งาน'), findsOneWidget);
  });

  testWidgets('farmer manager updates labels when language changes',
      (tester) async {
    final state = SooktaAppState()
      ..setLanguage(AppLanguage.en)
      ..addFarmer(
        const UserProfile(
          farmerId: 'FARM-001',
          name: 'Somchai',
          role: 'Research participant',
          location: 'Plot A',
        ),
      );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: FarmerManagerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage Farmers'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.textContaining('Select a farmer before assessment'),
        findsOneWidget);
    expect(find.text('จัดการรายชื่อชาวสวน'), findsNothing);

    state.setLanguage(AppLanguage.th);
    await tester.pumpAndSettle();

    expect(find.text('จัดการรายชื่อชาวสวน'), findsOneWidget);
    expect(find.text('เพิ่มคน'), findsOneWidget);
    expect(find.textContaining('เลือกชื่อก่อนประเมิน'), findsOneWidget);
    expect(find.text('Manage Farmers'), findsNothing);
  });
}
