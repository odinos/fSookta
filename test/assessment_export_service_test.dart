import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/economic_impact_models.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/assessment_export_service.dart';

void main() {
  test('builds Excel-compatible CSV with Thai summary fields', () {
    const before = ErgoResult(
      riskLevel: RiskLevel.high,
      techScore: 8,
      userScore: 8,
      userScoreColor: 0xFFFF5252,
      limitValue: 15,
      suggestionKey: 'sugg_reba_high',
      economicLoss: 12000,
      bodyPartRisks: {BodyPart.trunk: RiskLevel.high},
    );
    const after = ErgoResult(
      riskLevel: RiskLevel.medium,
      techScore: 6,
      userScore: 6,
      userScoreColor: 0xFFFFF176,
      limitValue: 15,
      suggestionKey: 'sugg_reba_med',
      economicLoss: 8000,
      bodyPartRisks: {BodyPart.trunk: RiskLevel.medium},
    );

    final csv = AssessmentExportService.buildExcelCsv(
      bundle: const AssessmentBundle(
        activity: SooktaActivity.harvesting,
        activityName: 'การเก็บเกี่ยว',
        jobType: JobType.reba,
        before: before,
        after: after,
        selectedSuggestionKeys: ['act_avoid_bend'],
        breakdown: AssessmentBreakdown(
          primaryMethod: AssessmentMethod.reba,
          rebaInput: RebaInputData(
            trunkScore: 4,
            neckScore: 2,
            legScore: 2,
            upperArmScore: 3,
            lowerArmScore: 2,
            wristScore: 2,
            trunkTwist: true,
            loadScore: 1,
            couplingScore: 1,
            activityScore: 1,
          ),
          rebaResult: before,
          ergoInput: ErgoInputData(jobType: JobType.reba),
        ),
      ),
      profile: const UserProfile(
        farmerId: 'FARM-001',
        name: 'สมหญิง',
        role: 'ชาวสวน',
        location: 'สวนตัวอย่าง',
        incomePerYear: '120000',
      ),
      selectedSuggestions: const ['หลีกเลี่ยงการก้มหลังค้างนาน'],
      beforeImpact: const EconomicImpactBreakdown(
        bodyTreatmentCost: 100,
        medicalVisitCost: 200,
        medicineAndSuppliesCost: 300,
        travelCost: 400,
        lostIncome: 500,
        reducedIncome: 600,
        compensationCost: 0,
        bodyImpacts: [],
      ),
      afterImpact: const EconomicImpactBreakdown(
        bodyTreatmentCost: 50,
        medicalVisitCost: 100,
        medicineAndSuppliesCost: 150,
        travelCost: 200,
        lostIncome: 250,
        reducedIncome: 300,
        compensationCost: 0,
        bodyImpacts: [],
      ),
    );

    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('การเก็บเกี่ยว'));
    expect(csv, contains('Worksheet Template Data Input for Application'));
    expect(csv, contains('Farmer ID'));
    expect(csv, contains('FARM-001'));
    expect(csv, contains('REBA Score'));
    expect(csv, contains('ISO 11228 Risk Level'));
    expect(csv, contains('Productivity Loss (THB)'));
    expect(csv, contains('ค่าพบแพทย์/คลินิก'));
    expect(csv, contains('รายละเอียดการประเมิน REBA/ISO11228'));
    expect(csv, contains('ข้อมูลย่อย REBA'));
    expect(csv, contains('ข้อมูลย่อย ISO11228'));
    expect(csv, contains('หลีกเลี่ยงการก้มหลังค้างนาน'));
  });

  test('builds history export CSV from saved record', () {
    final csv = AssessmentExportService.buildHistoryRecordCsv(
      record: EvaluationHistoryRecord(
        id: 7,
        activity: SooktaActivity.pruning,
        activityName: 'การตัดแต่งกิ่ง',
        dateTime: DateTime(2026, 5, 24, 8, 30),
        scoreBefore: 8,
        scoreAfter: 6,
        riskBefore: RiskLevel.high,
        riskAfter: RiskLevel.medium,
        economicLoss: 12000,
        moneySaved: 4000,
        selectedSuggestions: const ['ใช้ด้ามต่อเพื่อลดการยกแขนสูง'],
        bodyPartRisks: const {BodyPart.arms: RiskLevel.high},
        assessmentBreakdown: const AssessmentBreakdown(
          primaryMethod: AssessmentMethod.iso11228PushPull,
          rebaInput: RebaInputData(),
          rebaResult: ErgoResult(
            riskLevel: RiskLevel.medium,
            techScore: 6,
            userScore: 6,
            userScoreColor: 0xFFFFF176,
            limitValue: 15,
            suggestionKey: 'sugg_reba_med',
          ),
          ergoInput: ErgoInputData(
            jobType: JobType.pushPull,
            initialForce: 30,
            sustainForce: 12,
          ),
          isoMethod: AssessmentMethod.iso11228PushPull,
          isoResult: ErgoResult(
            riskLevel: RiskLevel.high,
            techScore: 1.5,
            userScore: 8,
            userScoreColor: 0xFFFF5252,
            limitValue: 20,
            suggestionKey: 'sugg_push_pull_high',
          ),
        ),
      ),
      profile: const UserProfile(
        farmerId: 'FARM-002',
        name: 'สมชาย',
        role: 'เจ้าของสวน',
        location: 'แปลงเหนือ',
      ),
    );

    expect(csv, contains('เลขประเมิน'));
    expect(csv, contains('การตัดแต่งกิ่ง'));
    expect(csv, contains('FARM-002'));
    expect(csv, contains('Maintenance / Pruning'));
    expect(csv, contains('ผลกระทบหลังปรับโดยประมาณ'));
    expect(csv, contains('ISO11228-2'));
    expect(csv, contains('แรงเริ่มต้นดัน/ลาก'));
    expect(csv, contains('8000'));
  });

  test('builds all-farmer worksheet CSV for research staff', () {
    final record = EvaluationHistoryRecord(
      id: 9,
      farmerProfileId: 'profile-a',
      farmerId: 'FARM-009',
      farmerName: 'สมปอง',
      farmerRole: 'ผู้ช่วยเก็บเกี่ยว',
      farmerLocation: 'แปลงใต้',
      activity: SooktaActivity.transport,
      activityName: 'การขนย้ายผลผลิต',
      dateTime: DateTime(2026, 5, 24),
      scoreBefore: 7,
      scoreAfter: 5,
      riskBefore: RiskLevel.high,
      riskAfter: RiskLevel.medium,
      economicLoss: 9000,
      moneySaved: 2500,
      selectedSuggestions: const ['ใช้รถเข็น'],
      bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
      assessmentBreakdown: const AssessmentBreakdown(
        primaryMethod: AssessmentMethod.iso11228Lifting,
        rebaInput: RebaInputData(trunkScore: 3),
        rebaResult: ErgoResult(
          riskLevel: RiskLevel.medium,
          techScore: 5,
          userScore: 5,
          userScoreColor: 0xFFFFF176,
          limitValue: 15,
          suggestionKey: 'sugg_reba_med',
        ),
        ergoInput: ErgoInputData(
          jobType: JobType.lifting,
          loadWeight: 15,
          transportDistance: 8,
          liftFrequency: 2,
          durationHours: 1.5,
        ),
        isoMethod: AssessmentMethod.iso11228Lifting,
        isoResult: ErgoResult(
          riskLevel: RiskLevel.high,
          techScore: 1.4,
          userScore: 7,
          userScoreColor: 0xFFFF5252,
          limitValue: 10,
          suggestionKey: 'sugg_lifting_high',
        ),
      ),
    );

    final csv = AssessmentExportService.buildAllHistoryCsv(
      records: [record],
      profilesByRecordId: const {
        9: UserProfile(
          profileId: 'profile-a',
          farmerId: 'FARM-009',
          name: 'สมปอง',
          role: 'ผู้ช่วยเก็บเกี่ยว',
          location: 'แปลงใต้',
        ),
      },
    );

    expect(csv, contains('Record ID'));
    expect(csv, contains('FARM-009'));
    expect(csv, contains('การขนย้ายผลผลิต'));
    expect(csv, contains('Manual Handling Weight (kg)'));
    expect(csv, contains('ใช้รถเข็น'));
  });
}
