import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/ergonomics_risk_prediction/ergonomics_risk_prediction.dart'
    as risk_ml;
import '../../core/models/assessment_session.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/ergo_calculator.dart';
import '../../core/services/firebase_telemetry_service.dart';
import '../../core/services/pose_estimation_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/tts_button.dart';
import 'camera_capture_screen.dart';
import 'initial_risk_screen.dart';

class EvaluationFormScreen extends StatefulWidget {
  const EvaluationFormScreen({
    required this.activity,
    super.key,
  });

  static const routeName = '/evaluation-form';

  final SooktaActivity activity;

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final horizontalController = TextEditingController(text: '25');
  final verticalController = TextEditingController(text: '75');
  final transportController = TextEditingController(text: '4');
  final initialForceController = TextEditingController(text: '18');
  final sustainForceController = TextEditingController(text: '8');
  final imagePicker = ImagePicker();
  final poseService = PoseEstimationService();
  risk_ml.JointFeatureSchema? jointFeatureSchema;
  risk_ml.MoveNetJointFeatureExtractor? jointFeatureExtractor;
  risk_ml.XGBoostOnnxPredictor? xGBoostPredictor;

  final selectedImagePaths = <String>[];
  final latestPoseEstimates = <PoseEstimate>[];
  var selectedDurationHours = 1.0;
  var selectedFrequency = 0.2;
  var selectedLoadWeight = 10.0;
  var showAdvancedDetails = false;
  var poseBusy = false;
  var poseAssessmentReady = false;
  String? poseStatus;
  AiRiskAlert? latestXGBoostAlert;
  late JobType selectedJobType;
  var rebaInput = const RebaInputData(
    trunkScore: 3,
    neckScore: 1,
    legScore: 1,
    upperArmScore: 2,
    lowerArmScore: 1,
    wristScore: 1,
  );

  @override
  void initState() {
    super.initState();
    selectedJobType = widget.activity.defaultJobType;
    _applyActivityDefaults();
  }

