import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/app_text.dart';
import 'package:fsookta/app/assets.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/screens/main/farmer_manager_screen.dart';

void main() {
  testWidgets('new farmer editor can select and save an avatar',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: FarmerManagerScreen()),
      ),
    );

    await tester.tap(find.text('เพิ่มคน'));
    await tester.pumpAndSettle();

    expect(find.text('เลือกรูปประจำตัว'), findsOneWidget);
    expect(find.byKey(const ValueKey(SooktaAssets.female02)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey(SooktaAssets.female02)));
    await tester.enterText(
      find.widgetWithText(TextField, const AppText(AppLanguage.th).fullName),
      'เกษตรกรคนที่สอง',
    );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(state.farmers, hasLength(1));
    expect(state.farmers.single.avatarAsset, SooktaAssets.female02);
    expect(find.byKey(const ValueKey('farmer-avatar-image')), findsOneWidget);
  });
}
