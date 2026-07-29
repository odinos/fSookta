import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/recommendations/recommendation_catalog_models.dart';

void main() {
  test('old stored recommendation text resolves to approved English', () {
    final oldRecord = EvaluationHistoryRecord.fromJson(<String, Object?>{
      'id': 1,
      'activityName': 'การใส่ปุ๋ย',
      'dateTime': '2026-07-29T10:00:00+07:00',
      'scoreBefore': 8,
      'scoreAfter': 6,
      'riskBefore': 'high',
      'riskAfter': 'medium',
      'economicLoss': 1000,
      'moneySaved': 280,
      'selectedSuggestions': <String>['ลดน้ำหนักปุ๋ยต่อครั้ง'],
      'bodyPartRisks': <String, String>{'trunk': 'high'},
    });

    final texts = oldRecord.localizedSelectedSuggestions(
      RecommendationLanguage.en,
    );

    expect(texts, isNotEmpty);
    expect(texts.every((text) => !RegExp(r'[ก-๙]').hasMatch(text)), isTrue);
  });

  test('new stored keys resolve to approved Thai and English', () {
    final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <String>['act_fert_split_load'],
      'selectedSuggestions': <String>['ข้อความเก่าที่ไม่ควรใช้แสดงผล'],
    });

    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.th),
      ['แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ'],
    );
    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.en),
      ['Split fertilizer into smaller loads per round.'],
    );
  });

  test('unresolved stored key tries its exact legacy alias before fallback',
      () {
    final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <String>['retired_selection_key'],
      'selectedSuggestions': <String>[
        'Split fertilizer into smaller loads per round',
      ],
    });

    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.en),
      ['Split fertilizer into smaller loads per round.'],
    );
  });

  test('old Thai and English aliases resolve in either language', () {
    final thaiAliasRecord = EvaluationHistoryRecord.fromJson(
      <String, Object?>{
        ..._recordJson(),
        'selectedSuggestions': <String>[
          'แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ',
        ],
      },
    );
    final englishAliasRecord = EvaluationHistoryRecord.fromJson(
      <String, Object?>{
        ..._recordJson(),
        'selectedSuggestions': <String>[
          'Split fertilizer into smaller loads per round',
        ],
      },
    );

    expect(
      thaiAliasRecord.localizedSelectedSuggestions(RecommendationLanguage.en),
      ['Split fertilizer into smaller loads per round.'],
    );
    expect(
      englishAliasRecord.localizedSelectedSuggestions(
        RecommendationLanguage.th,
      ),
      ['แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ'],
    );
  });

  test('unknown legacy text uses approved fallback in both languages', () {
    final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestions': <String>['คำแนะนำเก่าที่ไม่รู้จัก'],
    });

    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.th),
      ['ไม่สามารถจับคู่คำแนะนำเดิมกับรายการปัจจุบันได้'],
    );
    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.en),
      [
        'A saved recommendation could not be matched to the current approved catalog.',
      ],
    );
  });

  test('selection keys round-trip while old JSON defaults to no keys', () {
    final oldRecord = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestions': <String>[
        'Split fertilizer into smaller loads per round',
      ],
    });
    final keyedRecord = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <String>['act_fert_split_load'],
      'selectedSuggestions': <String>[
        'แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ',
      ],
    });

    expect(oldRecord.selectedSuggestionKeys, isEmpty);
    expect(
      EvaluationHistoryRecord.fromJson(keyedRecord.toJson())
          .selectedSuggestionKeys,
      ['act_fert_split_load'],
    );
    expect(
      EvaluationHistoryRecord.fromJson(keyedRecord.toJson())
          .selectedSuggestions,
      ['แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ'],
    );
  });
}

Map<String, Object?> _recordJson() => <String, Object?>{
      'id': 1,
      'activityName': 'Fertilizing',
      'dateTime': '2026-07-29T10:00:00+07:00',
      'scoreBefore': 8,
      'scoreAfter': 6,
      'riskBefore': 'high',
      'riskAfter': 'medium',
      'economicLoss': 1000,
      'moneySaved': 280,
      'bodyPartRisks': <String, String>{'trunk': 'high'},
    };
