import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'build_info.dart';
import '../core/models/assessment_session.dart';
import '../core/models/evaluation_models.dart';
import '../core/recommendations/recommendation_catalog_models.dart';
import '../core/services/economic_impact_service.dart';
import '../core/services/local_image_store.dart';
import '../core/services/recommendation_catalog_service.dart';

enum AppLanguage { th, en }

class UserProfile {
  const UserProfile({
    this.profileId = '',
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

  final String profileId;
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

  double? get weightKg => _parseProfileNumber(weight);

  double? get heightCm => _parseProfileNumber(height);

  double? get bmi {
    final kg = weightKg;
    final cm = heightCm;
    if (kg == null || cm == null || kg <= 0 || cm <= 0) return null;
    final meters = cm / 100;
    return kg / (meters * meters);
  }

  String get bmiCategoryKey {
    final value = bmi;
    if (value == null) return 'unknown';
    if (value < 18.5) return 'underweight';
    if (value < 23) return 'normal';
    return 'overweight';
  }

  String bmiCategoryLabel({required bool thai}) {
    return switch (bmiCategoryKey) {
      'underweight' => thai ? 'น้ำหนักต่ำกว่าเกณฑ์' : 'Underweight',
      'normal' => thai ? 'น้ำหนักปกติ' : 'Normal weight',
      'overweight' => thai ? 'น้ำหนักมากกว่าเกณฑ์' : 'Above Asian BMI range',
      _ => thai ? 'ยังไม่มีข้อมูล BMI' : 'BMI unavailable',
    };
  }

  String bmiDisplay({required bool thai}) {
    final value = bmi;
    if (value == null) return '-';
    return '${value.toStringAsFixed(1)} (${bmiCategoryLabel(thai: thai)})';
  }

  UserProfile copyWith({
    String? profileId,
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
      profileId: profileId ?? this.profileId,
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
      'profileId': profileId,
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
      profileId: json['profileId'] as String? ?? '',
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

double? _parseProfileNumber(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

class SooktaAppState extends ChangeNotifier {
  static const _languageKey = 'sookta.language';
  static const _profileKey = 'sookta.profile';
  static const _farmersKey = 'sookta.farmers';
  static const _activeProfileIdKey = 'sookta.activeProfileId';
  static const _setupCompletedKey = 'sookta.setupCompleted';
  static const _historyKey = 'sookta.history';
  static const _nextHistoryIdKey = 'sookta.nextHistoryId';
  static const _evaluationDraftKey = 'sookta.evaluationDraft';
  static const _evaluationDraftsKey = 'sookta.evaluationDrafts';
  static const _dataSchemaVersionKey = 'sookta.dataSchemaVersion';
  static const _latestBackupKey = 'sookta.latestBackup';
  static const _currentDataSchemaVersion = 2;

  AppLanguage? _language;
  UserProfile _profile = const UserProfile();
  final List<UserProfile> _farmers = [];
  String? _activeProfileId;
  bool _setupCompleted = false;
  final List<EvaluationHistoryRecord> _history = [];
  final Map<String, EvaluationDraft> _evaluationDrafts = {};
  EvaluationDraft? _evaluationDraft;
  int _nextHistoryId = 1;
  bool _hydrated = false;
  Future<void>? _restoreFuture;

  AppLanguage? get language => _language;
  UserProfile get profile => _profile;
  List<UserProfile> get farmers => List.unmodifiable(_farmers);
  String? get activeProfileId => _activeProfileId;
  bool get setupCompleted => _setupCompleted;
  bool get hydrated => _hydrated;
  bool get hasLanguage => _language != null;
  List<EvaluationHistoryRecord> get history => List.unmodifiable(_history);
  EvaluationDraft? get evaluationDraft =>
      evaluationDraftForProfile(_profile.profileId) ?? _evaluationDraft;
  List<EvaluationDraft> get evaluationDrafts {
    final drafts = _evaluationDrafts.values.toList(growable: false);
    drafts.sort((a, b) {
      final aTime = a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return drafts;
  }

  Future<void> restore() {
    return _restoreFuture ??= _restore();
  }

  Future<void> _restore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      String? adoptedLegacyProfileId;
      var adoptedLegacyDraft = false;
      await _backupBeforeSchemaMigration(preferences);
      final languageName = preferences.getString(_languageKey);
      if (languageName != null) {
        _language = AppLanguage.values.cast<AppLanguage?>().firstWhere(
              (language) => language?.name == languageName,
              orElse: () => null,
            );
      }

      final profileJson = preferences.getString(_profileKey);
      UserProfile? legacyProfile;
      if (profileJson != null) {
        final decoded = jsonDecode(profileJson);
        if (decoded is Map<String, Object?>) {
          legacyProfile = UserProfile.fromJson(decoded);
        } else if (decoded is Map) {
          legacyProfile =
              UserProfile.fromJson(Map<String, Object?>.from(decoded));
        }
      }

      _setupCompleted = preferences.getBool(_setupCompletedKey) ?? false;
      _nextHistoryId = preferences.getInt(_nextHistoryIdKey) ?? 1;

      final farmersJson = preferences.getString(_farmersKey);
      if (farmersJson != null) {
        final decoded = jsonDecode(farmersJson);
        if (decoded is List) {
          _farmers
            ..clear()
            ..addAll(decoded.whereType<Map>().map(
                  (item) => _ensureProfileId(
                    UserProfile.fromJson(Map<String, Object?>.from(item)),
                  ),
                ));
        }
      }
      if (_farmers.isEmpty && legacyProfile != null) {
        final normalized = _ensureProfileId(legacyProfile);
        _farmers.add(normalized);
        if (legacyProfile.profileId.isEmpty) {
          adoptedLegacyProfileId = normalized.profileId;
        }
      }
      _activeProfileId = preferences.getString(_activeProfileIdKey);
      if (_farmers.isNotEmpty) {
        final active = _farmers.firstWhere(
          (farmer) => farmer.profileId == _activeProfileId,
          orElse: () => _farmers.first,
        );
        _profile = active;
        _activeProfileId = active.profileId;
      } else {
        _profile = legacyProfile ?? const UserProfile();
      }

      final historyJson = preferences.getString(_historyKey);
      if (historyJson != null) {
        final decoded = jsonDecode(historyJson);
        if (decoded is List) {
          final restoredHistory = <EvaluationHistoryRecord>[];
          for (final item in decoded.whereType<Map>()) {
            try {
              restoredHistory.add(
                EvaluationHistoryRecord.fromJson(
                  Map<String, Object?>.from(item),
                ),
              );
            } on Object {
              // A single damaged saved record must not discard valid profiles,
              // drafts, or other history records.
            }
          }
          _history
            ..clear()
            ..addAll(restoredHistory);
        }
      }

      if (_history.isNotEmpty) {
        final maxId =
            _history.map((record) => record.id).reduce((a, b) => a > b ? a : b);
        if (_nextHistoryId <= maxId) _nextHistoryId = maxId + 1;
      }

      final draftJson = preferences.getString(_evaluationDraftKey);
      EvaluationDraft? legacyDraft;
      if (draftJson != null) {
        final decoded = jsonDecode(draftJson);
        if (decoded is Map) {
          legacyDraft = EvaluationDraft.fromJson(
            Map<String, Object?>.from(decoded),
          );
        }
      }

      final draftsJson = preferences.getString(_evaluationDraftsKey);
      if (draftsJson != null) {
        final decoded = jsonDecode(draftsJson);
        final draftMaps = decoded is List
            ? decoded
            : decoded is Map
                ? decoded.values
                : const Iterable<Object?>.empty();
        for (final item in draftMaps.whereType<Map>()) {
          var draft = EvaluationDraft.fromJson(
            Map<String, Object?>.from(item),
          );
          final profileId = adoptedLegacyProfileId;
          if (profileId != null &&
              (draft.farmerProfileId ?? '').trim().isEmpty) {
            draft = draft.copyWith(farmerProfileId: profileId);
            adoptedLegacyDraft = true;
          }
          _evaluationDrafts[_draftKey(draft)] = draft;
        }
      }
      if (legacyDraft != null) {
        final profileId = adoptedLegacyProfileId;
        if (profileId != null &&
            (legacyDraft.farmerProfileId ?? '').trim().isEmpty) {
          legacyDraft = legacyDraft.copyWith(farmerProfileId: profileId);
          adoptedLegacyDraft = true;
        }
        final enriched = _withActiveDraftMetadata(legacyDraft);
        _evaluationDrafts.putIfAbsent(_draftKey(enriched), () => enriched);
      }
      _evaluationDraft =
          evaluationDraftForProfile(_profile.profileId) ?? _latestDraftOrNull();
      if (adoptedLegacyDraft) {
        await _persist();
      } else {
        await preferences.setInt(
          _dataSchemaVersionKey,
          _currentDataSchemaVersion,
        );
      }
    } catch (_) {
      _language = null;
      _profile = const UserProfile();
      _farmers.clear();
      _activeProfileId = null;
      _setupCompleted = false;
      _history.clear();
      _evaluationDrafts.clear();
      _evaluationDraft = null;
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
    final profileId = profile.profileId.isNotEmpty
        ? profile.profileId
        : (_activeProfileId ?? _newProfileId());
    final updated = profile.copyWith(profileId: profileId);
    final index =
        _farmers.indexWhere((farmer) => farmer.profileId == profileId);
    if (index == -1) {
      _farmers.add(updated);
    } else {
      _farmers[index] = updated;
    }
    _profile = updated;
    _activeProfileId = profileId;
    _persistSoon();
    notifyListeners();
  }

  void saveAvatarAndFinish(String avatarAsset) {
    saveProfile(_profile.copyWith(avatarAsset: avatarAsset));
    _setupCompleted = true;
    _persistSoon();
    notifyListeners();
  }

  void addFarmer(UserProfile profile) {
    final farmer = _ensureProfileId(profile);
    _farmers.add(farmer);
    _profile = farmer;
    _activeProfileId = farmer.profileId;
    _setupCompleted = true;
    _persistSoon();
    notifyListeners();
  }

  void updateFarmer(UserProfile profile) {
    final updated = _ensureProfileId(profile);
    final index =
        _farmers.indexWhere((farmer) => farmer.profileId == updated.profileId);
    if (index == -1) {
      _farmers.add(updated);
    } else {
      _farmers[index] = updated;
    }
    if (_activeProfileId == updated.profileId) _profile = updated;
    _persistSoon();
    notifyListeners();
  }

  void deleteFarmer(String profileId) {
    _farmers.removeWhere((farmer) => farmer.profileId == profileId);
    if (_activeProfileId == profileId) {
      final next = _farmers.isEmpty ? const UserProfile() : _farmers.first;
      _profile = next;
      _activeProfileId = next.profileId.isEmpty ? null : next.profileId;
    }
    _persistSoon();
    notifyListeners();
  }

  void selectFarmer(String profileId) {
    final farmer = _farmers.cast<UserProfile?>().firstWhere(
          (item) => item?.profileId == profileId,
          orElse: () => null,
        );
    if (farmer == null) return;
    _profile = farmer;
    _activeProfileId = farmer.profileId;
    _persistSoon();
    notifyListeners();
  }

  List<EvaluationHistoryRecord> historyForFarmer(String profileId) {
    return _history
        .where((record) => record.farmerProfileId == profileId)
        .toList(growable: false);
  }

  EvaluationDraft? evaluationDraftForProfile(
    String profileId, {
    SooktaActivity? activity,
  }) {
    final drafts = evaluationDrafts.where((draft) {
      final sameProfile = profileId.isEmpty
          ? draft.farmerProfileId == null || draft.farmerProfileId!.isEmpty
          : draft.farmerProfileId == profileId;
      final sameActivity = activity == null || draft.activity == activity;
      return sameProfile && sameActivity;
    }).toList(growable: false);
    if (drafts.isEmpty) return null;
    return drafts.first;
  }

  Future<void> saveEvaluationDraft(EvaluationDraft draft) async {
    final persistentImagePaths = <String>[];
    for (final path in draft.selectedImagePaths) {
      persistentImagePaths.add(
        await LocalImageStore.saveImageFile(
          path,
          prefix: 'sookta_evaluation_media',
        ),
      );
    }
    final enriched = _withActiveDraftMetadata(draft).copyWith(
      selectedImagePaths: persistentImagePaths,
      savedAt: DateTime.now(),
    );
    _evaluationDrafts[_draftKey(enriched)] = enriched;
    _evaluationDraft = enriched;
    await _persist();
    notifyListeners();
  }

  Future<void> clearEvaluationDraft([EvaluationDraft? draft]) async {
    final target = draft ?? evaluationDraft;
    if (target == null) return;
    _evaluationDrafts.remove(_draftKey(target));
    _evaluationDraft = _latestDraftOrNull();
    await _persist();
    notifyListeners();
  }

  UserProfile profileForRecord(EvaluationHistoryRecord record) {
    for (final farmer in _farmers) {
      if (farmer.profileId == record.farmerProfileId) return farmer;
    }
    return UserProfile(
      profileId: record.farmerProfileId ?? '',
      farmerId: record.farmerId ?? '',
      name: record.farmerName ?? '',
      role: record.farmerRole ?? '',
      location: record.farmerLocation ?? '',
      age: record.farmerAge ?? '',
      gender: record.farmerGender ?? 'Male',
      weight: record.farmerWeight ?? '',
      height: record.farmerHeight ?? '',
    );
  }

  int get dailyIncome {
    final yearlyIncome = double.tryParse(_profile.incomePerYear);
    if (yearlyIncome != null && yearlyIncome > 0) {
      return (yearlyIncome / 365).round();
    }
    return 350;
  }

  Future<void> ensureResearchCaptureData() async {
    setLanguage(AppLanguage.th);
    if (_profile.profileId.isEmpty) {
      saveProfile(
        const UserProfile(
          profileId: 'capture-farmer',
          farmerId: 'FSK-944631',
          name: 'ddd',
          role: 'ชาวสวน',
          age: '45',
          gender: 'female',
          weight: '55',
          height: '158',
          incomePerYear: '120000',
        ),
      );
      _setupCompleted = true;
    }

    final profileRecords = historyForFarmer(_profile.profileId);
    if (profileRecords.length >= 7) return;

    const beforeScores = [7, 8, 8, 9, 9, 10, 10];
    const isoScores = [7, 8, 8, 8, 9, 9, 9];
    final missing = 7 - profileRecords.length;
    for (var offset = 0; offset < missing; offset++) {
      final index = profileRecords.length + offset;
      final scoreIndex = index.clamp(0, beforeScores.length - 1);
      final beforeScore = beforeScores[scoreIndex];
      final isoScore = isoScores[scoreIndex];
      const afterScore = 4;
      final before = _captureResult(
        score: beforeScore,
        riskLevel: RiskLevel.high,
        economicLoss: 18000 + index * 900,
        suggestionKey: 'sugg_reba_high',
      );
      final after = _captureResult(
        score: afterScore,
        riskLevel: RiskLevel.medium,
        economicLoss: 7200,
        suggestionKey: 'sugg_reba_med',
      );

      await saveEvaluation(
        activityName: 'การใส่ปุ๋ย',
        activity: SooktaActivity.fertilizing,
        before: before,
        after: after,
        selectedSuggestionKeys: const [
          'act_iso_keep_load_close',
          'act_fert_split_load',
        ],
        selectedSuggestions: const [
          'ยกถังปุ๋ยให้ใกล้ตัวและลดการก้ม',
          'แบ่งน้ำหนักปุ๋ยต่อรอบให้น้อยลง',
        ],
        assessmentBreakdown: _captureBreakdown(
          rebaScore: beforeScore,
          isoScore: isoScore,
          riskLevel: RiskLevel.high,
          loadWeight: 14.0 + index,
          liftFrequency: (18 + index * 2) / 60,
        ),
        afterAssessmentBreakdown: _captureBreakdown(
          rebaScore: afterScore,
          isoScore: 4,
          riskLevel: RiskLevel.medium,
          loadWeight: 8,
          liftFrequency: 10 / 60,
        ),
      );
    }
    _setupCompleted = true;
    _persistSoon();
    notifyListeners();
  }

  ErgoResult _captureResult({
    required int score,
    required RiskLevel riskLevel,
    required int economicLoss,
    required String suggestionKey,
  }) {
    return ErgoResult(
      riskLevel: riskLevel,
      techScore: score.toDouble(),
      userScore: score,
      userScoreColor: riskLevel.colorHex,
      limitValue: 9,
      suggestionKey: suggestionKey,
      economicLoss: economicLoss,
      bodyPartRisks: const {
        BodyPart.trunk: RiskLevel.high,
        BodyPart.neck: RiskLevel.medium,
        BodyPart.arms: RiskLevel.medium,
        BodyPart.wrists: RiskLevel.medium,
        BodyPart.legs: RiskLevel.low,
      },
    );
  }

  AssessmentBreakdown _captureBreakdown({
    required int rebaScore,
    required int isoScore,
    required RiskLevel riskLevel,
    required double loadWeight,
    required double liftFrequency,
  }) {
    final reba = _captureResult(
      score: rebaScore,
      riskLevel: riskLevel,
      economicLoss: 0,
      suggestionKey: 'sugg_reba_high',
    );
    final iso = _captureResult(
      score: isoScore,
      riskLevel: riskLevel,
      economicLoss: 0,
      suggestionKey: 'sugg_iso_lift_high',
    );
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
      rebaResult: reba,
      ergoInput: ErgoInputData(
        jobType: JobType.lifting,
        gender: 'female',
        dailyIncome: 350,
        toolId: 'fertilizer_bag_10_15kg',
        toolLabelTh: 'ถุงปุ๋ย (10-15 กก.)',
        toolLabelEn: 'Fertilizer bag (10-15 kg)',
        toolWeightKg: loadWeight,
        toolWeightBandCode: 3,
        loadWeight: loadWeight,
        horizontalDist: 40,
        verticalHeight: 60,
        liftFrequency: liftFrequency,
        durationHours: 2,
        workDaysPerWeek: 4,
        transportDistance: 5,
      ),
      isoMethod: AssessmentMethod.iso11228Lifting,
      isoResult: iso,
    );
  }

  Future<EvaluationHistoryRecord> saveEvaluation({
    required String activityName,
    required ErgoResult before,
    required ErgoResult after,
    required List<String> selectedSuggestionKeys,
    required List<String> selectedSuggestions,
    SooktaActivity? activity,
    AssessmentBreakdown? assessmentBreakdown,
    AssessmentBreakdown? afterAssessmentBreakdown,
  }) async {
    if (!_hydrated && _restoreFuture != null) {
      await restore();
    }
    final record = _createEvaluationRecord(
      activityName: activityName,
      before: before,
      after: after,
      selectedSuggestionKeys: selectedSuggestionKeys,
      selectedSuggestions: selectedSuggestions,
      activity: activity,
      assessmentBreakdown: assessmentBreakdown,
      afterAssessmentBreakdown: afterAssessmentBreakdown,
    );
    final draftBeforeSave = _evaluationDraft;
    _history.insert(0, record);
    if (draftBeforeSave != null) {
      _evaluationDrafts.remove(_draftKey(draftBeforeSave));
    }
    _evaluationDraft = _latestDraftOrNull();
    try {
      await _persist();
    } catch (_) {
      _history.removeWhere((item) => item.id == record.id);
      if (draftBeforeSave != null) {
        _evaluationDrafts[_draftKey(draftBeforeSave)] = draftBeforeSave;
      }
      _evaluationDraft = draftBeforeSave;
      if (_nextHistoryId == record.id + 1) _nextHistoryId = record.id;
      rethrow;
    }
    notifyListeners();
    return record;
  }

  EvaluationHistoryRecord _createEvaluationRecord({
    required String activityName,
    required ErgoResult before,
    required ErgoResult after,
    required List<String> selectedSuggestionKeys,
    required List<String> selectedSuggestions,
    SooktaActivity? activity,
    AssessmentBreakdown? assessmentBreakdown,
    AssessmentBreakdown? afterAssessmentBreakdown,
  }) {
    final recordId = _nextHistoryId++;
    final dateTime = DateTime.now();
    final poseFrames = assessmentBreakdown?.poseFrames ?? const [];
    final photoImageIndex = poseFrames.isEmpty
        ? null
        : (assessmentBreakdown?.worstPoseImageIndex ??
            poseFrames.first.imageIndex);
    final impactComparison = EconomicImpactService.compareBeforeAfter(
      beforeImpact: before.economicLoss,
      beforeScore: before.userScore,
      afterScore: after.userScore,
    );
    return EvaluationHistoryRecord(
      id: recordId,
      farmerProfileId: _profile.profileId,
      farmerId: _profile.farmerId,
      farmerName: _profile.name,
      farmerRole: _profile.role,
      farmerLocation: _profile.location,
      farmerAge: _profile.age,
      farmerGender: _profile.gender,
      farmerWeight: _profile.weight,
      farmerHeight: _profile.height,
      farmerBmi: _profile.bmi,
      farmerBmiCategory: _profile.bmiCategoryKey,
      activity: activity,
      activityName: activityName,
      dateTime: dateTime,
      scoreBefore: before.userScore,
      scoreAfter: after.userScore,
      riskBefore: before.riskLevel,
      riskAfter: after.riskLevel,
      economicLoss: before.economicLoss,
      moneySaved: impactComparison.savedAmount,
      selectedSuggestionKeys: selectedSuggestionKeys,
      selectedSuggestions: selectedSuggestions,
      bodyPartRisks: before.bodyPartRisks,
      aiRiskPercent: before.aiRiskAlert == null
          ? null
          : (before.aiRiskAlert!.probability * 100).round(),
      aiAlertLevel: before.aiRiskAlert?.level,
      aiModelSource: before.aiRiskAlert?.modelSource,
      appVersion: SooktaBuildInfo.label,
      assessmentBreakdown: assessmentBreakdown,
      afterAssessmentBreakdown: afterAssessmentBreakdown,
      photoId: photoImageIndex == null
          ? null
          : 'transaction_${recordId}_photo_$photoImageIndex',
      photoTimestamp: photoImageIndex == null ? null : dateTime,
    );
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
    await preferences.setString(
      _farmersKey,
      jsonEncode(_farmers.map((farmer) => farmer.toJson()).toList()),
    );
    final activeProfileId = _activeProfileId;
    if (activeProfileId == null) {
      await preferences.remove(_activeProfileIdKey);
    } else {
      await preferences.setString(_activeProfileIdKey, activeProfileId);
    }
    await preferences.setBool(_setupCompletedKey, _setupCompleted);
    await preferences.setInt(_nextHistoryIdKey, _nextHistoryId);
    await preferences.setString(
      _historyKey,
      jsonEncode(_history.map((record) => record.toJson()).toList()),
    );
    final draft = _evaluationDraft;
    if (draft == null) {
      await preferences.remove(_evaluationDraftKey);
    } else {
      await preferences.setString(
        _evaluationDraftKey,
        jsonEncode(draft.toJson()),
      );
    }
    await preferences.setString(
      _evaluationDraftsKey,
      jsonEncode(
          _evaluationDrafts.values.map((draft) => draft.toJson()).toList()),
    );
    await preferences.setInt(_dataSchemaVersionKey, _currentDataSchemaVersion);
  }

  Future<void> _backupBeforeSchemaMigration(
      SharedPreferences preferences) async {
    final existingVersion = preferences.getInt(_dataSchemaVersionKey) ?? 1;
    if (existingVersion >= _currentDataSchemaVersion) return;
    final backup = <String, Object?>{
      'fromSchemaVersion': existingVersion,
      'toSchemaVersion': _currentDataSchemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      _profileKey: preferences.getString(_profileKey),
      _farmersKey: preferences.getString(_farmersKey),
      _activeProfileIdKey: preferences.getString(_activeProfileIdKey),
      _historyKey: preferences.getString(_historyKey),
      _nextHistoryIdKey: preferences.getInt(_nextHistoryIdKey),
      _evaluationDraftKey: preferences.getString(_evaluationDraftKey),
      _evaluationDraftsKey: preferences.getString(_evaluationDraftsKey),
    };
    final backupKey =
        'sookta.backup.schema.$existingVersion.${DateTime.now().microsecondsSinceEpoch}';
    await preferences.setString(backupKey, jsonEncode(backup));
    await preferences.setString(_latestBackupKey, backupKey);
  }

  EvaluationDraft _withActiveDraftMetadata(EvaluationDraft draft) {
    return draft.copyWith(
      farmerProfileId: draft.farmerProfileId ?? _profile.profileId,
      farmerId: draft.farmerId ?? _profile.farmerId,
      farmerName: draft.farmerName ?? _profile.name,
      assessmentDateKey: draft.assessmentDateKey ?? _todayKey(),
      appVersion: draft.appVersion ?? SooktaBuildInfo.label,
    );
  }

  EvaluationDraft? _latestDraftOrNull() {
    final drafts = evaluationDrafts;
    return drafts.isEmpty ? null : drafts.first;
  }

  String _draftKey(EvaluationDraft draft) {
    final profileId = draft.farmerProfileId?.trim();
    final profilePart =
        profileId == null || profileId.isEmpty ? 'no-profile' : profileId;
    final datePart = draft.assessmentDateKey ?? _todayKey();
    return '$profilePart|${draft.activity.name}|$datePart';
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  UserProfile _ensureProfileId(UserProfile profile) {
    if (profile.profileId.isNotEmpty) return profile;
    return profile.copyWith(profileId: _newProfileId());
  }

  String _newProfileId() {
    return 'farmer-${DateTime.now().microsecondsSinceEpoch}-${_farmers.length + 1}';
  }
}

class EvaluationHistoryRecord {
  const EvaluationHistoryRecord({
    required this.id,
    this.farmerProfileId,
    this.farmerId,
    this.farmerName,
    this.farmerRole,
    this.farmerLocation,
    this.farmerAge,
    this.farmerGender,
    this.farmerWeight,
    this.farmerHeight,
    this.farmerBmi,
    this.farmerBmiCategory,
    this.activity,
    required this.activityName,
    required this.dateTime,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.riskBefore,
    required this.riskAfter,
    required this.economicLoss,
    required this.moneySaved,
    this.selectedSuggestionKeys = const [],
    required this.selectedSuggestions,
    required this.bodyPartRisks,
    this.aiRiskPercent,
    this.aiAlertLevel,
    this.aiModelSource,
    this.appVersion,
    this.assessmentBreakdown,
    this.afterAssessmentBreakdown,
    this.photoId,
    this.photoTimestamp,
    this.timeOnTaskSeconds,
    this.completionStatus,
    this.assistanceRequired,
    this.errorCount,
    this.expertReba,
    this.expertRiskLevel,
    this.expertAssessmentDate,
    this.expertComments,
  });

  final int id;
  final String? farmerProfileId;
  final String? farmerId;
  final String? farmerName;
  final String? farmerRole;
  final String? farmerLocation;
  final String? farmerAge;
  final String? farmerGender;
  final String? farmerWeight;
  final String? farmerHeight;
  final double? farmerBmi;
  final String? farmerBmiCategory;
  final SooktaActivity? activity;
  final String activityName;
  final DateTime dateTime;
  final int scoreBefore;
  final int scoreAfter;
  final RiskLevel riskBefore;
  final RiskLevel riskAfter;
  final int economicLoss;
  final int moneySaved;
  final List<String> selectedSuggestionKeys;
  final List<String> selectedSuggestions;
  final Map<BodyPart, RiskLevel> bodyPartRisks;
  final int? aiRiskPercent;
  final AiAlertLevel? aiAlertLevel;
  final String? aiModelSource;
  final String? appVersion;
  final AssessmentBreakdown? assessmentBreakdown;
  final AssessmentBreakdown? afterAssessmentBreakdown;
  final String? photoId;
  final DateTime? photoTimestamp;
  final int? timeOnTaskSeconds;
  final String? completionStatus;
  final bool? assistanceRequired;
  final int? errorCount;
  final double? expertReba;
  final RiskLevel? expertRiskLevel;
  final DateTime? expertAssessmentDate;
  final String? expertComments;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'farmerProfileId': farmerProfileId,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerRole': farmerRole,
      'farmerLocation': farmerLocation,
      'farmerAge': farmerAge,
      'farmerGender': farmerGender,
      'farmerWeight': farmerWeight,
      'farmerHeight': farmerHeight,
      'farmerBmi': farmerBmi,
      'farmerBmiCategory': farmerBmiCategory,
      'activity': activity?.name,
      'activityName': activityName,
      'dateTime': dateTime.toIso8601String(),
      'scoreBefore': scoreBefore,
      'scoreAfter': scoreAfter,
      'riskBefore': riskBefore.name,
      'riskAfter': riskAfter.name,
      'economicLoss': economicLoss,
      'moneySaved': moneySaved,
      'selectedSuggestionKeys': selectedSuggestionKeys,
      'selectedSuggestions': selectedSuggestions,
      'bodyPartRisks': bodyPartRisks.map(
        (part, risk) => MapEntry(part.name, risk.name),
      ),
      'aiRiskPercent': aiRiskPercent,
      'aiAlertLevel': aiAlertLevel?.name,
      'aiModelSource': aiModelSource,
      'appVersion': appVersion,
      'assessmentBreakdown': assessmentBreakdown?.toJson(),
      'afterAssessmentBreakdown': afterAssessmentBreakdown?.toJson(),
      'photoId': photoId,
      'photoTimestamp': photoTimestamp?.toIso8601String(),
      'timeOnTaskSeconds': timeOnTaskSeconds,
      'completionStatus': completionStatus,
      'assistanceRequired': assistanceRequired,
      'errorCount': errorCount,
      'expertReba': expertReba,
      'expertRiskLevel': expertRiskLevel?.name,
      'expertAssessmentDate': expertAssessmentDate?.toIso8601String(),
      'expertComments': expertComments,
    };
  }

  factory EvaluationHistoryRecord.fromJson(Map<String, Object?> json) {
    return EvaluationHistoryRecord(
      id: json['id'] as int? ?? 0,
      farmerProfileId: json['farmerProfileId'] as String?,
      farmerId: json['farmerId'] as String?,
      farmerName: json['farmerName'] as String?,
      farmerRole: json['farmerRole'] as String?,
      farmerLocation: json['farmerLocation'] as String?,
      farmerAge: json['farmerAge'] as String?,
      farmerGender: json['farmerGender'] as String?,
      farmerWeight: json['farmerWeight'] as String?,
      farmerHeight: json['farmerHeight'] as String?,
      farmerBmi: json['farmerBmi'] is num
          ? (json['farmerBmi'] as num).toDouble()
          : double.tryParse(json['farmerBmi']?.toString() ?? ''),
      farmerBmiCategory: json['farmerBmiCategory'] as String?,
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
      selectedSuggestionKeys:
          _optionalStringList(json['selectedSuggestionKeys']),
      selectedSuggestions: _optionalStringList(json['selectedSuggestions']),
      bodyPartRisks: _bodyRisksFromJson(json['bodyPartRisks']),
      aiRiskPercent: json['aiRiskPercent'] as int?,
      aiAlertLevel: _aiAlertFromName(json['aiAlertLevel'] as String?),
      aiModelSource: json['aiModelSource'] as String?,
      appVersion: json['appVersion'] as String?,
      assessmentBreakdown: _assessmentBreakdownFromJson(
        json['assessmentBreakdown'],
      ),
      afterAssessmentBreakdown: _assessmentBreakdownFromJson(
        json['afterAssessmentBreakdown'],
      ),
      photoId: json['photoId'] as String?,
      photoTimestamp: DateTime.tryParse(
        json['photoTimestamp']?.toString() ?? '',
      ),
      timeOnTaskSeconds: _optionalInt(json['timeOnTaskSeconds']),
      completionStatus: json['completionStatus'] as String?,
      assistanceRequired: _optionalBool(json['assistanceRequired']),
      errorCount: _optionalInt(json['errorCount']),
      expertReba: _optionalDouble(json['expertReba']),
      expertRiskLevel: _optionalRiskFromName(json['expertRiskLevel']),
      expertAssessmentDate: DateTime.tryParse(
        json['expertAssessmentDate']?.toString() ?? '',
      ),
      expertComments: json['expertComments'] as String?,
    );
  }

  static int? _optionalInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static List<String> _optionalStringList(Object? value) {
    if (value is! List || value.any((item) => item is! String)) {
      return const [];
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  static double? _optionalDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool? _optionalBool(Object? value) {
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase().trim();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
    return null;
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

  static RiskLevel? _optionalRiskFromName(Object? name) {
    if (name == null) return null;
    return RiskLevel.values.cast<RiskLevel?>().firstWhere(
          (risk) => risk?.name == name.toString(),
          orElse: () => null,
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

extension EvaluationHistoryRecommendationLocalization
    on EvaluationHistoryRecord {
  String localizedActivityName({required bool thai}) {
    final typedActivity = activity ?? _legacyActivityFromLabel(activityName);
    return typedActivity?.label(thai: thai) ?? (thai ? 'กิจกรรม' : 'Activity');
  }

  List<String> localizedSelectedSuggestions(
    RecommendationLanguage language,
  ) {
    if (selectedSuggestionKeys.isEmpty && selectedSuggestions.isEmpty) {
      return const [];
    }

    final fallback = RecommendationCatalogService.joinedText(
      selectionKey: 'system.unmapped_saved_recommendation',
      language: language,
    );
    final positionCount =
        selectedSuggestionKeys.length > selectedSuggestions.length
            ? selectedSuggestionKeys.length
            : selectedSuggestions.length;
    return List.unmodifiable(
      List.generate(positionCount, (index) {
        if (index < selectedSuggestionKeys.length) {
          final selectionKey = selectedSuggestionKeys[index];
          final resolvedKeyText = RecommendationCatalogService.tryJoinedText(
                selectionKey: selectionKey,
                language: language,
                activity: activity?.name,
                bodyPart: _bodyPartContextForSelectionKey(selectionKey),
                riskLevel: riskBefore.name,
              ) ??
              RecommendationCatalogService.tryJoinedTextForSelectionKey(
                selectionKey: selectedSuggestionKeys[index],
                language: language,
              );
          if (resolvedKeyText != null) return resolvedKeyText;
        }
        if (index < selectedSuggestions.length) {
          final legacyKey =
              RecommendationCatalogService.selectionKeyForLegacyText(
            selectedSuggestions[index],
          );
          if (legacyKey != null) {
            final resolvedLegacyText =
                RecommendationCatalogService.tryJoinedText(
                      selectionKey: legacyKey,
                      language: language,
                      activity: activity?.name,
                      bodyPart: _bodyPartContextForSelectionKey(legacyKey),
                      riskLevel: riskBefore.name,
                    ) ??
                    RecommendationCatalogService.tryJoinedTextForSelectionKey(
                      selectionKey: legacyKey,
                      language: language,
                    );
            if (resolvedLegacyText != null) return resolvedLegacyText;
          }
        }
        return fallback;
      }),
    );
  }

  static SooktaActivity? _legacyActivityFromLabel(String label) {
    for (final activity in SooktaActivity.values) {
      if (label == activity.label(thai: true) ||
          label == activity.label(thai: false)) {
        return activity;
      }
    }
    return null;
  }

  static String? _bodyPartContextForSelectionKey(String selectionKey) {
    const prefixes = <String, String>{
      'act_body_neck_': 'neck',
      'act_body_trunk_': 'trunk',
      'act_body_arms_': 'arms',
      'act_body_wrists_': 'wrists',
      'act_body_legs_': 'legs',
      'act_body_manual_': 'manual',
    };
    for (final entry in prefixes.entries) {
      if (selectionKey.startsWith(entry.key)) return entry.value;
    }
    return null;
  }
}
