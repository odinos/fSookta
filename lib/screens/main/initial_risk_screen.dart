import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/localization/sookta_strings.dart';
import '../../core/models/assessment_session.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/theme/sookta_theme.dart';
import 'final_result_screen.dart';

class InitialRiskScreen extends StatefulWidget {
  const InitialRiskScreen({
    required this.payload,
    super.key,
  });

  static const routeName = '/initial-risk';

  final InitialRiskPayload payload;

  @override
  State<InitialRiskScreen> createState() => _InitialRiskScreenState();
}

class _InitialRiskScreenState extends State<InitialRiskScreen> {
  final selectedKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final strings = SooktaStrings(thai ? SooktaLocale.th : SooktaLocale.en);
    final before = widget.payload.before;
    final suggestions = _suggestionsFor(before, widget.payload.activity);
    final after = _simulateAfter(before);

    return Scaffold(
      appBar: AppBar(
          title: Text(thai ? 'ผลการประเมินเบื้องต้น' : 'Initial Assessment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              thai
                  ? 'กิจกรรม: ${widget.payload.activityName}'
                  : 'Activity: ${widget.payload.activityName}',
              style: const TextStyle(
                color: SooktaColors.darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _RiskSummaryCard(
              result: before,
              title: thai ? 'คะแนนก่อนปรับปรุง' : 'Before Improvement',
              suggestion: strings.get(before.suggestionKey),
              thai: thai,
            ),
            const SizedBox(height: 16),
            _BodyMapCard(
              bodyRisks: before.bodyPartRisks,
              thai: thai,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      thai
                          ? 'แนวทางปรับปรุง (เลือกสิ่งที่ทำได้)'
                          : 'Improvement Plan',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      thai
                          ? 'เลือกหัวข้อด้านล่างเพื่อจำลองคะแนนหลังปรับปรุง'
                          : 'Select actions below to simulate the improved score.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    ...suggestions.map(
                      (key) => CheckboxListTile(
                        value: selectedKeys.contains(key),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedKeys.add(key);
                            } else {
                              selectedKeys.remove(key);
                            }
                          });
                        },
                        title: Text(strings.get(key)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _RiskSummaryCard(
              result: after,
              title: thai ? 'คะแนนจำลองหลังปรับปรุง' : 'Simulated After',
              suggestion: selectedKeys.isEmpty
                  ? (thai
                      ? 'ยังไม่ได้เลือกแนวทางปรับปรุง'
                      : 'No improvement selected')
                  : (thai
                      ? 'คะแนนลดลงตามแนวทางที่เลือก'
                      : 'Score reduced by selected actions'),
              thai: thai,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  FinalResultScreen.routeName,
                  arguments: AssessmentBundle(
                    activity: widget.payload.activity,
                    activityName: widget.payload.activityName,
                    jobType: widget.payload.jobType,
                    before: before,
                    after: after,
                    selectedSuggestionKeys: selectedKeys.toList(),
                  ),
                );
              },
              icon: const Icon(Icons.summarize_outlined),
              label: Text(thai ? 'สรุปผลการปรับปรุง' : 'Summarize Improvement'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _suggestionsFor(ErgoResult result, SooktaActivity activity) {
    final keys = <String>{
      ...result.suggestionKeys,
      switch (activity) {
        SooktaActivity.pesticide => 'act_extra_spray_strap',
        SooktaActivity.pruning => 'act_extra_prune_tool',
        SooktaActivity.fertilizing => 'act_extra_fert_cart',
        _ => 'act_rest_stretch',
      },
    };
    if (keys.isEmpty) keys.add('act_rest_stretch');
    return keys.toList();
  }

  ErgoResult _simulateAfter(ErgoResult before) {
    final reduction = math.min(selectedKeys.length, 4);
    final score = (before.userScore - reduction).clamp(1, 9).toInt();
    final risk = _riskFromUserScore(score);
    final lossFactor =
        selectedKeys.isEmpty ? 1.0 : math.max(0.0, 1 - (0.28 * reduction));
    return ErgoResult(
      riskLevel: risk,
      techScore: math.max(1.0, before.techScore - reduction),
      userScore: score,
      userScoreColor: _scoreColor(score),
      limitValue: before.limitValue,
      suggestionKey: before.suggestionKey,
      economicLoss: (before.economicLoss * lossFactor).round(),
      suggestionKeys: before.suggestionKeys,
      bodyPartRisks: before.bodyPartRisks.map(
        (part, level) =>
            MapEntry(part, reduction > 0 ? _lowerRisk(level) : level),
      ),
    );
  }

  RiskLevel _riskFromUserScore(int score) {
    if (score <= 3) return RiskLevel.low;
    if (score <= 6) return RiskLevel.medium;
    if (score <= 8) return RiskLevel.high;
    return RiskLevel.veryHigh;
  }

  RiskLevel _lowerRisk(RiskLevel level) {
    return switch (level) {
      RiskLevel.veryHigh => RiskLevel.high,
      RiskLevel.high => RiskLevel.medium,
      RiskLevel.medium => RiskLevel.low,
      RiskLevel.low => RiskLevel.low,
    };
  }

  int _scoreColor(int score) {
    const colors = [
      0xFF8BC34A,
      0xFF9CCC65,
      0xFFAED581,
      0xFFDCE775,
      0xFFFFF176,
      0xFFFFD54F,
      0xFFFFB74D,
      0xFFFF8A65,
      0xFFFF5252,
    ];
    return colors[(score - 1).clamp(0, 8).toInt()];
  }
}

class _RiskSummaryCard extends StatelessWidget {
  const _RiskSummaryCard({
    required this.result,
    required this.title,
    required this.suggestion,
    required this.thai,
  });

  final ErgoResult result;
  final String title;
  final String suggestion;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final color = Color(result.userScoreColor);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${result.userScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_riskLabel(result.riskLevel, thai)),
                  const SizedBox(height: 4),
                  Text(suggestion,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text(
                    thai
                        ? 'อาจสูญเสียรายได้ ${result.economicLoss} บ./ปี'
                        : 'Potential loss ${result.economicLoss} THB/year',
                    style: const TextStyle(color: SooktaColors.darkGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _riskLabel(RiskLevel level, bool thai) {
    if (thai) return level.label;
    return switch (level) {
      RiskLevel.low => 'Low Risk',
      RiskLevel.medium => 'Medium Risk',
      RiskLevel.high => 'High Risk',
      RiskLevel.veryHigh => 'Very High Risk',
    };
  }
}

class _BodyMapCard extends StatelessWidget {
  const _BodyMapCard({
    required this.bodyRisks,
    required this.thai,
  });

  final Map<BodyPart, RiskLevel> bodyRisks;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final parts = BodyPart.values;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              thai ? 'ตำแหน่งที่เสี่ยง' : 'Risky Body Parts',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: parts.map((part) {
                final risk = bodyRisks[part] ?? RiskLevel.low;
                return Chip(
                  avatar: CircleAvatar(backgroundColor: Color(risk.colorHex)),
                  label: Text('${_partLabel(part)}: ${_shortRisk(risk)}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _partLabel(BodyPart part) {
    if (thai) {
      return switch (part) {
        BodyPart.neck => 'คอ',
        BodyPart.trunk => 'หลัง',
        BodyPart.legs => 'ขา',
        BodyPart.arms => 'ไหล่/แขน',
        BodyPart.wrists => 'ข้อมือ',
      };
    }
    return switch (part) {
      BodyPart.neck => 'Neck',
      BodyPart.trunk => 'Trunk',
      BodyPart.legs => 'Legs',
      BodyPart.arms => 'Arms',
      BodyPart.wrists => 'Wrists',
    };
  }

  String _shortRisk(RiskLevel level) {
    if (thai) {
      return switch (level) {
        RiskLevel.low => 'ต่ำ',
        RiskLevel.medium => 'ปานกลาง',
        RiskLevel.high => 'สูง',
        RiskLevel.veryHigh => 'สูงมาก',
      };
    }
    return switch (level) {
      RiskLevel.low => 'Low',
      RiskLevel.medium => 'Med',
      RiskLevel.high => 'High',
      RiskLevel.veryHigh => 'V.High',
    };
  }
}
