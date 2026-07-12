import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumes an evaluation draft with saved media on device',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    final documents = await getApplicationDocumentsDirectory();
    final sourceBytes = await rootBundle.load(
      SooktaActivity.harvesting.readablePoseExampleAsset,
    );
    final imagePaths = <String>[];
    for (var index = 0; index < 4; index++) {
      final file = File(
        p.join(documents.path, 'sookta_resume_media_${index + 1}.jpg'),
      );
      await file.writeAsBytes(
        sourceBytes.buffer.asUint8List(
          sourceBytes.offsetInBytes,
          sourceBytes.lengthInBytes,
        ),
        flush: true,
      );
      imagePaths.add(file.path);
    }

    final initialState = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(initialState.dispose);
    await initialState.saveEvaluationDraft(
      EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedImagePaths: imagePaths,
        selectedToolId: 'basket_mid_10_15kg',
        durationHours: 4,
        frequency: 6.5,
        workDaysPerWeek: 5,
        rebaInput: const RebaInputData(trunkScore: 4, loadScore: 1),
      ),
    );

    final restoredState = SooktaAppState();
    addTearDown(restoredState.dispose);
    await restoredState.restore();

    await tester.pumpWidget(
      AppStateScope(
        state: restoredState,
        child: const MaterialApp(
          home: EvaluationFormScreen(activity: SooktaActivity.harvesting),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('นำข้อมูลแบบร่างกลับมาแล้ว'), findsOneWidget);
    expect(find.text('ภาพครบ 4 จาก 4 มุม'), findsOneWidget);
    expect(find.text('มีภาพแล้ว'), findsNWidgets(4));
    expect(find.text('ยังไม่มีภาพ'), findsNothing);
  });
}
