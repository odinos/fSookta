import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/assessment_session.dart';
import '../core/models/evaluation_models.dart';

enum AppLanguage { th, en }

class UserProfile {
  const UserProfile({
    this.farmerId = '',
    this.name = '',
    this.role = '',
    this.location = '',
    this.age = '',
    this.gender = 'Male',
    this.weight = '',
    this.height = '',
    this.incomePerYear = '',
    this.avatarAsset,
  });

  final String farmerId;
  final String name;
  final String role;
  final String location;
  final String age;
  final String gender;
  final String weight;
  final String height;
  final String incomePerYear;
  final String? avatarAsset;

  UserProfile copyWith({
    String? farmerId,
    String? name,
    String? role,
    String? location,
    String? age,
    String? gender,
    String? weight,
    String? height,
    String? incomePerYear,
    String? avatarAsset,
  }) {
    return UserProfile(
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      role: role ?? this.role,
      location: location ?? this.location,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      incomePerYear: incomePerYear ?? this.incomePerYear,
      avatarAsset: avatarAsset ?? this.avatarAsset,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'farmerId': farmerId,
      'name': name,
      'role': role,
      'location': location,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'incomePerYear': incomePerYear,
      'avatarAsset': avatarAsset,
    };
  }

  factory UserProfile.fromJson(Map<String, Object?> json) {
    return UserProfile(
      farmerId: json['farmerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      location: json['location'] as String? ?? '',
      age: json['age'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Male',
      weight: json['weight'] as String? ?? '',
      height: json['height'] as String? ?? '',
      incomePerYear: json['incomePerYear'] as String? ?? '',
      avatarAsset: json['avatarAsset'] as String?,
    );
  }
}

class SooktaAppState extends ChangeNotifier {
  static const _languageKey = 'sookta.language';
  static const _profileKey = 'sookta.profile';
  static const _setupCompletedKey = 'sookta.setupCompleted';
  static const _historyKey = 'sookta.history';
  static const _nextHistoryIdKey = 'sookta.nextHistoryId';

  AppLanguage? _language;
  UserProfile _profile = const UserProfile();
  bool _setupCompleted = false;
  final List<EvaluationHistoryRecord> _history = [];
  int _nextHistoryId = 1;
  bool _hydrated = false;
  Future<void>? _restoreFuture;

  AppLanguage? get language => _language;
  UserProfile get profile => _profile;
  bool get setupCompleted => _setupCompleted;
  bool get hydrated => _hydrated;
  bool get hasLanguage => _language != null;
  List<EvaluationHistoryRecord> get history => List.unmodifiable(_history);

  Future<void> restore() {
    return _restoreFuture ??= _restore();
  }

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final languageName = preferences.getString(_languageKey);
      if (languageName != null) {
        _language = AppLanguage.values.cast<AppLanguage?>().firstWhere(
              (language) => language?.name == languageName,
              orElse: () => null,
            );
      }

      final profileJson = preferences.getString(_profileKey);
      if (profileJson != null) {
        final decoded = jsonDecode(profileJson);
        if (decoded is Map<String, Object?>) {
          _profile = UserProfile.fromJson(decoded);
        } else if (decoded is Map) {
          _profile = UserProfile.fromJson(Map<String, Object?>.from(decoded));
        }
      }

      _setupCompleted = preferences.getBool(_setupCompletedKey) ?? false;
      _nextHistoryId = preferences.getInt(_nextHistoryIdKey) ?? 1;

      final historyJson = preferences.getString(_historyKey);
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson);
        if (decoded is List) {
          _history
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((item) => EvaluationHistoryRecord.fromJson(
                        Map<String, Object?>.from(item),
                      )),
            );
        }
      }

      if (_history.isNotEmpty) {
        final maxId =
            _history.map((record) => record.id).reduce((a, b) => a > b ? a : b);
        if (_nextHistoryId <= maxId) _nextHistoryId = maxId + 1;
      }
    } catch (_) {
      _language = null;
      _profile = const UserProfile();
      _setupCompleted = false;
      _history.clear();
      _nextHistoryId = 1;
    } finally {
      _hydrated = true;
      notifyListeners();
    }
  }

  void setLanguage(AppLanguage language) {
    _language = language;
    _persistSoon();
    notifyListeners();
  }

  void saveProfile(UserProfile profile) {
    _profile = profile;
    _persistSoon();
    notifyListeners();
  }

  void saveAvatarAndFinish(String avatarAsset) {
    _profile = _profile.copyWith(avatarAsset: avatarAsset);
    _setupCompleted = true;
    _persistSoon();
    notifyListeners();
  }

  int get dailyIncome {
    final yearlyIncome = double.tryParse(_profile.incomePerYear);
    if (yearlyIncome != null && yearlyIncome > 0) {
      return (yearlyIncome / 365).round();
    }
    return 350;
  }

  EvaluationHistoryRecord saveEvaluation({
    required String activityName,
    required ErgoResult before,
    required ErgoResult after,
    required List<String> selectedSuggestions,
    SooktaActivity? activity,
    AssessmentBreakdown? assessmentBreakdown,
  }) {
    final record = EvaluationHistoryRecord(
      id: _nextHistoryId++,
      activity: activity,
      activityName: activityName,
      dateTime: DateTime.now(),
      scoreBefore: before.userScore,
      scoreAfter: after.userScore,
      riskBefore: before.riskLevel,
      riskAfter: after.riskLevel,
      economicLoss: before.economicLoss,
      moneySaved:
          (before.economicLoss - after.economicLoss).clamp(0, 999999).toInt(),
      selectedSuggestions: selectedSuggestions,
      bodyPartRisks: before.bodyPartRisks,
      aiRiskPercent: before.aiRiskAlert == null
          ? null
          : (before.aiRiskAlert!.probability * 100).round(),
      aiAlertLevel: before.aiRiskAlert?.level,
      aiModelSource: before.aiRiskAlert?.modelSource,
      assessmentBreakdown: assessmentBreakdown,
    );
    _history.insert(0, record);
    _persistSoon();
    notifyListeners();
    return record;
  }

  EvaluationHistoryRecord? historyById(int id) {
    for (final record in _history) {
      if (record.id == id) return record;
    }
    return null;
  }

  void _persistSoon() {
    if (!_hydrated) return;
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final language = _language;
    if (language == null) {
      await preferences.remove(_languageKey);
    } else {
      await preferences.setString(_languageKey, language.name);
    }

    await preferences.setString(_profileKey, jsonEncode(_profile.toJson()));
    await preferences.setBool(_setupCompletedKey, _setupCompleted);
    await preferences.setInt(_nextHistoryIdKey, _nextHistoryId);
    await preferences.setString(
      _historyKey,
      jsonEncode(_history.map((record) => record.toJson()).toList()),
    );
  }
}

