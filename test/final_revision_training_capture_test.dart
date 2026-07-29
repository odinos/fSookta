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
import 'package:fsookta/screens/main/daily_prediction_screen.dart';
import 'package:fsookta/screens/main/training_data_export_screen.dart';

void main() {
  testWidgets('captures final revision trend and training export screens',
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
          profileId: 'profile-a',
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
    for (var index = 0; index < 7; index++) {
      await state.saveEvaluation(
        activityName: 'การปลูกกล้า',
        activity: SooktaActivity.transplanting,
        before: ErgoResult(
          riskLevel: RiskLevel.high,
          techScore: 8,
          userScore: index == 6 ? 9 : 8,
          userScoreColor: RiskLevel.high.colorHex,
          limitValue: 9,
          suggestionKey: 'sugg_reba_high',
          economicLoss: 18080,
          bodyPartRisks: const {
            BodyPart.trunk: RiskLevel.high,
            BodyPart.neck: RiskLevel.medium,
          },
        ),
        after: ErgoResult(
          riskLevel: RiskLevel.medium,
          techScore: 5,
          userScore: 5,
          userScoreColor: RiskLevel.medium.colorHex,
          limitValue: 9,
          suggestionKey: 'sugg_reba_med',
          economicLoss: 8127,
          bodyPartRisks: const {
            BodyPart.trunk: RiskLevel.medium,
            BodyPart.neck: RiskLevel.low,
          },
        ),
        selectedSuggestionKeys: const [],
        selectedSuggestions: const [
          'ยกแปลงหรือถังงานให้สูงขึ้น',
          'สลับพักและเปลี่ยนท่าทุกช่วงสั้น ๆ',
        ],
        assessmentBreakdown: _breakdown(index),
      );
    }

    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _captureScreen(
      tester: tester,
      state: state,
      home: const DailyPredictionScreen(),
      name: 'final_revision_before_trend_th',
      expectedText: 'สรุปแนวโน้มความเสี่ยงจริง',
    );
    expect(find.text('คะแนนก่อนปรับ'), findsNothing);
    await tester.scrollUntilVisible(
      find.textContaining('ผลก่อนปรับปรุงเป็นฐาน'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('ผลก่อนปรับปรุงเป็นฐาน'), findsWidgets);
    expect(find.textContaining('ผลหลังปรับปรุงถูกใช้เพื่อเปรียบเทียบ'),
        findsWidgets);
    expect(find.textContaining('REBA ล่าสุด'), findsWidgets);
    expect(find.textContaining('Probability'), findsNothing);

    await _captureScreen(
      tester: tester,
      state: state,
      home: const TrainingDataExportScreen(),
      name: 'final_revision_training_export_th',
      expectedText: 'ส่งออกข้อมูลสำหรับเทรนโมเดล',
    );
    expect(find.textContaining('Logistic Regression'), findsWidgets);
    expect(find.textContaining('XGBoost'), findsWidgets);
  });
}

AssessmentBreakdown _breakdown(int index) {
  return AssessmentBreakdown(
    primaryMethod: AssessmentMethod.rebaIsoCombined,
    rebaInput: const RebaInputData(
      trunkScore: 4,
      neckScore: 2,
      legScore: 1,
      upperArmScore: 2,
      lowerArmScore: 1,
      wristScore: 1,
      loadScore: 1,
      couplingScore: 1,
      activityScore: 1,
    ),
    rebaResult: ErgoResult(
      riskLevel: RiskLevel.high,
      techScore: 8,
      userScore: index == 6 ? 9 : 8,
      userScoreColor: RiskLevel.high.colorHex,
      limitValue: 9,
      suggestionKey: 'sugg_reba_high',
      bodyPartRisks: const {
        BodyPart.trunk: RiskLevel.high,
        BodyPart.neck: RiskLevel.medium,
      },
    ),
    ergoInput: const ErgoInputData(
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
      verticalHeight: 60,
      liftFrequency: 0.2,
      durationHours: 2,
      workDaysPerWeek: 4,
      transportDistance: 5,
    ),
    isoMethod: AssessmentMethod.iso11228Lifting,
    isoResult: ErgoResult(
      riskLevel: RiskLevel.high,
      techScore: 8,
      userScore: 8,
      userScoreColor: RiskLevel.high.colorHex,
      limitValue: 9,
      suggestionKey: 'sugg_iso_lift_high',
    ),
    poseFrames: [
      PoseRebaFrameAnalysis(
        imageIndex: 1,
        timestampMs: 1200 + index,
        rebaInput: const RebaInputData(trunkScore: 4, neckScore: 2),
        rebaScore: 8,
        riskLevel: RiskLevel.high,
        trunkFlexionDeg: 68,
        neckFlexionDeg: 24,
        upperArmFlexionDeg: 55,
        jointFeatures: List.generate(51, (feature) => (feature + 1) / 100),
      ),
    ],
    worstPoseImageIndex: 1,
    motionSummary: const MotionAnalysisSummary(
      sourceKind: 'video_gallery',
      durationMs: 9000,
      sampledFrameCount: 8,
      readableFrameCount: 8,
      sampleRateFps: 0.89,
      highRiskFrameCount: 5,
      highRiskFrameRatio: 0.625,
      deepTrunkFlexionFrameCount: 4,
      deepTrunkFlexionRatio: 0.5,
      estimatedHighRiskSeconds: 5.625,
      estimatedDeepTrunkSeconds: 4.5,
      movementChangeCount: 2,
      pattern: MotionPattern.repeatedRiskMovement,
      anySegmentRiskFrameCount: 6,
      anySegmentRiskFrameRatio: 0.75,
      estimatedSegmentRiskSeconds: 6.75,
      neckRiskFrameCount: 2,
      neckRiskFrameRatio: 0.25,
      trunkRiskFrameCount: 6,
      trunkRiskFrameRatio: 0.75,
      upperArmRiskFrameCount: 3,
      upperArmRiskFrameRatio: 0.375,
      lowerArmRiskFrameCount: 1,
      lowerArmRiskFrameRatio: 0.125,
      wristRiskFrameCount: 1,
      wristRiskFrameRatio: 0.125,
      legRiskFrameCount: 2,
      legRiskFrameRatio: 0.25,
      dominantRiskBodyPart: 'trunk',
      maxTrunkFlexionDeg: 68,
      avgTrunkFlexionDeg: 44,
    ),
  );
}

Future<void> _captureScreen({
  required WidgetTester tester,
  required SooktaAppState state,
  required Widget home,
  required String name,
  required String expectedText,
}) async {
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
          home: home,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1200));
  expect(find.text(expectedText), findsWidgets);
  await tester.runAsync(() => _capture(captureKey, name));
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
