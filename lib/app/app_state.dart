import 'package:flutter/foundation.dart';

import '../core/models/evaluation_models.dart';

enum AppLanguage { th, en }

class UserProfile {
  const UserProfile({
    this.name = '',
    this.age = '',
    this.gender = 'Male',
    this.weight = '',
    this.height = '',
    this.incomePerYear = '',
    this.avatarAsset,
  });

  final String name;
  final String age;
  final String gender;
  final String weight;
  final String height;
  final String incomePerYear;
  final String? avatarAsset;

  UserProfile copyWith({
    String? name,
    String? age,
    String? gender,
    String? weight,
    String? height,
    String? incomePerYear,
    String? avatarAsset,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      incomePerYear: incomePerYear ?? this.incomePerYear,
      avatarAsset: avatarAsset ?? this.avatarAsset,
    );
  }
}

class SooktaAppState extends ChangeNotifier {
  AppLanguage? _language;
  UserProfile _profile = const UserProfile();
  bool _setupCompleted = false;
  final List<EvaluationHistoryRecord> _history = [];
  int _nextHistoryId = 1;

  AppLanguage? get language => _language;
  UserProfile get profile => _profile;
  bool get setupCompleted => _setupCompleted;
  bool get hasLanguage => _language != null;
  List<EvaluationHistoryRecord> get history => List.unmodifiable(_history);

  void setLanguage(AppLanguage language) {
    _language = language;
    notifyListeners();
  }

  void saveProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void saveAvatarAndFinish(String avatarAsset) {
    _profile = _profile.copyWith(avatarAsset: avatarAsset);
    _setupCompleted = true;
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
  }) {
    final record = EvaluationHistoryRecord(
      id: _nextHistoryId++,
      activityName: activityName,
      dateTime: DateTime.now(),
      scoreBefore: before.userScore,
      scoreAfter: after.userScore,
      riskBefore: before.riskLevel,
      riskAfter: after.riskLevel,
      economicLoss: before.economicLoss,
      moneySaved: (before.economicLoss - after.economicLoss).clamp(0, 999999).toInt(),
      selectedSuggestions: selectedSuggestions,
      bodyPartRisks: before.bodyPartRisks,
    );
    _history.insert(0, record);
    notifyListeners();
    return record;
  }

  EvaluationHistoryRecord? historyById(int id) {
    for (final record in _history) {
      if (record.id == id) return record;
    }
    return null;
  }
}

class EvaluationHistoryRecord {
  const EvaluationHistoryRecord({
    required this.id,
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
  });

  final int id;
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
}