  void _applyActivityDefaults() {
    switch (widget.activity) {
      case SooktaActivity.transplanting:
        selectedDurationHours = 4.0;
        selectedFrequency = 2.0;
        rebaInput = rebaInput.copyWith(activityScore: 1);
      case SooktaActivity.fertilizing:
        selectedDurationHours = 2.0;
        selectedFrequency = 2.0;
        selectedLoadWeight = 15.0;
        transportController.text = '6';
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          loadScore: 1,
          couplingScore: 1,
        );
      case SooktaActivity.pesticide:
        selectedDurationHours = 2.0;
        selectedFrequency = 0.2;
        initialForceController.text = '12';
        sustainForceController.text = '6';
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          loadScore: 1,
          couplingScore: 1,
        );
      case SooktaActivity.pruning:
        selectedDurationHours = 2.0;
        selectedFrequency = 2.0;
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          wristScore: 2,
        );
      case SooktaActivity.harvesting:
        selectedDurationHours = 4.0;
        selectedFrequency = 6.5;
        selectedLoadWeight = 10.0;
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          loadScore: 1,
        );
      case SooktaActivity.transport:
        selectedDurationHours = 2.0;
        selectedFrequency = 2.0;
        selectedLoadWeight = 20.0;
        transportController.text = '8';
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          loadScore: 1,
          couplingScore: 1,
        );
    }
  }

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    transportController.dispose();
    initialForceController.dispose();
    sustainForceController.dispose();
    poseService.dispose();
    xGBoostPredictor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final language = state.language ?? AppLanguage.th;
    final thai = language == AppLanguage.th;
    final activityName = widget.activity.label(thai: thai);
    final canAnalyze =
        selectedImagePaths.isNotEmpty && poseAssessmentReady && !poseBusy;

    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'แบบฟอร์มประเมิน' : 'Evaluation Form')),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 680,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              thai ? 'กิจกรรม: $activityName' : 'Activity: $activityName',
              style: const TextStyle(
                color: SooktaColors.darkGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _EvaluationVoiceGuide(
              thai: thai,
              activityName: activityName,
              jobType: selectedJobType,
              durationHours: selectedDurationHours,
              frequency: selectedFrequency,
              loadWeight: selectedLoadWeight,
            ),
            const SizedBox(height: 16),
            _ImageSlots(
              imagePaths: selectedImagePaths,
              onCamera: selectedImagePaths.length >= 4 ? null : _capturePhoto,
              onGallery:
                  selectedImagePaths.length >= 4 ? null : _pickGalleryPhoto,
              onSlotTap: _pickGalleryForSlot,
              onSlotRemove: _removeImageAt,
              thai: thai,
            ),
            const SizedBox(height: 16),
            _SimpleAssessmentCard(
              thai: thai,
              activityName: activityName,
              jobType: selectedJobType,
              imageCount: selectedImagePaths.length,
              poseBusy: poseBusy,
              poseReady: poseAssessmentReady,
              poseStatus: poseStatus,
              durationHours: selectedDurationHours,
              frequency: selectedFrequency,
              loadWeight: selectedLoadWeight,
              onAnalyze: canAnalyze ? _analyze : null,
            ),
            const SizedBox(height: 16),
            _AdvancedDetailsCard(
              thai: thai,
              expanded: showAdvancedDetails,
              onExpansionChanged: (value) =>
                  setState(() => showAdvancedDetails = value),
              children: [
                _SectionCard(
                  title: thai ? 'ข้อมูลสำหรับนักวิจัย' : 'Research Details',
                  children: [
                    Text(
                      thai
                          ? 'ระบบตั้งค่าให้แล้วจากกิจกรรมและรูปภาพ ปรับเฉพาะเมื่อทราบข้อมูลจริง'
                          : 'The app pre-fills these values from the activity and photo. Adjust only when known.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<JobType>(
                      segments: [
                        ButtonSegment(
                          value: JobType.reba,
                          label: Text(thai ? 'ท่าทาง' : 'Posture'),
                          icon: const Icon(Icons.accessibility_new),
                        ),
                        ButtonSegment(
                          value: JobType.lifting,
                          label: Text(thai ? 'ยก/แบก' : 'Lift'),
                          icon: const Icon(Icons.inventory_2_outlined),
                        ),
                        ButtonSegment(
                          value: JobType.pushPull,
                          label: Text(thai ? 'ดัน/ดึง' : 'Push'),
                          icon: const Icon(Icons.open_with),
                        ),
                      ],
                      selected: {selectedJobType},
                      onSelectionChanged: (value) {
                        setState(() {
                          selectedJobType = value.first;
                          poseStatus = null;
                          poseAssessmentReady = false;
                        });
                        if (selectedImagePaths.isNotEmpty) {
                          _applyPoseEstimates();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _ChoiceRow<double>(
                      label: thai ? 'ระยะเวลาประมาณ' : 'Estimated duration',
                      value: selectedDurationHours,
                      items: {
                        1.0: thai ? 'สั้น' : 'Short',
                        2.0: thai ? 'ประมาณ 2 ชม.' : 'About 2 hrs',
                        4.0: thai ? 'ครึ่งวัน' : 'Half day',
                        8.0: thai ? 'ทั้งวัน' : 'Full day',
                      },
                      onChanged: (value) =>
                          setState(() => selectedDurationHours = value),
                    ),
                    _ChoiceRow<double>(
                      label: thai ? 'ทำซ้ำบ่อยแค่ไหน' : 'Repetition',
                      value: selectedFrequency,
                      items: {
                        0.2: thai ? 'นาน ๆ ครั้ง' : 'Occasional',
                        2.0: thai ? 'เป็นระยะ' : 'Repeated',
                        6.5: thai ? 'บ่อยมาก' : 'Very frequent',
                      },
                      onChanged: (value) =>
                          setState(() => selectedFrequency = value),
                    ),
                    if (selectedJobType == JobType.lifting)
                      _ChoiceRow<double>(
                        label: thai ? 'น้ำหนักโดยประมาณ' : 'Estimated load',
                        value: selectedLoadWeight,
                        items: {
                          5.0: thai ? 'เบา (5 กก.)' : 'Light (5 kg)',
                          10.0: thai ? 'ปานกลาง (10 กก.)' : 'Medium (10 kg)',
                          15.0: thai
                              ? 'ค่อนข้างหนัก (15 กก.)'
                              : 'Quite heavy (15 kg)',
                          20.0: thai ? 'หนัก (20 กก.)' : 'Heavy (20 kg)',
                          25.0:
                              thai ? 'หนักมาก (25 กก.)' : 'Very heavy (25 kg)',
                        },
                        onChanged: (value) =>
                            setState(() => selectedLoadWeight = value),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedJobType == JobType.reba)
                  _RebaCard(
                    thai: thai,
                    input: rebaInput,
                    poseBusy: poseBusy,
                    poseStatus: poseStatus,
                    onChanged: (input) => setState(() => rebaInput = input),
                    onAutoFill: selectedImagePaths.isEmpty || poseBusy
                        ? null
                        : _applyPoseEstimates,
                  )
                else
                  _IsoCard(
                    thai: thai,
                    jobType: selectedJobType,
                    horizontalController: horizontalController,
                    verticalController: verticalController,
                    transportController: transportController,
                    initialForceController: initialForceController,
                    sustainForceController: sustainForceController,
                  ),
              ],
            ),
            if (showAdvancedDetails) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: canAnalyze ? _analyze : null,
                icon: poseBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: Text(thai ? 'ดูผลประเมิน' : 'View Assessment'),
              ),
              if (!canAnalyze) ...[
                const SizedBox(height: 8),
                Text(
                  poseBusy
                      ? (thai
                          ? 'กำลังอ่านรูปภาพ รอสักครู่'
                          : 'Reading the photo. Please wait.')
                      : (selectedImagePaths.isNotEmpty && !poseAssessmentReady)
                          ? (thai
                              ? 'ต้องใช้รูปที่เห็นบุคคลและท่าทางชัดเจนก่อน จึงจะแสดงผลประเมินได้'
                              : 'Use a clear photo with a readable person posture before viewing results.')
                          : (thai
                              ? 'ถ่ายรูปหรือเลือกรูปก่อน ระบบจะช่วยคำนวณให้'
                              : 'Take or choose a photo first. The app will calculate the rest.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (path != null) {
      await _addImage(path);
      unawaited(FirebaseTelemetryService.logImageAdded(
        source: 'camera',
        imageCount: selectedImagePaths.length,
      ));
    }
  }

  Future<void> _pickGalleryPhoto() async {
    await _pickGalleryForSlot(-1);
  }

  Future<void> _pickGalleryForSlot(int slotIndex) async {
    final photo = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (photo != null) {
      await _addImage(photo.path, slotIndex: slotIndex);
      unawaited(FirebaseTelemetryService.logImageAdded(
        source: 'gallery',
        imageCount: selectedImagePaths.length,
      ));
    }
  }

  Future<void> _addImage(String path, {int slotIndex = -1}) async {
    if (selectedImagePaths.length >= 4 &&
        (slotIndex < 0 || slotIndex >= selectedImagePaths.length)) {
      return;
    }
    setState(() {
      if (slotIndex >= 0 && slotIndex < selectedImagePaths.length) {
        selectedImagePaths[slotIndex] = path;
      } else if (slotIndex == selectedImagePaths.length &&
          selectedImagePaths.length < 4) {
        selectedImagePaths.add(path);
      } else if (selectedImagePaths.length < 4) {
        selectedImagePaths.add(path);
      }
      poseStatus = null;
      poseAssessmentReady = false;
      latestXGBoostAlert = null;
      latestPoseEstimates.clear();
    });
    await _applyPoseEstimates();
  }

  Future<void> _removeImageAt(int index) async {
    if (index < 0 || index >= selectedImagePaths.length) return;
    setState(() {
      selectedImagePaths.removeAt(index);
      poseStatus = null;
      poseAssessmentReady = false;
      latestXGBoostAlert = null;
      latestPoseEstimates.clear();
    });
    if (selectedImagePaths.isNotEmpty) {
      await _applyPoseEstimates();
    }
  }

  Future<void> _applyPoseEstimates() async {
    if (selectedImagePaths.isEmpty || poseBusy) return;

    setState(() {
      poseBusy = true;
      poseAssessmentReady = false;
      final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
          AppLanguage.th;
      poseStatus = thai ? 'กำลังวิเคราะห์ภาพ...' : 'Analyzing photo...';
    });

    try {
      final estimates = <PoseEstimate>[];
      for (final path in selectedImagePaths) {
        final estimate = await poseService.estimatePoseFromFile(path);
        if (estimate != null) estimates.add(estimate);
      }

      if (!mounted) return;
      final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
          AppLanguage.th;
      if (estimates.isEmpty) {
        setState(() {
          poseAssessmentReady = false;
          latestPoseEstimates.clear();
          latestXGBoostAlert = null;
          poseStatus = thai
              ? 'ยังประเมินไม่ได้: ไม่พบคนหรืออ่านท่าทางไม่ได้ กรุณาใช้รูปที่เห็นบุคคลและท่าทางชัดเจน'
              : 'Cannot assess yet: no readable person posture was detected. Use a clear full-body photo.';
        });
        return;
      }

      final inferred = _inferWorstRebaInput(estimates);
      final xgbAlert = await _predictXGBoostAlert(estimates);

      if (selectedJobType == JobType.reba) {
        setState(() {
          latestPoseEstimates
            ..clear()
            ..addAll(estimates);
          latestXGBoostAlert = xgbAlert;
          rebaInput = inferred;
          poseAssessmentReady = true;
          poseStatus = thai
              ? 'ระบบประเมินคะแนน REBA จากภาพและตรวจเทียบด้วย XGBoost แล้ว'
              : 'REBA scores updated from photos and checked with XGBoost.';
        });
      } else if (selectedJobType == JobType.lifting) {
        final dimensions =
            poseService.estimateLiftingDimensions(estimates.last);
        setState(() {
          latestPoseEstimates
            ..clear()
            ..addAll(estimates);
          latestXGBoostAlert = xgbAlert;
          rebaInput = inferred;
          if (dimensions == null) {
            poseAssessmentReady = false;
            poseStatus = thai
                ? 'ยังประเมินไม่ได้: พบคนในภาพ แต่ยังอ่านระยะ H/V ไม่ได้ กรุณาใช้รูปที่เห็นท่าทางและตำแหน่งมือชัดเจน'
                : 'Cannot assess yet: a person was detected, but H/V distances could not be estimated. Use a clearer posture photo.';
          } else {
            horizontalController.text =
                dimensions.horizontalCm.round().toString();
            verticalController.text = dimensions.verticalCm.round().toString();
            poseAssessmentReady = true;
            poseStatus = thai
                ? 'ระบบอ่านระยะ H/V และคะแนน REBA จากภาพแล้ว'
                : 'H/V distances and REBA posture scores updated from the latest photo.';
          }
        });
      } else {
        setState(() {
          latestPoseEstimates
            ..clear()
            ..addAll(estimates);
          latestXGBoostAlert = xgbAlert;
          rebaInput = inferred;
          poseAssessmentReady = true;
          poseStatus = thai
              ? 'ระบบประเมินท่าทางจากภาพแล้ว'
              : 'Posture scores updated from photos.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
          AppLanguage.th;
      setState(() {
        poseAssessmentReady = false;
        latestXGBoostAlert = null;
        latestPoseEstimates.clear();
        poseStatus =
            thai ? 'วิเคราะห์ภาพไม่สำเร็จ: $e' : 'Image analysis failed: $e';
      });
    } finally {
      if (mounted) setState(() => poseBusy = false);
    }
  }

  Future<void> _analyze() async {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    if (selectedImagePaths.isEmpty || poseBusy || !poseAssessmentReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'ยังประเมินไม่ได้ กรุณาใช้รูปที่เห็นบุคคลและท่าทางชัดเจนก่อน เพื่อหลีกเลี่ยงตัวเลขที่ไม่น่าเชื่อถือ'
                : 'Cannot assess yet. Use a clear photo with a readable person posture to avoid unreliable numbers.',
          ),
        ),
      );
      return;
    }
    final activityName = widget.activity.label(thai: thai);
    final gender = state.profile.gender.toLowerCase();
    final dailyIncome = state.dailyIncome.toDouble();
    final ergoInput = ErgoInputData(
      jobType: selectedJobType,
      gender: gender,
      dailyIncome: dailyIncome,
      loadWeight: selectedLoadWeight,
      horizontalDist: _number(horizontalController, 25),
      verticalHeight: _number(verticalController, 75),
      liftFrequency: selectedFrequency,
      durationHours: selectedDurationHours,
      transportDistance: _number(transportController, 4),
      initialForce: _number(initialForceController, 18),
      sustainForce: _number(sustainForceController, 8),
    );
    final rebaData = rebaInput.copyWith(dailyIncome: dailyIncome);
    final rebaResult = ErgoCalculator.calculateRebaRisk(rebaData);
    final isoMethod = switch (selectedJobType) {
      JobType.lifting => AssessmentMethod.iso11228Lifting,
      JobType.pushPull => AssessmentMethod.iso11228PushPull,
      JobType.reba => null,
    };
    final isoResult = switch (selectedJobType) {
      JobType.lifting => ErgoCalculator.calculateLiftingRisk(ergoInput),
      JobType.pushPull => ErgoCalculator.calculatePushPullRisk(ergoInput),
      JobType.reba => null,
    };
    var result = isoResult == null
        ? rebaResult
        : ErgoCalculator.calculateCombinedRebaIsoRisk(
            rebaResult: rebaResult,
            isoResult: isoResult,
            dailyIncome: dailyIncome,
          );
    final primaryMethod = isoResult == null
        ? AssessmentMethod.reba
        : AssessmentMethod.rebaIsoCombined;

    unawaited(FirebaseTelemetryService.logAssessmentCalculated(
      activity: widget.activity.name,
      jobType: selectedJobType.name,
      primaryMethod: primaryMethod.name,
      riskLevel: result.riskLevel.name,
      score: result.userScore,
      imageCount: selectedImagePaths.length,
      usesIso11228: isoResult != null,
    ));

    final xgbAlert = latestXGBoostAlert;
    if (xgbAlert != null) {
      result = _applyXGBoostGuardrail(result, xgbAlert);
    }
    final breakdown = AssessmentBreakdown(
      primaryMethod: primaryMethod,
      rebaInput: rebaData,
      rebaResult: rebaResult,
      ergoInput: ergoInput,
      isoMethod: isoMethod,
      isoResult: isoResult,
    );

    if (!mounted) return;

    Navigator.of(context).pushNamed(
      InitialRiskScreen.routeName,
      arguments: InitialRiskPayload(
        activity: widget.activity,
        activityName: activityName,
        jobType: selectedJobType,
        before: result,
        ergoInput: ergoInput,
        rebaInput: rebaData,
        breakdown: breakdown,
      ),
    );
  }

  double _number(TextEditingController controller, double fallback) {
    return double.tryParse(controller.text.trim()) ?? fallback;
  }

  RebaInputData _inferWorstRebaInput(List<PoseEstimate> estimates) {
    var inferred = rebaInput;
    for (final estimate in estimates) {
      final input = ErgoCalculator.calculateRebaInputFromPose(
        estimate.person,
        rebaInput,
      );
      inferred = inferred.copyWith(
        trunkScore: mathMax(input.trunkScore, inferred.trunkScore),
        neckScore: mathMax(input.neckScore, inferred.neckScore),
        legScore: mathMax(input.legScore, inferred.legScore),
        upperArmScore: mathMax(input.upperArmScore, inferred.upperArmScore),
        lowerArmScore: mathMax(input.lowerArmScore, inferred.lowerArmScore),
      );
    }
    return inferred;
  }

  Future<AiRiskAlert?> _predictXGBoostAlert(
    List<PoseEstimate> estimates,
  ) async {
    if (estimates.isEmpty) return null;
    try {
      final schema = jointFeatureSchema ??
          await const risk_ml.JointFeatureSchemaLoader().load();
      jointFeatureSchema = schema;
      final extractor =
          jointFeatureExtractor ?? risk_ml.MoveNetJointFeatureExtractor(schema);
      jointFeatureExtractor = extractor;
      final predictor = xGBoostPredictor ??
          risk_ml.XGBoostOnnxPredictor(featureSchema: schema);
      xGBoostPredictor = predictor;
      await predictor.initModel();

      risk_ml.RiskAssessmentResult? strongest;
      for (final estimate in estimates) {
        final result = await predictor
            .predictRiskLevel(extractor.extract(estimate.person));
        if (strongest == null ||
            result.level.index > strongest.level.index ||
            (result.level.index == strongest.level.index &&
                result.confidenceScore > strongest.confidenceScore)) {
          strongest = result;
        }
      }
      if (strongest == null) return null;
      final probability = strongest.confidenceScore.clamp(0.0, 1.0).toDouble();
      return AiRiskAlert(
        probability: probability,
        logisticProbability: 0,
        xgBoostProbability: probability,
        level: _alertLevelFromRisk(strongest.level),
        modelVersion: 'reba-iso-xgboost-onnx-2026-06-06',
        modelSource: 'research_team_reba2_iso11228_document_guided_xgboost',
        featureImportance: const [],
      );
    } catch (_) {
      return null;
    }
  }

  ErgoResult _applyXGBoostGuardrail(ErgoResult result, AiRiskAlert alert) {
    final xgbRisk = _riskLevelFromAlert(alert.level);
    if (xgbRisk.index <= result.riskLevel.index) {
      return result.copyWith(aiRiskAlert: alert);
    }
    final calibratedScore = switch (xgbRisk) {
      RiskLevel.low => result.userScore,
      RiskLevel.medium => mathMax(result.userScore, 4),
      RiskLevel.high => mathMax(result.userScore, 7),
      RiskLevel.veryHigh => mathMax(result.userScore, 9),
    };
    return result.copyWith(
      riskLevel: xgbRisk,
      userScore: calibratedScore,
      userScoreColor: xgbRisk.colorHex,
      suggestionKey: xgbRisk == RiskLevel.low ? 'sugg_safe' : 'sugg_improve',
      aiRiskAlert: alert,
    );
  }

  AiAlertLevel _alertLevelFromRisk(risk_ml.RiskLevel risk) {
    return switch (risk.name) {
      'veryHigh' => AiAlertLevel.critical,
      'high' => AiAlertLevel.high,
      'medium' => AiAlertLevel.watch,
      _ => AiAlertLevel.low,
    };
  }

  RiskLevel _riskLevelFromAlert(AiAlertLevel level) {
    return switch (level) {
      AiAlertLevel.critical => RiskLevel.veryHigh,
      AiAlertLevel.high => RiskLevel.high,
      AiAlertLevel.watch => RiskLevel.medium,
      AiAlertLevel.low => RiskLevel.low,
    };
  }

  int mathMax(int a, int b) => a > b ? a : b;
}

class _EvaluationVoiceGuide extends StatelessWidget {
  const _EvaluationVoiceGuide({
    required this.thai,
    required this.activityName,
    required this.jobType,
    required this.durationHours,
    required this.frequency,
    required this.loadWeight,
  });

  final bool thai;
  final String activityName;
  final JobType jobType;
  final double durationHours;
  final double frequency;
  final double loadWeight;

  @override
  Widget build(BuildContext context) {
    final guide = thai
        ? 'กิจกรรม $activityName ขั้นตอนนี้ให้ถ่ายรูปหรือเลือกรูปที่เห็นคนทำงานชัดเจน ระบบจะอ่านท่าทางจากรูปและตั้งค่าประเมินให้อัตโนมัติ วิธีประเมินคือ ${_jobLabel(jobType, true)} ค่าเริ่มต้นคือ ${_defaultSummary(true)}'
        : 'Activity $activityName. Take or choose a clear photo of the worker. The app reads posture from the photo and prepares the assessment automatically. Assessment method is ${_jobLabel(jobType, false)}. Defaults are ${_defaultSummary(false)}.';
    return Card(
      color: const Color(0xFFEAF5EF),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.record_voice_over_outlined,
                color: SooktaColors.darkGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                thai
                    ? 'กดลำโพงเพื่อฟังขั้นตอนประเมินกิจกรรมนี้'
                    : 'Tap the speaker to hear this assessment step.',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            SooktaTtsButton(text: guide, thai: thai, size: 42),
          ],
        ),
      ),
    );
  }

  String _defaultSummary(bool thai) {
    final duration = switch (durationHours) {
      1.0 => thai ? 'งานสั้น' : 'short work',
      2.0 => thai ? 'ประมาณ 2 ชั่วโมง' : 'about 2 hours',
      4.0 => thai ? 'ครึ่งวัน' : 'half day',
      _ => thai ? 'ทั้งวัน' : 'full day',
    };
    final repetition = switch (frequency) {
      <= 0.2 => thai ? 'ทำไม่ถี่' : 'occasional',
      < 6.0 => thai ? 'ทำซ้ำเป็นระยะ' : 'repeated',
      _ => thai ? 'ทำซ้ำบ่อย' : 'very frequent',
    };
    if (jobType == JobType.lifting) {
      return thai
          ? '$duration, $repetition, น้ำหนักประมาณ ${loadWeight.round()} กิโลกรัม'
          : '$duration, $repetition, about ${loadWeight.round()} kilograms';
    }
    return '$duration, $repetition';
  }
}

class _ImageSlots extends StatelessWidget {
  const _ImageSlots({
    required this.imagePaths,
    required this.onCamera,
    required this.onGallery,
    required this.onSlotTap,
    required this.onSlotRemove,
    required this.thai,
  });

  final List<String> imagePaths;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final ValueChanged<int> onSlotTap;
  final ValueChanged<int> onSlotRemove;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: thai
          ? '1. ถ่ายรูปท่าทางทำงาน (${imagePaths.length}/4)'
          : '1. Take a Work-Posture Photo (${imagePaths.length}/4)',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                thai ? 'คำแนะนำรูปภาพ' : 'Photo guidance',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SooktaTtsButton(
              thai: thai,
              text: thai
                  ? 'ถ่ายรูปให้เห็นคนทำงานชัดเจน เห็นศีรษะ หลัง แขน มือ ขา และเท้าได้มากที่สุด เพิ่มได้ไม่เกินสี่รูป ถ้าระบบอ่านท่าทางไม่ได้ ให้ถ่ายใหม่หรือเลือกรูปใหม่'
                  : 'Take a clear photo of the worker. Show the head, back, arms, hands, legs, and feet as much as possible. Add up to four photos. If the app cannot read the posture, retake or choose another photo.',
              size: 36,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          thai
              ? 'ให้เห็นคนทำงานชัดที่สุด ระบบจะอ่านท่าทางและตั้งค่าประเมินให้อัตโนมัติ'
              : 'Show the worker clearly. The app reads the posture and fills the assessment automatically.',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 340 ? 1 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 1 ? 2.6 : 1.45,
              ),
              itemBuilder: (context, index) {
                final filled = index < imagePaths.length;
                final enabled = filled || index == imagePaths.length;
                return InkWell(
                  onTap: enabled && !filled ? () => onSlotTap(index) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: filled
                          ? const Color(0xFFE8F5E9)
                          : enabled
                              ? Colors.grey.shade100
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: filled
                            ? SooktaColors.leafGreen
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: filled
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(imagePaths[index]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: SooktaColors.darkGreen,
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.red.withValues(alpha: 0.86),
                                      foregroundColor: Colors.white,
                                      fixedSize: const Size(30, 30),
                                      minimumSize: const Size(30, 30),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => onSlotRemove(index),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Icon(
                                enabled
                                    ? Icons.add_a_photo_outlined
                                    : Icons.image_outlined,
                                color: enabled
                                    ? Colors.grey
                                    : Colors.grey.shade400,
                              ),
                            ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 340;
            return Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2,
                  child: FilledButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(thai ? 'ถ่ายรูป' : 'Camera'),
                  ),
                ),
                SizedBox(
                  width: stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2,
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(thai ? 'อัลบั้ม' : 'Gallery'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SimpleAssessmentCard extends StatelessWidget {
  const _SimpleAssessmentCard({
    required this.thai,
    required this.activityName,
    required this.jobType,
    required this.imageCount,
    required this.poseBusy,
    required this.poseReady,
    required this.poseStatus,
    required this.durationHours,
    required this.frequency,
    required this.loadWeight,
    required this.onAnalyze,
  });

  final bool thai;
  final String activityName;
  final JobType jobType;
  final int imageCount;
  final bool poseBusy;
  final bool poseReady;
  final String? poseStatus;
  final double durationHours;
  final double frequency;
  final double loadWeight;
  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageCount > 0;
    final ready = hasImage && poseReady && !poseBusy;
    final blocked = hasImage && !poseReady && !poseBusy;
    final color = ready
        ? SooktaColors.leafGreen
        : blocked
            ? Colors.red.shade700
            : Colors.amber.shade700;
    final statusSpeech = thai
        ? '${ready ? 'ระบบตั้งค่าประเมินให้แล้ว' : blocked ? 'ยังประเมินไม่ได้' : 'ถ่ายรูปก่อน แล้วระบบจะช่วยคำนวณ'} ${poseStatus ?? 'ต้องมีรูปบุคคลที่เห็นท่าทางชัดเจนก่อน ระบบจึงจะแสดงตัวเลขประเมิน'} กิจกรรม $activityName วิธีประเมิน ${_jobLabel(jobType, true)} ค่าพื้นฐาน ${_defaultSummary(true)}'
        : '${ready ? 'The app prepared the assessment.' : blocked ? 'Cannot assess yet.' : 'Take a photo and the app will calculate.'} ${poseStatus ?? 'A clear person-posture photo is required before the app shows assessment numbers.'} Activity $activityName. Assessment method ${_jobLabel(jobType, false)}. Defaults ${_defaultSummary(false)}.';
    return Card(
      color: ready
          ? const Color(0xFFEFF8EF)
          : blocked
              ? const Color(0xFFFFF1F1)
              : const Color(0xFFFFFBEE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_outline
                      : blocked
                          ? Icons.warning_amber_rounded
                          : Icons.touch_app_outlined,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thai
                            ? (ready
                                ? 'ระบบตั้งค่าประเมินให้แล้ว'
                                : blocked
                                    ? 'ยังประเมินไม่ได้'
                                    : 'ถ่ายรูปก่อน แล้วระบบจะช่วยคำนวณ')
                            : (ready
                                ? 'The app prepared the assessment'
                                : blocked
                                    ? 'Cannot assess yet'
                                    : 'Take a photo and the app will calculate'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        poseBusy
                            ? (thai
                                ? 'กำลังอ่านท่าทางจากรูปภาพ...'
                                : 'Reading posture from the photo...')
                            : (poseStatus ??
                                (thai
                                    ? 'ต้องมีรูปบุคคลที่เห็นท่าทางชัดเจนก่อน ระบบจึงจะแสดงตัวเลขประเมิน'
                                    : 'A clear person-posture photo is required before the app shows assessment numbers.')),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                SooktaTtsButton(text: statusSpeech, thai: thai, size: 38),
              ],
            ),
            if (poseBusy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 14),
            _SimpleFactRow(
              icon: Icons.work_outline,
              label: thai ? 'กิจกรรม' : 'Activity',
              value: activityName,
            ),
            _SimpleFactRow(
              icon: Icons.auto_awesome,
              label: thai ? 'วิธีประเมิน' : 'Assessment',
              value: _jobLabel(jobType, thai),
            ),
            _SimpleFactRow(
              icon: Icons.schedule,
              label: thai ? 'ค่าพื้นฐาน' : 'Defaults',
              value: _defaultSummary(thai),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAnalyze,
              icon: const Icon(Icons.arrow_forward),
              label: Text(thai ? 'ดูผลประเมิน' : 'View Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  String _defaultSummary(bool thai) {
    final duration = switch (durationHours) {
      1.0 => thai ? 'งานสั้น' : 'short work',
      2.0 => thai ? 'ประมาณ 2 ชม.' : 'about 2 hrs',
      4.0 => thai ? 'ครึ่งวัน' : 'half day',
      _ => thai ? 'ทั้งวัน' : 'full day',
    };
    final repetition = switch (frequency) {
      <= 0.2 => thai ? 'ทำไม่ถี่' : 'occasional',
      < 6.0 => thai ? 'ทำซ้ำเป็นระยะ' : 'repeated',
      _ => thai ? 'ทำซ้ำบ่อย' : 'very frequent',
    };
    if (jobType == JobType.lifting) {
      return thai
          ? '$duration, $repetition, น้ำหนักประมาณ ${loadWeight.round()} กก.'
          : '$duration, $repetition, about ${loadWeight.round()} kg';
    }
    return '$duration, $repetition';
  }
}

class _SimpleFactRow extends StatelessWidget {
  const _SimpleFactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: SooktaColors.darkGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: const TextStyle(color: Colors.black54),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedDetailsCard extends StatelessWidget {
  const _AdvancedDetailsCard({
    required this.thai,
    required this.expanded,
    required this.onExpansionChanged,
    required this.children,
  });

  final bool thai;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        leading: const Icon(Icons.tune, color: SooktaColors.darkGreen),
        title: Text(
          thai ? 'ปรับรายละเอียด ถ้าทราบ' : 'Adjust Details if Known',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          thai
              ? 'ส่วนนี้ไม่จำเป็นสำหรับผู้ใช้ทั่วไป'
              : 'Most users can leave this unchanged.',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: children,
      ),
    );
  }
}

String _jobLabel(JobType jobType, bool thai) {
  return switch (jobType) {
    JobType.reba => thai ? 'ดูท่าทางจากรูป' : 'Posture from photo',
    JobType.lifting => thai ? 'งานยก/แบก' : 'Lifting',
    JobType.pushPull => thai ? 'งานดัน/ดึง' : 'Push or pull',
  };
}

class _RebaCard extends StatelessWidget {
  const _RebaCard({
    required this.thai,
    required this.input,
    required this.poseBusy,
    required this.poseStatus,
    required this.onChanged,
    required this.onAutoFill,
  });

  final bool thai;
  final RebaInputData input;
  final bool poseBusy;
  final String? poseStatus;
  final ValueChanged<RebaInputData> onChanged;
  final VoidCallback? onAutoFill;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: thai ? 'คะแนนท่าทาง REBA' : 'REBA Posture Scores',
      children: [
        OutlinedButton.icon(
          onPressed: onAutoFill,
          icon: poseBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(thai ? 'ประเมิน REBA จากภาพ' : 'Assess REBA from photos'),
        ),
        if (poseStatus != null) ...[
          const SizedBox(height: 8),
          Text(
            poseStatus!,
            style: const TextStyle(color: SooktaColors.darkGreen),
          ),
        ],
        _ScoreSlider(
          label: thai ? 'ลำตัว' : 'Trunk',
          value: input.trunkScore,
          min: 1,
          max: 4,
          onChanged: (value) => onChanged(input.copyWith(trunkScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'คอ' : 'Neck',
          value: input.neckScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(neckScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ขา' : 'Legs',
          value: input.legScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(legScore: value)),
        ),
        _CheckTile(
          label: thai ? 'ลำตัวบิด' : 'Trunk twist',
          value: input.trunkTwist,
          onChanged: (value) => onChanged(input.copyWith(trunkTwist: value)),
        ),
        _CheckTile(
          label: thai ? 'ลำตัวเอียงข้าง' : 'Trunk side flexion',
          value: input.trunkSideFlex,
          onChanged: (value) => onChanged(input.copyWith(trunkSideFlex: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ต้นแขน' : 'Upper Arm',
          value: input.upperArmScore,
          min: 1,
          max: 4,
          onChanged: (value) => onChanged(input.copyWith(upperArmScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ปลายแขน' : 'Lower Arm',
          value: input.lowerArmScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(lowerArmScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ข้อมือ' : 'Wrist',
          value: input.wristScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(wristScore: value)),
        ),
        _CheckTile(
          label: thai ? 'ข้อมือบิด' : 'Wrist twist',
          value: input.wristTwist,
          onChanged: (value) => onChanged(input.copyWith(wristTwist: value)),
        ),
        _ScoreSlider(
          label: thai ? 'น้ำหนักที่ถือ' : 'Load',
          value: input.loadScore,
          min: 0,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(loadScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'การจับยึด' : 'Coupling',
          value: input.couplingScore,
          min: 0,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(couplingScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'กิจกรรมซ้ำ/ค้างท่า' : 'Activity',
          value: input.activityScore,
          min: 0,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(activityScore: value)),
        ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _IsoCard extends StatelessWidget {
  const _IsoCard({
    required this.thai,
    required this.jobType,
    required this.horizontalController,
    required this.verticalController,
    required this.transportController,
    required this.initialForceController,
    required this.sustainForceController,
  });

  final bool thai;
  final JobType jobType;
  final TextEditingController horizontalController;
  final TextEditingController verticalController;
  final TextEditingController transportController;
  final TextEditingController initialForceController;
  final TextEditingController sustainForceController;

  @override
  Widget build(BuildContext context) {
    final lifting = jobType == JobType.lifting;
    return _SectionCard(
      title: lifting
          ? (thai ? 'ข้อมูล ISO 11228 งานยก' : 'ISO 11228 Lifting')
          : (thai ? 'ข้อมูลแรงดัน/ดึง' : 'Push/Pull Force'),
      children: [
        if (lifting) ...[
          _NumberField(
            controller: horizontalController,
            label: thai ? 'ระยะห่าง H (cm)' : 'Distance H (cm)',
          ),
          _NumberField(
            controller: verticalController,
            label: thai ? 'ความสูง V (cm)' : 'Height V (cm)',
          ),
          _NumberField(
            controller: transportController,
            label: thai ? 'ระยะทางขนย้าย (m)' : 'Transport distance (m)',
          ),
        ] else ...[
          _NumberField(
            controller: initialForceController,
            label: thai ? 'แรงเริ่มต้น (N)' : 'Initial force (N)',
          ),
          _NumberField(
            controller: sustainForceController,
            label: thai ? 'แรงต่อเนื่อง (N)' : 'Sustained force (N)',
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items.entries
            .map(
              (entry) => DropdownMenuItem<T>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        Slider(
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          value: value.toDouble(),
          label: '$value',
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}
