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
      ),
      profile: const UserProfile(name: 'สมหญิง', incomePerYear: '120000'),
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
    expect(csv, contains('ค่าพบแพทย์/คลินิก'));
    expect(csv, contains('หลีกเลี่ยงการก้มหลังค้างนาน'));
  });
}
