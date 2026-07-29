import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/assessment_session.dart';
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

  test('keys shorter than legacy text preserve trailing recommendations', () {
    final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <String>['act_fert_split_load'],
      'selectedSuggestions': <String>[
        'Split fertilizer into smaller loads per round',
        'Reduce prolonged arm raising',
      ],
    });

    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.en),
      [
        'Split fertilizer into smaller loads per round.',
        'Reduce prolonged arm raising.',
      ],
    );
  });

  test('keys longer than legacy text preserve every keyed recommendation', () {
    final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <String>[
        'act_fert_split_load',
        'act_reduce_arm_raise',
      ],
      'selectedSuggestions': <String>[
        'Split fertilizer into smaller loads per round',
      ],
    });

    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.en),
      [
        'Split fertilizer into smaller loads per round.',
        'Reduce prolonged arm raising.',
      ],
    );
  });

  test('duplicate saved positions preserve order and multiplicity', () {
    final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <String>[
        'act_fert_split_load',
        'act_fert_split_load',
      ],
      'selectedSuggestions': <String>[
        'Split fertilizer into smaller loads per round',
      ],
    });

    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.en),
      [
        'Split fertilizer into smaller loads per round.',
        'Split fertilizer into smaller loads per round.',
      ],
    );
  });

  test('mixed unknown and retired keys resolve each saved position in order',
      () {
    final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <String>[
        'retired_selection_key',
        'unknown_selection_key',
      ],
      'selectedSuggestions': <String>[
        'Reduce prolonged arm raising',
        'คำแนะนำเก่าที่ไม่รู้จัก',
        'Split fertilizer into smaller loads per round',
      ],
    });

    expect(
      record.localizedSelectedSuggestions(RecommendationLanguage.en),
      [
        'Reduce prolonged arm raising.',
        'A saved recommendation could not be matched to the current approved catalog.',
        'Split fertilizer into smaller loads per round.',
      ],
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

  test('malformed selectedSuggestionKeys defaults to an empty list', () {
    for (final malformedValue in <Object?>[
      'act_fert_split_load',
      <String, String>{'key': 'act_fert_split_load'},
    ]) {
      final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
        ..._recordJson(),
        'selectedSuggestionKeys': malformedValue,
        'selectedSuggestions': <String>[
          'Split fertilizer into smaller loads per round',
        ],
      });

      expect(record.selectedSuggestionKeys, isEmpty);
      expect(
        record.localizedSelectedSuggestions(RecommendationLanguage.en),
        ['Split fertilizer into smaller loads per round.'],
      );
    }
  });

  test('mixed-type saved lists are rejected without shifting positions', () {
    final mixedKeys = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <Object?>[
        'act_reduce_arm_raise',
        7,
        'act_fert_split_load',
      ],
      'selectedSuggestions': <String>[
        'Reduce prolonged arm raising',
        'Split fertilizer into smaller loads per round',
      ],
    });
    final mixedLegacy = EvaluationHistoryRecord.fromJson(<String, Object?>{
      ..._recordJson(),
      'selectedSuggestionKeys': <String>[
        'act_reduce_arm_raise',
        'act_fert_split_load',
      ],
      'selectedSuggestions': <Object?>[
        'Reduce prolonged arm raising',
        <String, String>{'text': 'invalid'},
        'Split fertilizer into smaller loads per round',
      ],
    });

    expect(mixedKeys.selectedSuggestionKeys, isEmpty);
    expect(
      mixedKeys.localizedSelectedSuggestions(RecommendationLanguage.en),
      [
        'Reduce prolonged arm raising.',
        'Split fertilizer into smaller loads per round.',
      ],
    );
    expect(mixedLegacy.selectedSuggestions, isEmpty);
    expect(
      mixedLegacy.localizedSelectedSuggestions(RecommendationLanguage.en),
      [
        'Reduce prolonged arm raising.',
        'Split fertilizer into smaller loads per round.',
      ],
    );
  });

  test('scalar and map legacy suggestion lists default to empty', () {
    for (final malformed in <Object?>[
      'Reduce prolonged arm raising',
      <String, String>{'text': 'Reduce prolonged arm raising'},
    ]) {
      final record = EvaluationHistoryRecord.fromJson(<String, Object?>{
        ..._recordJson(),
        'selectedSuggestions': malformed,
      });

      expect(record.selectedSuggestions, isEmpty);
      expect(
        record.localizedSelectedSuggestions(RecommendationLanguage.en),
        isEmpty,
      );
    }
  });

  test('typed and exact legacy activity names localize in either language', () {
    final typedThaiRecord = EvaluationHistoryRecord.fromJson(
      <String, Object?>{
        ..._recordJson(),
        'activity': SooktaActivity.fertilizing.name,
        'activityName': 'การใส่ปุ๋ย',
      },
    );
    final legacyThaiRecord = EvaluationHistoryRecord.fromJson(
      <String, Object?>{
        ..._recordJson(),
        'activityName': 'การตัดแต่งกิ่ง',
      },
    );
    final legacyEnglishRecord = EvaluationHistoryRecord.fromJson(
      <String, Object?>{
        ..._recordJson(),
        'activityName': 'On-farm Transport',
      },
    );
    final unknownRecord = EvaluationHistoryRecord.fromJson(
      <String, Object?>{
        ..._recordJson(),
        'activityName': 'ค่าภายในที่ไม่รู้จัก',
      },
    );

    expect(typedThaiRecord.localizedActivityName(thai: false), 'Fertilizing');
    expect(legacyThaiRecord.localizedActivityName(thai: false), 'Pruning');
    expect(
      legacyEnglishRecord.localizedActivityName(thai: true),
      'การขนย้ายผลผลิต',
    );
    expect(unknownRecord.localizedActivityName(thai: false), 'Activity');
    expect(unknownRecord.localizedActivityName(thai: true), 'กิจกรรม');
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
