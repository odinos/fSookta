import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/theme/sookta_theme.dart';
import 'package:fsookta/screens/main/final_result_screen.dart';

void main() {
  testWidgets('captures economic impact comparison on final result',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        if (call.method == 'getVoices') return <Map<String, Object?>>[];
        if (call.method == 'getLanguages') return <String>['th-TH', 'en-US'];
        if (call.method == 'getDefaultVoice') return <String, Object?>{};
        return 1;
      },
    );

    await tester.runAsync(_loadTahomaTestFont);
    await tester.runAsync(_loadMaterialIconsTestFont);

    final state = SooktaAppState()
      ..setLanguage(AppLanguage.th)
      ..saveProfile(
        const UserProfile(
          farmerId: 'FARM-001',
          name: 'ตัวอย่างชาวสวน',
          role: 'ชาวสวน',
          age: '45',
          gender: 'Female',
          weight: '55',
          height: '158',
          incomePerYear: '120000',
        ),
      );
    addTearDown(state.dispose);

    const rebaInput = RebaInputData(
      dailyIncome: 350,
      trunkScore: 3,
      neckScore: 2,
      legScore: 1,
      upperArmScore: 2,
      lowerArmScore: 1,
      wristScore: 1,
      loadScore: 1,
      couplingScore: 1,
      activityScore: 1,
    );
    const ergoInput = ErgoInputData(
      jobType: JobType.lifting,
      gender: 'female',
      dailyIncome: 350,
      toolId: 'seedling_bucket_5_10kg',
      toolLabelTh: 'ถังกล้า (5-10 กก.)',
      toolLabelEn: 'Seedling bucket (5-10 kg)',
      toolWeightKg: 7.5,
      toolWeightBandCode: 2,
      loadWeight: 7.5,
      horizontalDist: 40,
      verticalHeight: 75,
      liftFrequency: 4,
      durationHours: 2,
      workDaysPerWeek: 4,
      transportDistance: 4,
    );
    const before = ErgoResult(
      riskLevel: RiskLevel.high,
      techScore: 7,
      userScore: 7,
      userScoreColor: 0xFFFFB74D,
      limitValue: 7,
      suggestionKey: 'act_transplant_raise_bed',
      economicLoss: 18471,
      bodyPartRisks: {BodyPart.trunk: RiskLevel.high},
    );
    final after = before.copyWith(
      riskLevel: RiskLevel.medium,
      techScore: 5,
      userScore: 5,
      userScoreColor: 0xFFFFF176,
      limitValue: 5,
      economicLoss: 8127,
    );

    final bundle = AssessmentBundle(
      activity: SooktaActivity.transplanting,
      activityName: 'ปลูกกล้า',
      jobType: JobType.lifting,
      before: before,
      after: after,
      selectedSuggestionKeys: const ['act_transplant_raise_bed'],
      breakdown: const AssessmentBreakdown(
        primaryMethod: AssessmentMethod.rebaIsoCombined,
        rebaInput: rebaInput,
        rebaResult: before,
        ergoInput: ergoInput,
        isoMethod: AssessmentMethod.iso11228Lifting,
        isoResult: before,
      ),
    );

    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final theme = buildSooktaTheme();
    final captureKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: AppStateScope(
          state: state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'Tahoma'),
              primaryTextTheme:
                  theme.primaryTextTheme.apply(fontFamily: 'Tahoma'),
            ),
            home: FinalResultScreen(bundle: bundle),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('เปรียบเทียบรายได้ที่สูญเสีย'), findsOneWidget);
    expect(find.text('18,471'), findsOneWidget);
    expect(find.text('8,127'), findsOneWidget);
    expect(find.text('10,344'), findsOneWidget);

    await tester.runAsync(
      () => _capture(captureKey, 'economic_impact_compare_card_current_th'),
    );
  });
}

Future<void> _loadTahomaTestFont() async {
  final bytes =
      await File('/System/Library/Fonts/Supplemental/Tahoma.ttf').readAsBytes();
  final loader = FontLoader('Tahoma')
    ..addFont(
      Future.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  await loader.load();
}

Future<void> _loadMaterialIconsTestFont() async {
  final bytes = await File(
    '/Users/kpc/develop/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  await loader.load();
}

Future<void> _capture(GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    throw StateError('Unable to encode screenshot: $name');
  }
  final file = File('build/manual_screenshots/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
}
