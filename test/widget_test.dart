import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/farmer_manager_screen.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';
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

  testWidgets('initial risk AI signal does not expose probability percent',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = SooktaAppState()
      ..setLanguage(AppLanguage.en)
      ..saveProfile(
        const UserProfile(
          farmerId: 'FARM-001',
          name: 'Somchai',
          role: 'Farmer',
          incomePerYear: '120000',
        ),
      );
    const result = ErgoResult(
      riskLevel: RiskLevel.high,
      techScore: 8,
      userScore: 8,
      userScoreColor: 0xFFFF5252,
      limitValue: 15,
      suggestionKey: 'sugg_reba_high',
      economicLoss: 12000,
      bodyPartRisks: {BodyPart.trunk: RiskLevel.high},
      aiRiskAlert: AiRiskAlert(
        probability: 0.72,
        logisticProbability: 0,
        xgBoostProbability: 0.72,
        level: AiAlertLevel.high,
        modelVersion: 'test',
        modelSource: 'research_trained',
        featureImportance: [],
      ),
    );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: InitialRiskScreen(
            payload: InitialRiskPayload(
              activity: SooktaActivity.transplanting,
              activityName: 'Planting',
              jobType: JobType.reba,
              before: result,
              ergoInput: ErgoInputData(jobType: JobType.reba),
              rebaInput: RebaInputData(trunkScore: 4),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Posture Awareness Signal', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('High risk, improve posture', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('72%', skipOffstage: false), findsNothing);
  });
}