class EvaluationHistoryRecord {
  const EvaluationHistoryRecord({
    required this.id,
    this.activity,
    required this.activityName,
    required this.dateTime,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.riskBefore,
    required this.riskAfter,
    required this.economicLoss,
    required this.moneySaved,
    required this.selectedSuggestions,
    required this.bodyPartRisks,
    this.aiRiskPercent,
    this.aiAlertLevel,
    this.aiModelSource,
    this.assessmentBreakdown,
  });

  final int id;
  final SooktaActivity? activity;
  final String activityName;
  final DateTime dateTime;
  final int scoreBefore;
  final int scoreAfter;
  final RiskLevel riskBefore;
  final RiskLevel riskAfter;
  final int economicLoss;
  final int moneySaved;
  final List<String> selectedSuggestions;
  final Map<BodyPart, RiskLevel> bodyPartRisks;
  final int? aiRiskPercent;
  final AiAlertLevel? aiAlertLevel;
  final String? aiModelSource;
  final AssessmentBreakdown? assessmentBreakdown;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'activity': activity?.name,
      'activityName': activityName,
      'dateTime': dateTime.toIso8601String(),
      'scoreBefore': scoreBefore,
      'scoreAfter': scoreAfter,
      'riskBefore': riskBefore.name,
      'riskAfter': riskAfter.name,
      'economicLoss': economicLoss,
      'moneySaved': moneySaved,
      'selectedSuggestions': selectedSuggestions,
      'bodyPartRisks': bodyPartRisks.map(
        (part, risk) => MapEntry(part.name, risk.name),
      ),
      'aiRiskPercent': aiRiskPercent,
      'aiAlertLevel': aiAlertLevel?.name,
      'aiModelSource': aiModelSource,
      'assessmentBreakdown': assessmentBreakdown?.toJson(),
    };
  }

  factory EvaluationHistoryRecord.fromJson(Map<String, Object?> json) {
    return EvaluationHistoryRecord(
      id: json['id'] as int? ?? 0,
      activity: _activityFromName(json['activity'] as String?),
      activityName: json['activityName'] as String? ?? '',
      dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ??
          DateTime.now(),
      scoreBefore: json['scoreBefore'] as int? ?? 0,
      scoreAfter: json['scoreAfter'] as int? ?? 0,
      riskBefore: _riskFromName(json['riskBefore'] as String?),
      riskAfter: _riskFromName(json['riskAfter'] as String?),
      economicLoss: json['economicLoss'] as int? ?? 0,
      moneySaved: json['moneySaved'] as int? ?? 0,
      selectedSuggestions: (json['selectedSuggestions'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      bodyPartRisks: _bodyRisksFromJson(json['bodyPartRisks']),
      aiRiskPercent: json['aiRiskPercent'] as int?,
      aiAlertLevel: _aiAlertFromName(json['aiAlertLevel'] as String?),
      aiModelSource: json['aiModelSource'] as String?,
      assessmentBreakdown: _assessmentBreakdownFromJson(
        json['assessmentBreakdown'],
      ),
    );
  }

  static AssessmentBreakdown? _assessmentBreakdownFromJson(Object? raw) {
    if (raw is! Map) return null;
    return AssessmentBreakdown.fromJson(Map<String, Object?>.from(raw));
  }

  static SooktaActivity? _activityFromName(String? name) {
    if (name == null) return null;
    return SooktaActivity.values.cast<SooktaActivity?>().firstWhere(
          (activity) => activity?.name == name,
          orElse: () => null,
        );
  }

  static RiskLevel _riskFromName(String? name) {
    return RiskLevel.values.firstWhere(
      (risk) => risk.name == name,
      orElse: () => RiskLevel.low,
    );
  }

  static AiAlertLevel? _aiAlertFromName(String? name) {
    if (name == null) return null;
    return AiAlertLevel.values.cast<AiAlertLevel?>().firstWhere(
          (level) => level?.name == name,
          orElse: () => null,
        );
  }

  static Map<BodyPart, RiskLevel> _bodyRisksFromJson(Object? raw) {
    if (raw is! Map) return const {};
    final result = <BodyPart, RiskLevel>{};
    for (final entry in raw.entries) {
      final bodyPart = BodyPart.values.cast<BodyPart?>().firstWhere(
            (part) => part?.name == entry.key,
            orElse: () => null,
          );
      if (bodyPart != null) {
        result[bodyPart] = _riskFromName(entry.value as String?);
      }
    }
    return result;
  }
}
