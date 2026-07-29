import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/screens/main/evaluation_menu_screen.dart';

void main() {
  testWidgets('evaluation menu handles the zero-height Android warm-up frame',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 0);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: EvaluationMenuScreen(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
